# Memory behaviour of .assemble_nodes().
#
# A 2137-keypaper run OOMed at 28.7 GiB in this function after 5.7 hours. The
# cause was four blocking window operators -- three bool_or(...) OVER
# (PARTITION BY id) added in 0.13.0 and a QUALIFY row_number() OVER added in
# 0.12.1 -- each carrying all ~51 wide nested works columns, because
# `SELECT * REPLACE` defeats projection pruning.
#
# These tests reproduce that in seconds rather than hours, and pin the
# invariant that fixes it: no window operator in the assembly plan.

# The pre-0.15.0 statement, kept verbatim as an oracle. Do not "tidy" it.
old_assemble_sql <- function(sources_sql, nodes_dir) {
  sprintf(
    "COPY (
        SELECT
          * REPLACE (CAST(oa_input AS BOOLEAN) AS oa_input),
          bool_or(relation = 'keypaper') OVER (PARTITION BY id) AS is_keypaper,
          bool_or(relation = 'citing')   OVER (PARTITION BY id) AS is_citing,
          bool_or(relation = 'cited')    OVER (PARTITION BY id) AS is_cited
        FROM read_parquet([%s], union_by_name = true)
        QUALIFY row_number() OVER (
          PARTITION BY id
          ORDER BY CASE relation
                     WHEN 'keypaper' THEN 1
                     WHEN 'citing'   THEN 2
                     ELSE                 3
                   END
        ) = 1
      ) TO '%s'
        (FORMAT PARQUET, COMPRESSION SNAPPY, APPEND, PARTITION_BY 'relation')",
    sources_sql, nodes_dir
  )
}

# A payload that is large in memory but tiny on disk: repeat() compresses to
# almost nothing in parquet but expands once an operator materialises it.
#
# The sizing separates the two pressures deliberately:
#
#   n_rows drives the OLD statement, whose window must hold every wide row at
#   once -- 1M x ~1.2 KB, comfortably over a 512 MB limit.
#   n_ids drives the NEW statement, whose only blocking step is a GROUP BY
#   over (id, relation, filename, file_row_number) -- 50k groups of ~250 B,
#   about 12 MB.
#
# Keeping n_ids well below n_rows is what makes the comparison about the
# operator rather than about cardinality; it also means 20 copies per id, so
# the dedup path is exercised hard. Raise n_ids towards n_rows and the new
# path's aggregate state grows until it too needs to spill.
make_wide_fixture <- function(dir, n_rows = 1000000L, n_ids = 50000L) {
  d <- file.path(dir, "citing_parquet", "query=chunk_0")
  dir.create(d, recursive = TRUE, showWarnings = FALSE)
  con <- DBI::dbConnect(duckdb::duckdb())
  on.exit(DBI::dbDisconnect(con, shutdown = TRUE), add = TRUE)
  DBI::dbExecute(con, sprintf(
    "COPY (
       SELECT 'https://openalex.org/W' || (i %% %d)          AS id,
              'citing'                                        AS relation,
              'FALSE'                                         AS oa_input,
              'chunk_0'                                       AS page,
              repeat('lorem ipsum ' || (i %% 977), 100)        AS abstract,
              ['https://openalex.org/W' || j FOR j IN range(5)] AS referenced_works
       FROM range(%d) t(i)
     ) TO '%s' (FORMAT PARQUET, COMPRESSION SNAPPY)",
    n_ids, n_rows, file.path(d, "data_0.parquet")
  ))
  dir
}

sources_of <- function(output) {
  paste(sprintf("'%s'",
    file.path(output, "citing_parquet", "**", "*.parquet")), collapse = ", ")
}

test_that("the old windowed statement OOMs where the new one streams", {
  skip_on_cran()
  out <- withr::local_tempdir()
  make_wide_fixture(out)

  # max_temp_directory_size = 0 is the essential part: DuckDB's default is 90%
  # of free disk, so without it the old statement merely spills and gets slow
  # instead of failing, and the test would take minutes and prove nothing.
  con <- DBI::dbConnect(duckdb::duckdb())
  on.exit(DBI::dbDisconnect(con, shutdown = TRUE), add = TRUE)
  # Note: `duckdb(config = list(memory_limit = ...))` is silently ignored by
  # the R driver -- the limit stays at 80% of RAM. It must be SET.
  DBI::dbExecute(con, "SET memory_limit = '512MB'")
  DBI::dbExecute(con, "SET max_temp_directory_size = '0KiB'")
  DBI::dbExecute(con, "SET preserve_insertion_order = false")

  expect_error(
    DBI::dbExecute(con, old_assemble_sql(
      sources_of(out), file.path(out, "nodes_old")
    )),
    regexp = "Out of Memory"
  )
  # The production failure happened *with* spilling available (28.7 GiB limit,
  # temp_directory = .tmp, 90% of disk), so the real statement held memory it
  # could not offload. Disallowing spill here reproduces the same operator
  # failing in seconds instead of hours; it is not a claim that spill was the
  # missing piece in production.

  # Same connection, same limits, no spilling allowed.
  expect_no_error(.assemble_nodes(out, con = con))
  n <- arrow::open_dataset(file.path(out, "nodes")) |> dplyr::collect()
  expect_equal(nrow(n), 50000L)
  expect_equal(dplyr::n_distinct(n$id), 50000L)
})

