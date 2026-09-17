# openalexSnowball 0.15.0

## Bug fix: `pro_snowball()` ran out of memory assembling large node sets

A 2137-keypaper run failed after 5.7 hours with
`Out of Memory Error: could not allocate block of size 256.0 KiB
(28.7 GiB/28.7 GiB used)`.

This was a regression. Through 0.12.0 `.assemble_nodes()` was a pure
streaming scan-and-write. 0.12.1 added `QUALIFY row_number() OVER (PARTITION
BY id ...)` to make `id` a key, and 0.13.0 added three `bool_or(...) OVER
(PARTITION BY id)` for the role flags -- four *blocking* window operators.
DuckDB materialises a window's entire input before emitting a row, and
`SELECT * REPLACE` defeats projection pruning, so all ~51 wide nested works
columns (`abstract`, `abstract_inverted_index` as `MAP(VARCHAR, BIGINT[])`,
`authorships`, `locations`, `topics`) were carried through the
hash-partition. `select=` is snapshot-only, so the API path projected
nothing.

Assembly is now two passes, and the wide columns never enter a blocking
operator:

* **Pass 1** aggregates `(id, relation)` plus the synthetic `filename` /
  `file_row_number` into one row per work -- the three role flags, and the
  physical address of the row that wins the precedence order. A single
  `min(struct_pack(precedence, filename, file_row_number))` replaces all four
  windows, because STRUCT comparison is lexicographic by field position.
  Projection pushdown means the nested columns are never decoded.
* **Pass 2** scans the wide data once per relation and inner-joins that
  narrow table on the row address. Each work contributes exactly one address,
  so the join is 1:1 and the wide columns only travel the streaming probe
  side.

Output semantics are unchanged: one row per `id`, relation precedence
`keypaper` > `citing` > `cited`, and the `is_*` flags computed over every
source row.

A second hazard that would have survived fixing the windows is also gone:
`PARTITION_BY` buffers up to `partitioned_write_flush_threshold` (524,288)
rows *per thread* with no byte cap, which for rows this wide is gigabytes on
its own. Each relation is now written to `nodes/relation=<rel>/` explicitly --
identical layout, plain streaming writer.

### Two behaviour changes that follow

**The de-duplication tie-break is now deterministic.** The old `ORDER BY`
ranked only the relation, so which of several copies of a work survived was
whatever order the sort happened to produce. It is now
`(precedence, filename, file_row_number)`, a total order. Where a work was
fetched twice with differing metadata, a different -- but stable -- copy may
now win.

**`nodes` no longer carries a `query` column, and the schema no longer
depends on the keypaper count.** Above 50 keypapers `pro_query()` chunks the
id filter, so the intermediate directories acquire `query=chunk_N/` levels
and DuckDB materialised `query` as a column: 57 columns at two seeds, 58 at
2137. Assembly now reads with `hive_partitioning = false`. The column was
arbitrary provenance anyway -- after de-duplication it named whichever chunk
the surviving row happened to come from.

## DuckDB connections are configured rather than left at their defaults

New `snowball_duckdb_config()` and a `duckdb_config` argument on
`pro_snowball()`, `pro_snowball_get_nodes()` and
`pro_snowball_extract_edges()`; also settable session-wide with
`options(openalexSnowball.duckdb_config = )`.

Both connections were bare `dbConnect(duckdb::duckdb())`, so DuckDB's
defaults applied -- including a `memory_limit` of ~80% of system RAM **per
instance** and a `temp_directory` of `.tmp` *relative to the working
directory*. Neither suits a package people run several of at once: three
concurrent callers on a 36 GB machine promised 86 GB, and they all spilled
into one directory, which is the colliding-spill-file corruption
openalexSnapshot documents.

Defaults now: `preserve_insertion_order = FALSE`, a private per-call,
per-stage spill directory under `tempdir()`, and a memory budget of half of
physical RAM divided by a declared `concurrency`:

```r
options(openalexSnowball.duckdb_config = list(concurrency = 4))
```

Settings resolve **per field** -- argument over option over default -- so
setting one does not silently discard the others. Unknown field names are an
error. `partitioned_write_max_open_files` is deliberately left at DuckDB's
100: `nodes/` and `edges/` have three partitions each.

## `resume = TRUE`: a failed run no longer costs the fetching

The run that motivated this release lost about six hours of completed API
fetching. The data was not destroyed by the crash -- the cleanup `unlink()`s
run *after* assembly, so every intermediate directory was still on disk -- but
`output` defaults to `tempfile()`, which lives under `tempdir()` and goes away
when the R session ends.

So the fix is mostly about not throwing the checkpoint away:

* `pro_snowball(resume = TRUE)` keeps an existing `output` instead of deleting
  and recreating it, and skips stages that a `.osb_done/` marker records as
  complete. Within the fetch stage only the query chunks that did not finish
  are re-requested, via `openalexPro::pro_request(resume = )`.
