# DuckDB connection configuration.

test_that("defaults are the safe ones", {
  cfg <- .osb_resolve_duckdb_config(NULL)
  expect_false(cfg$preserve_insertion_order)
  expect_identical(cfg$memory_limit, "auto")
  expect_identical(cfg$temp_directory, "auto")
  expect_identical(cfg$concurrency, 1L)
  # Deliberately left at DuckDB's 100: nodes/ and edges/ have three
  # partitions each, so raising it only adds write buffers.
  expect_null(cfg$partitioned_write_max_open_files)
})

test_that("fields override, not objects", {
  # This is the whole point of merging per field. Object-level merging would
  # mean an option that sets one field silently discards the safe defaults
  # for the others, and a call-site config discards the session-wide budget.
  withr::local_options(
    openalexSnowball.duckdb_config = list(memory_limit = "6GB", concurrency = 3)
  )
  cfg <- .osb_resolve_duckdb_config(list(threads = 2L))

  expect_identical(cfg$memory_limit, "6GB")   # from the option
  expect_identical(cfg$threads, 2L)           # from the argument
  expect_identical(cfg$concurrency, 3)        # from the option
  expect_false(cfg$preserve_insertion_order)  # still the package default
})

test_that("an explicit NULL means 'leave DuckDB alone', not 'unspecified'", {
  # modifyList() would delete the element here, collapsing the two meanings.
  cfg <- .osb_resolve_duckdb_config(list(memory_limit = NULL))
  expect_true("memory_limit" %in% names(cfg))
  expect_null(cfg$memory_limit)
})

test_that("an argument beats the option for the same field", {
  withr::local_options(
    openalexSnowball.duckdb_config = list(memory_limit = "6GB")
  )
  expect_identical(
    .osb_resolve_duckdb_config(list(memory_limit = "2GB"))$memory_limit,
    "2GB"
  )
})

test_that("unknown fields error rather than being ignored", {
  # A typo'd memory_limit that silently did nothing would reproduce the very
  # failure this machinery exists to prevent.
  expect_error(.osb_resolve_duckdb_config(list(memory_limits = "4GB")),
               "Unknown `duckdb_config` field")
  expect_error(snowball_duckdb_config(concurrency = 0), "concurrency")
  expect_error(.osb_resolve_duckdb_config("4GB"), "must be a list")
})

test_that("snowball_duckdb_config returns a validated object", {
  cfg <- snowball_duckdb_config(memory_limit = "8GB", concurrency = 4)
  expect_s3_class(cfg, "openalexSnowball_duckdb_config")
  expect_identical(cfg$memory_limit, "8GB")
  expect_identical(.osb_resolve_duckdb_config(cfg)$concurrency, 4)
})

test_that(".osb_con applies the settings it is given", {
  out <- withr::local_tempdir()
  duck <- .osb_con(
    .osb_resolve_duckdb_config(list(
      memory_limit = "1GB", threads = 2L, preserve_insertion_order = TRUE
    )),
    tag = "nodes", output = out
  )
  on.exit({
    DBI::dbDisconnect(duck$con, shutdown = TRUE)
    unlink(duck$temp_dir, recursive = TRUE, force = TRUE)
  }, add = TRUE)

  get1 <- function(k) {
    DBI::dbGetQuery(duck$con,
                    sprintf("SELECT current_setting('%s') AS v", k))$v[[1L]]
  }
  expect_equal(.osb_parse_bytes(get1("memory_limit")), 1e9, tolerance = 0.01)
  expect_equal(as.integer(get1("threads")), 2L)
  expect_true(as.logical(get1("preserve_insertion_order")))
  expect_true(dir.exists(duck$temp_dir))
  expect_match(get1("temp_directory"), "nodes$")
})

test_that("spill directories are private per call and per stage", {
  # DuckDB's default is `.tmp` relative to the working directory, which every
  # concurrent pro_snowball() would share -- colliding
  # duckdb_temp_storage_*.tmp files corrupt each other's spill.
  cfg <- .osb_resolve_duckdb_config(NULL)
  a <- .osb_temp_dir(cfg$temp_directory, "nodes", "/out/one")
  b <- .osb_temp_dir(cfg$temp_directory, "nodes", "/out/two")
  c1 <- .osb_temp_dir(cfg$temp_directory, "edges", "/out/one")

  expect_false(identical(a, b))   # different outputs
  expect_false(identical(a, c1))  # different stages
  expect_true(startsWith(a, tempdir()))
})

test_that("a user-supplied temp_directory is a root, not the final path", {
  # Setting one fast-disk path for a whole worker pool must stay safe; using
  # it verbatim would re-create the collision this guards against.
  a <- .osb_temp_dir("/fast/spill", "nodes", "/out/one")
  b <- .osb_temp_dir("/fast/spill", "nodes", "/out/two")
  expect_true(startsWith(a, "/fast/spill"))
  expect_false(identical(a, b))
  expect_match(a, "nodes$")
})

test_that("memory and thread budgets divide by the declared concurrency", {
  skip_if(is.na(.osb_total_ram_bytes()), "could not determine RAM")
  one  <- .osb_parse_bytes(.osb_auto_memory(1L))
  four <- .osb_parse_bytes(.osb_auto_memory(4L))
  expect_gt(one, four)
  # never below the 1 GB floor
  expect_gte(.osb_parse_bytes(.osb_auto_memory(10000L)), 1024^3)
  expect_gte(.osb_auto_threads(1L), .osb_auto_threads(8L))
  expect_gte(.osb_auto_threads(10000L), 1L)
})

test_that("keypaper ids come back sorted", {
  # Their order flows into pro_query()'s filter URLs, which VCR matches on.
  # Without ORDER BY that order is unspecified, and with
  # preserve_insertion_order = false it becomes nondeterministic -- turning a
  # clean cassette break into an intermittent one.
  tmp <- withr::local_tempdir()
  kp <- file.path(tmp, "keypaper_parquet")
  dir.create(kp, recursive = TRUE)
  con <- DBI::dbConnect(duckdb::duckdb())
  on.exit(DBI::dbDisconnect(con, shutdown = TRUE), add = TRUE)
  DBI::dbExecute(con, "SET preserve_insertion_order = false")

  for (i in 1:2) {
    ids <- if (i == 1) c("W9", "W3", "W7") else c("W1", "W8", "W2")
    DBI::dbExecute(con, sprintf(
      "COPY (SELECT * FROM (VALUES ('%s'), ('%s'), ('%s')) t(id))
       TO '%s' (FORMAT PARQUET)",
      ids[1], ids[2], ids[3], file.path(kp, sprintf("p%d.parquet", i))
    ))
  }
  got <- .osb_keypaper_ids(con, kp)
  expect_identical(got, sort(got))
  expect_setequal(got, c("W1", "W2", "W3", "W7", "W8", "W9"))
})

test_that("pro_snowball validates duckdb_config before doing any work", {
  # A typo'd field must fail immediately, not after hours of fetching.
  expect_error(
    pro_snowball(identifier = "W123", duckdb_config = list(memory_limits = "4GB")),
    "Unknown `duckdb_config` field"
  )
})