test_that("the assembly plan contains no window operator", {
  skip_on_cran()
  # This is the invariant the whole change is about: a window operator here
  # materialises every wide nested column before emitting a row.
  out <- withr::local_tempdir()
  make_wide_fixture(out, n_rows = 2000L, n_ids = 1500L)
  con <- DBI::dbConnect(duckdb::duckdb())
  on.exit(DBI::dbDisconnect(con, shutdown = TRUE), add = TRUE)

  # .assemble_nodes() drops its TEMP table on exit, so rebuild the narrow
  # winners table here exactly as pass 1 does and EXPLAIN pass 2 against it.
  read_all <- sprintf(
    "read_parquet([%s], union_by_name = true, hive_partitioning = false,
                  filename = true, file_row_number = true)",
    sources_of(out)
  )
  DBI::dbExecute(con, sprintf(
    "CREATE OR REPLACE TEMP TABLE snowball_node_winners AS
     SELECT id, is_keypaper, is_citing, is_cited,
            win.f AS win_file, win.r AS win_row
     FROM (
       SELECT id,
              bool_or(relation = 'keypaper') AS is_keypaper,
              bool_or(relation = 'citing')   AS is_citing,
              bool_or(relation = 'cited')    AS is_cited,
              min(struct_pack(
                p := CASE relation WHEN 'keypaper' THEN 1
                                   WHEN 'citing'   THEN 2 ELSE 3 END,
                f := filename, r := file_row_number)) AS win
       FROM %s GROUP BY id
     )", read_all
  ))

  plan <- paste(
    DBI::dbGetQuery(con, sprintf(
      "EXPLAIN SELECT n.* EXCLUDE (relation, filename, file_row_number),
                      w.is_keypaper, w.is_citing, w.is_cited
               FROM %s n
               JOIN (SELECT win_file, win_row, is_keypaper, is_citing, is_cited
                     FROM snowball_node_winners WHERE is_citing) w
                 ON n.filename = w.win_file AND n.file_row_number = w.win_row
               WHERE n.relation = 'citing'", read_all
    ))[[2L]],
    collapse = "\n"
  )
  expect_false(grepl("WINDOW", plan, ignore.case = TRUE))
})

test_that("duplicates within one relation collapse to one row", {
  skip_on_cran()
  # pro_query() chunks cites/cited_by at chunk_limit ids into separate URLs,
  # so a work citing keypapers in two chunks is written into two
  # query=chunk_N directories. Neither existing fixture can expose this:
  # test-004 uses two keypapers (one URL, no chunking) and test-005 goes
  # through get_citing(), which returns unique ids.
  out <- withr::local_tempdir()
  make_wide_fixture(out, n_rows = 500L, n_ids = 500L)
  src <- file.path(out, "citing_parquet", "query=chunk_0", "data_0.parquet")
  dup <- file.path(out, "citing_parquet", "query=chunk_1")
  dir.create(dup, recursive = TRUE, showWarnings = FALSE)
  file.copy(src, file.path(dup, "data_0.parquet"))

  con <- DBI::dbConnect(duckdb::duckdb())
  on.exit(DBI::dbDisconnect(con, shutdown = TRUE), add = TRUE)
  .assemble_nodes(out, con = con)

  n <- arrow::open_dataset(file.path(out, "nodes")) |> dplyr::collect()
  expect_equal(nrow(n), 500L)
  expect_equal(dplyr::n_distinct(n$id), 500L)
  expect_true(all(n$is_citing))
  expect_false(any(n$is_keypaper))
})

test_that("assembly is idempotent and does not append into an existing nodes/", {
  skip_on_cran()
  # The COPY used APPEND with PARTITION_BY, so running assembly twice against
  # a surviving nodes/ doubled every row -- re-creating exactly the duplicate
  # ids 0.12.1 removed. Assembly now builds into .nodes.building and renames.
  out <- withr::local_tempdir()
  make_wide_fixture(out, n_rows = 300L, n_ids = 300L)
  con <- DBI::dbConnect(duckdb::duckdb())
  on.exit(DBI::dbDisconnect(con, shutdown = TRUE), add = TRUE)

  .assemble_nodes(out, con = con)
  first <- arrow::open_dataset(file.path(out, "nodes")) |> dplyr::collect()
  .assemble_nodes(out, con = con)
  second <- arrow::open_dataset(file.path(out, "nodes")) |> dplyr::collect()

  expect_equal(nrow(second), nrow(first))
  expect_equal(nrow(second), 300L)
  expect_false(dir.exists(file.path(out, ".nodes.building")))
})

test_that("the written node schema does not depend on the keypaper count", {
  skip_on_cran()
  # Above 50 keypapers pro_query() chunks the id filter, so the *_parquet
  # directories acquire query=chunk_N/ levels. With hive detection on, DuckDB
  # materialised `query` as a column, making the node schema 57 columns at two
  # seeds and 58 at 2137.
  out1 <- withr::local_tempdir()
  make_wide_fixture(out1, n_rows = 100L, n_ids = 100L)

  out2 <- withr::local_tempdir()
  make_wide_fixture(out2, n_rows = 100L, n_ids = 100L)
  extra <- file.path(out2, "citing_parquet", "query=chunk_1")
  dir.create(extra, recursive = TRUE, showWarnings = FALSE)
  file.copy(
    file.path(out2, "citing_parquet", "query=chunk_0", "data_0.parquet"),
    file.path(extra, "data_0.parquet")
  )

  con <- DBI::dbConnect(duckdb::duckdb())
  on.exit(DBI::dbDisconnect(con, shutdown = TRUE), add = TRUE)
  .assemble_nodes(out1, con = con)
  .assemble_nodes(out2, con = con)

  n1 <- arrow::open_dataset(file.path(out1, "nodes")) |> dplyr::collect()
  n2 <- arrow::open_dataset(file.path(out2, "nodes")) |> dplyr::collect()
  expect_equal(sort(names(n1)), sort(names(n2)))
  expect_false("query" %in% names(n1))
  expect_false("query" %in% names(n2))
})