* Cleanup of the `*_json` / `*_parquet` directories moved from the end of
  `pro_snowball_get_nodes()` to after edge extraction, so a failure in
  *edges* is resumable too. `keep_intermediates = TRUE` suppresses it
  entirely. Peak disk is correspondingly higher, since the intermediates now
  coexist with `nodes/` and `edges/`.
* A `_snowball_run.parquet` manifest records the parameters that define which
  snowball this is. Resuming with a different keypaper set, `snapshot`,
  `endpoint`, `max_results` or `select` is a hard error naming the field --
  it would otherwise splice two snowballs into one output, silently.
  `workers`, `verbose` and `duckdb_config` may differ freely, which is the
  point: "resume with fewer workers and a smaller memory limit" is the usual
  reason to resume at all.
* Failures are re-thrown naming the stage, the output path, the completed
  stages and the exact resume call -- and warning, when the path is under
  `tempdir()`, that it will not survive the session. That warning is the one
  thing that would have saved the six hours.

`resume = FALSE` remains the default and behaves exactly as before.

## Edge extraction no longer goes through the Arrow bridge

`extract_edges.sql` scans `nodes` six times -- `edges_basic`, `keypaper`, and
four joins. Registering the node set with `duckdb_register_arrow()` meant
DuckDB could not push projections into any of those scans, so a ~51-column
node set with nested structs was pulled across the bridge repeatedly. It is
now a native `read_parquet` view.

The four joins test membership only, so they now join `(SELECT id FROM ...)`
rather than the whole node row, keeping the hash-join build sides narrow. And
the outer `SELECT DISTINCT *` is gone: `edges` is built on `edges_basic`,
which already applies `DISTINCT`, so that was a second hash aggregate over
the entire exploded edge set for nothing.

## The keypaper fetch is parallel

`pro_query()` chunks the `openalex` id filter exactly as it chunks
`cites`/`cited_by`, so a large keypaper set becomes many URLs -- about 43 for
2137 seeds. They were fetched *and* converted strictly sequentially even at
`workers = 12`, straight on the critical path. Both now honour `workers`, and
the chunk size is derived from it as it already was for the expansions.

## A concurrency test

Nothing in the suite ever ran two `pro_snowball()` calls at once, which is
how the shared-spill-directory bug survived in two packages: DuckDB's
`temp_directory` defaults to `.tmp` *relative to the working directory*, so
concurrent callers write colliding `duckdb_temp_storage_*.tmp` files into one
place. openalexSnapshot documents that hazard for its index builders; neither
the snowball path nor openalexSnapshot's own parallel lookup guarded it.

`test-005` now starts two overlapping snapshot snowballs under
`future::multisession(workers = 2)` -- both futures created before either is
resolved -- and requires each to produce a complete, correct result matching
a sequential reference. `future` is added to Suggests. Runs offline in a few
seconds.

It deliberately does *not* assert that no `.tmp` appeared: the fixture is 12
works and never spills, so that check was verified to pass even with DuckDB's
default restored, i.e. it asserted nothing. The private-spill invariant is
asserted directly in `test-007` instead.

## `ORDER BY id` when reading resolved keypapers

The keypaper id vector is joined into `pro_query()`'s filter URLs, so its
order determines the requests. It came straight out of an unordered
`SELECT id`, which DuckDB makes no promise about and which
`preserve_insertion_order = FALSE` would make genuinely nondeterministic.
Sorting makes the URLs a pure function of the *set* of keypapers.

This changed the recorded request URLs, so `tests/fixtures/vcr/pro_snowball.yml`
gained the sorted-order episodes. The two unsorted-order episodes are now
unreachable; the responses are identical either way (verified: same 46 x 57
nodes and the same edge counts).

# openalexSnowball 0.14.0

## `endpoint` argument: target a self-hosted OpenAlex

`pro_snowball()` and `pro_snowball_get_nodes()` gain `endpoint`, defaulting to
`"https://api.openalex.org"` -- so behaviour is unchanged unless you set it.

`openalexPro::pro_query()` has always accepted an `endpoint`, but neither
snowball function exposed or forwarded it, so all four query call sites were
pinned to the public API. Pointing a snowball at a self-hosted OpenAlex
instance (OurResearch publish the production stack as
`ourresearch/openalex-elastic-api`) was therefore impossible without editing
the package. It now takes one argument.

This matters beyond convenience: a self-hosted instance carries no rate limit,
which is the constraint that caps useful `workers` values on the API path. It
also makes the API path testable against a mock server rather than only
against recorded cassettes.

Threaded through all four call sites -- keypaper lookup by id, by DOI, and the
`cites` / `cited_by` expansions -- and the "no records for the requested
keypaper(s)" error now names the endpoint actually queried instead of
hard-coding the public host.

