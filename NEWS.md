# openalexSnowball 0.13.0

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
