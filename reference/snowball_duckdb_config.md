# Configuration for the DuckDB connections used by a snowball

[`pro_snowball()`](https://openalexpro.github.io/openalexSnowball/reference/pro_snowball.md)
opens DuckDB twice – once to assemble `nodes/`, once to extract
`edges/`. This builds the settings applied to both.

## Usage

``` r
snowball_duckdb_config(
  memory_limit = "auto",
  temp_directory = "auto",
  threads = "auto",
  preserve_insertion_order = FALSE,
  partitioned_write_max_open_files = NULL,
  max_temp_directory_size = NULL,
  concurrency = 1L
)
```

## Arguments

- memory_limit:

  DuckDB `memory_limit`. `"auto"` (the default) derives a budget from
  physical RAM and `concurrency`; `NULL` leaves DuckDB's own default of
  ~80% of RAM; anything else is passed through (e.g. `"8GB"`).

- temp_directory:

  Root for DuckDB's spill files. `"auto"` (the default) uses a private
  directory under [`tempdir()`](https://rdrr.io/r/base/tempfile.html). A
  path you supply is treated as a **root**: a
  `<pid>-<output hash>/<stage>` leaf is always appended, so setting one
  path for a whole worker pool stays safe. `NULL` leaves DuckDB's
  `.tmp`, which concurrent callers share – not recommended.

- threads:

  `SET threads`. `"auto"` divides the available cores by `concurrency`;
  `NULL` leaves DuckDB's default.

- preserve_insertion_order:

  Defaults to `FALSE`. Row order on disk is not part of this package's
  contract –
  [`read_snowball()`](https://openalexpro.github.io/openalexSnowball/reference/read_snowball.md)
  sorts nodes by `(desc(oa_input), id)` and edges by `(from, to)` – and
  preserving it makes the partitioned writes buffer.

- partitioned_write_max_open_files:

  `NULL` (default) leaves DuckDB's 100. Do not raise it here: `nodes/`
  and `edges/` have three partitions each, so 100 is already ~33x what
  is needed, and each open file carries a write buffer.
  (openalexSnapshot raises it to 512, but that write fans out over
  hundreds of partitions.)

- max_temp_directory_size:

  `NULL` (default) leaves DuckDB's 90% of free disk.

- concurrency:

  How many
  [`pro_snowball()`](https://openalexpro.github.io/openalexSnowball/reference/pro_snowball.md)
  calls you intend to run at the same time. Used to divide the memory
  and thread budgets. There is no portable way to detect sibling R
  processes, so this is declared rather than discovered – set it once
  for a worker pool:
  `options(openalexSnowball.duckdb_config = list(concurrency = 4))`.

## Value

A list of class `openalexSnowball_duckdb_config`.

## Details

Settings resolve **per field**, not per object: an explicit argument
field beats the same field of
`getOption("openalexSnowball.duckdb_config")`, which beats the package
default. So setting one field in the option does not silently discard
the safe defaults for the others, and passing
`duckdb_config = list(threads = 2)` at a call site does not discard a
session-wide memory budget.

Note that `memory_limit` is a fairness and blast-radius control rather
than a correctness one: lowering it does not make a query fit, it makes
a failure arrive sooner and stops one run from starving the others.

## Examples

``` r
snowball_duckdb_config(memory_limit = "8GB", concurrency = 4)
#> $memory_limit
#> [1] "8GB"
#> 
#> $temp_directory
#> [1] "auto"
#> 
#> $threads
#> [1] "auto"
#> 
#> $preserve_insertion_order
#> [1] FALSE
#> 
#> $partitioned_write_max_open_files
#> NULL
#> 
#> $max_temp_directory_size
#> NULL
#> 
#> $concurrency
#> [1] 4
#> 
#> attr(,"class")
#> [1] "openalexSnowball_duckdb_config"
```