Trailing slashes are stripped: `pro_query()` appends `/works`, and `//works`
is not merely cosmetic, since some reverse proxies route it differently.
Ignored in snapshot mode, where no request is made.

# openalexSnowball 0.13.0

## Documentation: pool keypapers in snapshot mode

`?pro_snowball` gains a section on where snapshot-mode time actually goes, with
the measurement behind it. Over 100 random keypapers against the full corpus,
record retrieval is 92% of the run (95.5 s) against 8.5 s for both index
lookups -- and the reason is scattered reads, not the lookup: those keypapers
produced 3,121 nodes spread over 1,222 of the corpus's 2,127 parquet files, an
average of 2.6 wanted rows per file opened.

Because that file set saturates at 2,127 however many keypapers are supplied,
cost is strongly concave in the number of keypapers. Users running many
searches should pass all keypapers to a single call rather than looping, which
is now documented, with the caveat that a pooled run defines `oa_input`,
`relation`, the `is_*` flags and `edge_type` relative to the pooled keypaper
set.

## `nodes` records every role a work holds

0.12.1 made `id` a key in `nodes/` by collapsing duplicated works to one row.
That was correct, but it made `relation` lossy: a work that both cites a
keypaper and is cited by one kept `relation = "citing"` only, and the fact
that it was also cited disappeared.

`nodes/` now carries three boolean columns alongside `relation`:

* `is_keypaper` -- the work is one of the supplied keypapers.
* `is_citing` -- the work cites at least one keypaper.
* `is_cited` -- the work is cited by at least one keypaper.

Any combination can be `TRUE`, so no role is lost. They are computed with
`bool_or(...) OVER (PARTITION BY id)` *before* the deduplicating `QUALIFY`, so
they see every row a work had, not just the surviving one. In a clustered
40-keypaper snowball over the snapshot, 75 of 3837 works hold more than one
role -- 60 `citing` + `cited`, 15 `keypaper` + something else.

`relation` is kept and unchanged: it is the hive partition key of `nodes/`, so
removing it would break the on-disk layout and every existing reader. It still
holds the highest-precedence role only (`keypaper` > `citing` > `cited`).
Filter on the booleans; use `relation` for partition pruning.

`inst/extract_edges.sql` now selects keypapers with `WHERE is_keypaper` rather
than `WHERE relation = 'keypaper'`. The two agree today -- `keypaper` wins the
precedence order -- but only the boolean stays correct if that order is ever
changed.

Additive, so nothing breaks. Existing code reading `relation` behaves exactly
as in 0.12.1; snapshots of node schemas gain three columns.

Documented in a "Node roles" section of both `?pro_snowball` and
`?read_snowball`, the latter with worked filtering examples, since
`read_snowball()` is what hands you the `nodes` table.

## Test infrastructure

`tests/testthat/helper_snapshot.R` now sources openalexSnapshot's shared corpus
generator with `local = TRUE`. Without it the function landed in globalenv,
which the test environment of `devtools::test()` and `testthat::test_local()`
does not see, so the whole offline-snowball file errored with "could not find
function `make_tiny_corpus`". `testthat::test_dir()` did see it, which is why
the suite looked green. Pre-existing; unrelated to the change above.

# openalexSnowball 0.12.1

## Bug fix: duplicated nodes

`id` is now a key in the `nodes` table. It was not, in two independent ways:

* **Across relations, on both paths.** A keypaper that also cites another
  keypaper appeared twice -- once as `relation = "keypaper"` with
  `oa_input = TRUE`, once as `relation = "citing"` with `oa_input = FALSE`.
  The same work carried contradictory metadata, and any join on `id` fanned
  out. Measured at 75 duplicated ids in a clustered 40-keypaper snowball.

* **Within a relation, on the API path only.** `pro_query()` chunks `cites`
  and `cited_by` at 50 ids into separate URLs, fetched and converted
  independently, so a work citing keypapers in two different chunks was
  written twice. Measured at 1.088x on `cited` and 1.010x on `citing` for 60
  keypapers. Unreachable below 51 keypapers, which is why the two-keypaper
  test fixture never exposed it. The snapshot path was never affected --
  `get_citing()` and `get_cited()` return unique ids.

`.assemble_nodes()` now keeps one row per work, keypaper winning over citing
winning over cited. That mirrors `openalexR::oa_snowball()`, which does
`nodes[!duplicated(nodes$id), ]` over `list(paper, citing, cited)` -- so this
converges on the reference rather than inventing a rule. A plain `DISTINCT`
would not have worked: the duplicate rows differ in `relation` and `oa_input`.

Two consequences worth knowing:

* A work that both cites a keypaper and is cited by one now keeps only
  `relation = "citing"`. That signal is lost, deliberately; `openalexR` makes
  the same trade.
