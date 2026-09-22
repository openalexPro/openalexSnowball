# openalexSnowball

Citation **snowball searches** on the OpenAlex graph, processed on disk.

Starting from a set of seed papers (*keypapers*), a snowball search
follows citation links outward: the works that cite the seeds, and the
works the seeds cite. openalexSnowball retrieves that neighbourhood and
writes it as partitioned Apache Parquet, so the result is bounded by
disk rather than by memory and can be queried without loading it.

Two backends produce the same on-disk construct:

- **API** — live queries against OpenAlex, via
  [openalexPro](https://github.com/openalexPro/openalexPro).
- **Snapshot** — entirely offline against a local OpenAlex snapshot, via
  [openalexSnapshot](https://github.com/openalexPro/openalexSnapshot).
  Reproducible, because the corpus is a fixed vintage.

## Installation

``` r

# stable, from r-universe
install.packages(
  "openalexSnowball",
  repos = c("https://openalexpro.r-universe.dev", "https://cloud.r-project.org")
)

# development
remotes::install_github("openalexPro/openalexSnowball", ref = "dev")
```

## Usage

``` r

library(openalexSnowball)

out <- pro_snowball(
  identifier = c("W2741809807", "W2755950973"),
  output     = "./snowball"
)

sb <- read_snowball(out, return_data = TRUE, shorten_ids = TRUE)
sb$nodes
sb$edges
```

Keypapers may be given as `identifier` (OpenAlex ids) or `doi`.

### Nodes

`id` is a key: every work appears exactly once. Because a work can hold
more than one role in the same search — a keypaper that cites another
keypaper is both — the roles are three independent flags:

| column        | meaning                           |
|---------------|-----------------------------------|
| `is_keypaper` | one of the supplied keypapers     |
| `is_citing`   | cites at least one keypaper       |
| `is_cited`    | is cited by at least one keypaper |

Any combination can be `TRUE`. `relation` is also present and is the
hive partition key, but it records only the highest-precedence role
(`keypaper` \> `citing` \> `cited`), so it is lossy — filter on the
booleans.

### Edges

Three **mutually exclusive** types: `core` (at least one endpoint is a
keypaper, both endpoints in the dataset), `extended` (both endpoints in
the dataset, neither a keypaper), and `outside` (an endpoint is
external). Selecting several is a union of disjoint sets.

### Offline

``` r

pro_snowball(
  identifier = keypapers,
  snapshot   = "/path/to/openalex/parquet",
  select     = c("id", "doi", "title", "publication_year"),
  output     = "./snowball_offline"
)
```

Needs the indexes built by
[`openalexSnapshot::build_corpus_index()`](https://rdrr.io/pkg/openalexSnapshot/man/build_corpus_index.html)
and `build_citation_index()`, plus `build_doi_index()` for DOI
keypapers.

### Larger searches

- **Pass all keypapers to one call.** Cost is dominated by scattered
  reads over the corpus and the file set saturates, so ten times the
  keypapers costs roughly twice the time — a loop pays that cost every
  iteration.
- **Name the columns you need** with `select=`. Record retrieval is ~92%
  of an offline run.
- **Declare concurrency** if you run several searches at once, so they
  do not each assume they own the machine:
  `options(openalexSnowball.duckdb_config = list(concurrency = 4))`.
- **`resume = TRUE`** continues an interrupted run. The default `output`
  is a temporary directory that does not survive the session, so pass a
  persistent `output =` if you want that.

See
[`vignette("Snowball")`](https://openalexpro.github.io/openalexSnowball/articles/Snowball.md)
and
[`?pro_snowball`](https://openalexpro.github.io/openalexSnowball/reference/pro_snowball.md)
for the full argument set.

## Related packages

| package | role |
|----|----|
| [openalexPro](https://github.com/openalexPro/openalexPro) | OpenAlex API access and JSON→Parquet conversion |
| [openalexSnapshot](https://github.com/openalexPro/openalexSnapshot) | local snapshot indexing and offline lookup |
| [openalexConvert](https://github.com/openalexPro/openalexConvert) | export to CSL-JSON, BibTeX, Zotero |

## LLM usage disclosure

Code and documentation in this project have been generated with the
assistance of LLM tools. All content is based on conceptualisation by
the authors and has been reviewed and edited by humans afterwards.
