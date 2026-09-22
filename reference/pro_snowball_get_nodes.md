# A function to get the nodes for a snowball search

A function to get the nodes for a snowball search

## Usage

``` r
pro_snowball_get_nodes(
  identifier = NULL,
  doi = NULL,
  limit = NULL,
  snapshot = NULL,
  max_results = 100000L,
  workers = 1L,
  chunk_limit = NULL,
  select = NULL,
  endpoint = "https://api.openalex.org",
  duckdb_config = NULL,
  resume = FALSE,
  cleanup = TRUE,
  prepared = FALSE,
  output = tempfile(fileext = ".snowball"),
  verbose = FALSE
)
```

## Arguments

- identifier:

  Character vector of openalex identifiers.

- doi:

  Character vector of dois.

- limit:

  If `citedOnly` only works cited by the keypaper are retrieved,
  `citingOnly` retrieves only works citing the keypaper. Default: `NULL`
  where all will be retrieved. 'none' is equal to `NULL`

- snapshot:

  Path to a local OpenAlex snapshot (either a root directory containing
  `parquet/`, or the `parquet/` directory itself). When supplied, nodes
  are gathered offline from the snapshot instead of the OpenAlex API.
  Requires the indexes built by
  [`openalexSnapshot::build_corpus_index()`](https://rdrr.io/pkg/openalexSnapshot/man/build_corpus_index.html)
  and `build_citation_index()`. Default `NULL` (use the API).

- max_results:

  Snapshot mode only: refuse to expand a keypaper with more citing works
  than this. See
  [`openalexSnapshot::get_citing()`](https://rdrr.io/pkg/openalexSnapshot/man/get_citing.html).

- workers:

  Number of parallel workers. Default `1` (sequential).

- chunk_limit:

  API mode only: ids per filter URL. `NULL` (default) derives one from
  `workers`; see
  [`pro_snowball()`](https://openalexpro.github.io/openalexSnowball/reference/pro_snowball.md).

- select:

  Snapshot mode only: node columns to keep. See
  [`pro_snowball()`](https://openalexpro.github.io/openalexSnowball/reference/pro_snowball.md).

- endpoint:

  API mode only: base URL of the OpenAlex API. See
  [`pro_snowball()`](https://openalexpro.github.io/openalexSnowball/reference/pro_snowball.md).

- duckdb_config:

  DuckDB settings for the assembly connection. See
  [`snowball_duckdb_config()`](https://openalexpro.github.io/openalexSnowball/reference/snowball_duckdb_config.md).

- resume:

  Keep an existing `output` and continue from where a previous run
  stopped, instead of deleting it. Default `FALSE`.

- cleanup:

  Remove the intermediate `*_json` / `*_parquet` directories once the
  nodes are assembled. Default `TRUE`.
  [`pro_snowball()`](https://openalexpro.github.io/openalexSnowball/reference/pro_snowball.md)
  passes `FALSE` and cleans up after edge extraction instead, so that a
  failure there is still resumable.

- prepared:

  Internal. `TRUE` means the caller has already created or cleaned
  `output` and this function must not delete it.

- output:

  parquet dataset; default: temporary directory.

- verbose:

  Logical indicating whether to show a verbose information. Defaults to
  `FALSE`

## Value

Path to the nodes parquet dataset