* A `relation` partition can now be **absent**. If everything the keypapers
  cite is itself a keypaper or a citer, those rows are promoted and
  `nodes/relation=cited/` is never written.

Edges are unchanged: `inst/extract_edges.sql` already applied its own
`DISTINCT`, so duplicate node rows never reached them.


* `pro_snowball()` gains `select=`, `workers=` and `chunk_limit=`; see below.
* Requires openalexSnapshot (>= 0.2.0): `select=` needs `lookup_by_id(columns=)`,
  and the offline path expects the partitioned `works_id_idx/` directory that
  0.2.0 introduced. An 0.1.x snapshot index will not be found.

## New: offline snowball searches

* **`pro_snowball()` gains a `snapshot` argument.** When given a path to a
  local OpenAlex snapshot the whole snowball is built offline; when `NULL`
  (the default) behaviour is byte-identical to before. There is no separate
  function -- one entry point, two backends.

  ```r
  # unchanged: live API
  pro_snowball(identifier = "W3045921891")

  # offline, reproducible, no network
  pro_snowball(identifier = "W3045921891", snapshot = "~/openalex/parquet")
  ```

  The path may be either a root directory containing `parquet/` or the
  `parquet/` directory itself. Keypapers may be OpenAlex IDs or DOIs, with or
  without a resolver prefix, mixed freely.

  Requires `openalexSnapshot::build_corpus_index()` and
  `build_citation_index()`, plus `build_doi_index()` for DOI keypapers.

* **The output construct is unchanged** -- `nodes/relation=` and
  `edges/edge_type=` partitioned identically, and [read_snowball()] reads it
  without modification.

  **The node columns are not.** Snapshot records are not API records, so
  snapshot nodes carry whatever the works corpus holds plus `oa_input` and
  `relation`. In particular there is no `page` column, which is an API
  pagination artefact with no snapshot analogue; it is deliberately absent
  rather than faked. Offline results are also frozen at the snapshot's vintage
  rather than live.

* Keypapers that resolve but are **absent from the snapshot** now warn and are
  dropped; if none are present, that is an error. Previously such a snowball
  would have been built with no seed, silently changing the core/extended edge
  classification.

* `max_results` (snapshot mode) refuses to expand a keypaper with more citing
  works than the limit. A heavily cited work can have hundreds of thousands of
  citers, and extracting records for all of them would read most of the corpus.

* **Provenance.** Every snowball now writes `snowball_meta.parquet` recording
  how it was produced: `api` or `snapshot`, the snapshot path and the vintage
  of the citation index the results are frozen at, the resolved keypapers, and
  package versions. Without it an offline snowball is indistinguishable from an
  online one on disk, which matters if results are cited in published work.

  `read_snowball(meta = TRUE)` returns it as a third list element. It is
  **opt-in**: the sidecar carries a wall-clock `created_at`, so returning it by
  default would make any snapshot test of the returned object unstable, and
  would change the return shape for existing callers. The default remains
  `list(nodes, edges)`.

## Internal

* `pro_snowball_get_nodes()` split into `.nodes_from_api()`,
  `.nodes_from_snapshot()` and a shared `.assemble_nodes()`. Only the fetch
  differs between the two paths; the union COPY,
  `pro_snowball_extract_edges()` and `read_snowball()` were already generic.

* `inst/extract_edges.sql` is reused **unmodified**. Its `UNLIST()` needs a
  list type, and the legacy snapshot corpus stores `referenced_works` as a JSON
  string, so `.assemble_nodes()` normalises the column at node-write time
  instead. That keeps the SQL a static readable artifact and makes the offline
  node schema more API-compatible, not less.

* `openalexSnapshot (>= 0.1.0)` added to Imports.

# openalexSnowball 0.10.1

## Breaking Changes

* Minimum `openalexPro` version bumped from `>= 0.4.0` to `>= 0.10.2`.

## Bug Fixes

* `pro_snowball_get_nodes()`: fixed `pro_query()` call to use `id =` instead
  of the removed `openalex =` argument (renamed in openalexPro 0.4.1).
* `pro_snowball_extract_edges()`: replaced removed `openalexPro::load_sql_file()`
  with `readLines()` + `paste()` fed to `DBI::dbExecute()` directly
  (function removed in openalexPro 0.4.2; DuckDB handles multi-statement SQL
  natively).
* Test helper: replaced removed `oap_apikey()` / `oap_mail()` with
  `Sys.getenv/setenv("openalexPro.apikey")`.
* CI now depends on openalexPro ≥ 0.10.2 (with type-normalisation fixes from
  PRs #59 and #60) installed from r-universe dev branch.

# openalexSnowball 0.1.0

* Split snowball functions from openalexPro (<0.4)
