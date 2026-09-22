# Snowball Searches

## 1 Overview

`openalexSnowball` provides snowball search utilities that build on the
`openalexPro` pipeline. A snowball search starts from a set of key
papers and follows citation links to collect cited and citing works.
Results are stored on disk as parquet datasets and can be loaded back
into R using
[`read_snowball()`](https://openalexpro.github.io/openalexSnowball/reference/read_snowball.md).

## 2 Basic workflow

### 2.1 1. Define keypapers

Keypapers can be identified by OpenAlex IDs or DOIs.

### 2.2 2. Run a snowball search

``` r

snowball_dir <- "./snowball_ids"
pro_snowball(
  identifier = c("W2741809807", "W2755950973"),
  output = snowball_dir,
  verbose = TRUE
)
```

``` r

snowball_dir_dois <- "./snowball_dois"
pro_snowball(
  doi = c("10.1016/j.joi.2017.08.007", "10.7717/peerj.4375"),
  output = snowball_dir_dois,
  verbose = TRUE
)
```

## 3 Reading results

Use
[`read_snowball()`](https://openalexpro.github.io/openalexSnowball/reference/read_snowball.md)
to load nodes and edges. The output can be an Arrow Dataset (default) or
collected into memory as tibbles.

``` r

snowball <- read_snowball(
  snowball = snowball_dir,
  edge_type = c("core", "extended"),
  return_data = TRUE,
  shorten_ids = TRUE
)

snowball$nodes
snowball$edges
```

## 4 Node roles

`id` is a key in `nodes/`: every work appears exactly once. A work can
still hold more than one role — a keypaper that cites another keypaper
is both — so the roles are three independent flags:

- `is_keypaper` — one of the supplied keypapers
- `is_citing` — cites at least one keypaper
- `is_cited` — is cited by at least one keypaper

Any combination can be `TRUE`, and at least one always is.

``` r

subset(snowball$nodes, is_citing & is_cited)   # works in both directions
subset(snowball$nodes, !is_keypaper)           # the snowballed neighbourhood
```

`relation` is also present and is the hive partition key, but it records
only the highest-precedence role (`keypaper` \> `citing` \> `cited`). So
`relation == "cited"` does **not** find every cited work — `is_cited`
does. Filter on the booleans; use `relation` for partition pruning.

## 5 Offline: searching a local snapshot

With a local OpenAlex snapshot and its indexes, the whole search runs
without touching the API, and is reproducible against a fixed corpus
vintage.

``` r

pro_snowball(
  identifier = c("W2741809807", "W2755950973"),
  snapshot = "/path/to/openalex/parquet",
  select = c("id", "doi", "title", "publication_year"),
  output = "./snowball_offline"
)
```

This needs the indexes built by
[`openalexSnapshot::build_corpus_index()`](https://rdrr.io/pkg/openalexSnapshot/man/build_corpus_index.html)
and `build_citation_index()`, plus `build_doi_index()` if keypapers are
given as DOIs. `select=` is worth using: retrieving records is ~92% of
the run, and naming only the columns you need cuts the bytes read
substantially.

## 6 Large searches

Two things matter once you have more than a handful of keypapers.

**Pass them all to one call.** Cost is dominated by scattered reads
across the corpus, and the set of files touched saturates — ten times
the keypapers costs roughly twice the time, not ten times. A loop of
separate calls re-pays that cost every iteration.

**Declare how many searches you run at once.** Each DuckDB instance
otherwise assumes it owns ~80% of the machine:

``` r

options(openalexSnowball.duckdb_config = list(concurrency = 4))
```

`workers =` parallelises fetching and conversion. `resume = TRUE`
continues an interrupted run instead of restarting it — note the default
`output` lives in the session’s temporary directory, so pass a
persistent `output =` if you want to resume after a crash.

## 7 Output layout

A completed search contains:

    snowball/
    ├── nodes/                     # partitioned by relation=
    ├── edges/                     # partitioned by edge_type=
    ├── snowball_meta.parquet      # provenance: mode, vintage, keypapers
    └── _snowball_run.parquet      # parameters, used by resume

The `*_json/` and `*_parquet/` working directories exist only while the
search runs and are removed once `edges/` is written;
`keep_intermediates = TRUE` keeps them.

## 8 Tips

- Use `return_data = FALSE` to keep large datasets on disk.
- Use `edge_type = "core"` when you only need edges involving keypapers.
  The three edge types are mutually exclusive, so combining them is a
  union of disjoint sets rather than a widening.
