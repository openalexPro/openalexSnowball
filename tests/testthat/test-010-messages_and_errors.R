# Progress messages and error paths of the snapshot pipeline, the edge
# extraction, node assembly and read_snowball().
#
# Offline throughout: the snapshot fixture (helper_snapshot.R) or a few rows
# written straight into the *_parquet directories the fetchers produce.

#' Write one `<rel>_parquet` directory the way the fetchers do
write_rel <- function(output, rel, ids, refs = NULL) {
  d <- file.path(output, paste0(rel, "_parquet"))
  dir.create(d, recursive = TRUE, showWarnings = FALSE)
  df <- data.frame(id = paste0("https://openalex.org/", ids),
                   oa_input = if (rel == "keypaper") "TRUE" else "FALSE",
                   relation = rel)
  df$referenced_works <- refs %||% rep(list(character(0)), length(ids))
  arrow::write_parquet(df, file.path(d, "data_0.parquet"))
  invisible(d)
}

test_that("verbose = TRUE reports each stage of a snapshot snowball", {
  fx <- make_snapshot_fixture()
  out <- withr::local_tempdir()
  writeLines("stale", file.path(out, "stale.txt"))

  msgs <- testthat::capture_messages(
    res <- pro_snowball(identifier = fx$ids, snapshot = fx$root,
                        output = out, verbose = TRUE)
  )
  expect_true(any(grepl("Deleting and recreating", msgs)))
  expect_true(any(grepl("Resolving keypapers against the snapshot", msgs)))
  expect_true(any(grepl("Collecting citing documents from the snapshot", msgs)))
  expect_true(any(grepl("Collecting cited documents from the snapshot", msgs)))
  expect_true(any(grepl("Wrote [0-9]+ nodes to relation = 'keypaper'", msgs)))
  expect_false(file.exists(file.path(out, "stale.txt")))
  expect_gt(nrow(read_snowball(res, return_data = TRUE)$edges), 0L)
})

test_that("verbose resume says whether there is anything left to do", {
  fx <- make_snapshot_fixture()
  out <- withr::local_tempdir()
  pro_snowball(identifier = fx$ids, snapshot = fx$root, output = out,
               verbose = FALSE)

  expect_message(
    res <- pro_snowball(identifier = fx$ids, snapshot = fx$root,
                        output = out, resume = TRUE, verbose = TRUE),
    "Nothing to do: .* is already complete"
  )
  expect_identical(res, normalizePath(out))

  unlink(file.path(.osb_done_dir(out), "edges"))
  # suppressWarnings: the tempdir-resume warning is test-008's subject
  msgs <- suppressWarnings(testthat::capture_messages(
    pro_snowball(identifier = fx$ids, snapshot = fx$root, output = out,
                 resume = TRUE, verbose = TRUE)
  ))
  expect_true(any(grepl("Resuming in", msgs)))
  expect_true(any(grepl("Resuming: nodes/ already assembled", msgs)))
  expect_true(.osb_stage_done(out, "edges"))
})

test_that("a DOI the snapshot cannot resolve is an error, not an empty snowball", {
  fx <- make_snapshot_fixture()
  out <- withr::local_tempdir()
  expect_error(
    suppressWarnings(
      pro_snowball_get_nodes(doi = "10.9999/not.in.the.snapshot",
                             snapshot = fx$root, output = out,
                             verbose = FALSE)
    ),
    "No keypapers could be resolved against the snapshot"
  )
})

test_that("re-extracting edges replaces edges/ rather than appending to it", {
  fx <- make_snapshot_fixture()
  out <- withr::local_tempdir()
  res <- pro_snowball(identifier = fx$ids, snapshot = fx$root, output = out,
                      verbose = FALSE)
  n_first <- nrow(read_snowball(res, return_data = TRUE)$edges)

  expect_message(
    pro_snowball_extract_edges(nodes = file.path(out, "nodes"), output = out,
                               verbose = TRUE),
    "Deleting and recreating `.*edges`"
  )
  expect_identical(nrow(read_snowball(res, return_data = TRUE)$edges),
                   n_first)
})

test_that("read_snowball() checks its directory argument", {
  expect_error(read_snowball(), "Directory `snowball` missing!")
  expect_error(read_snowball(file.path(withr::local_tempdir(), "nope")),
               "Directory `snowball` does not exist!")
})

snowball_without_meta <- function(env = parent.frame()) {
  fx <- make_snapshot_fixture(env = env)
  out <- withr::local_tempdir(.local_envir = env)
  res <- pro_snowball(identifier = fx$ids[1:2], snapshot = fx$root,
                      output = out, verbose = FALSE)
  # as for a snowball written before the provenance sidecar existed
  unlink(file.path(res, "snowball_meta.parquet"))
  res
}

test_that("read_snowball(meta = TRUE) still reads a snowball without sidecar", {
  sb <- read_snowball(snowball_without_meta(), meta = TRUE)
  expect_null(sb$meta)
  expect_gt(nrow(dplyr::collect(sb$nodes)), 0L)
  expect_gt(nrow(dplyr::collect(sb$edges)), 0L)
})

test_that("read_snowball(meta = TRUE) always returns a `meta` element", {
  skip("Known bug: `result$meta <- NULL` drops the element when the sidecar is absent")
  # ?read_snowball: meta = TRUE returns provenance "as a third list element
  # `meta`"; the code means NULL there, but assigning NULL removes it.
  sb <- read_snowball(snowball_without_meta(), meta = TRUE)
  expect_identical(names(sb), c("nodes", "edges", "meta"))
})

test_that(".assemble_nodes() refuses to assemble nothing", {
  out <- withr::local_tempdir()
  # an empty *_parquet directory does not count as collected
  dir.create(file.path(out, "citing_parquet"))
  con <- DBI::dbConnect(duckdb::duckdb())
  on.exit(DBI::dbDisconnect(con, shutdown = TRUE), add = TRUE)
  expect_error(.assemble_nodes(out, con = con), "No nodes were collected.")
})

test_that("a relation whose works were all promoted writes no partition", {
  # W1 is both keypaper and cited: precedence puts it in relation=keypaper,
  # leaving nothing for relation=cited -- which must then be absent rather
  # than an empty partition.
  out <- withr::local_tempdir()
  write_rel(out, "keypaper", "W1", refs = list("https://openalex.org/W1"))
  write_rel(out, "cited", "W1")
  con <- DBI::dbConnect(duckdb::duckdb())
  on.exit(DBI::dbDisconnect(con, shutdown = TRUE), add = TRUE)

  msgs <- testthat::capture_messages(
    .assemble_nodes(out, con = con, verbose = TRUE)
  )
  expect_true(any(grepl("No works survive as relation = 'cited'", msgs)))
  expect_false(any(grepl("relation = 'citing'", msgs)))
  expect_identical(list.files(file.path(out, "nodes")), "relation=keypaper")
  n <- arrow::open_dataset(file.path(out, "nodes")) |> dplyr::collect()
  expect_identical(nrow(n), 1L)
  expect_true(n$is_keypaper && n$is_cited && !n$is_citing)
})

test_that("a nodes/ that cannot be moved into place is an error", {
  skip_on_os("windows") # relies on POSIX directory permissions
  skip_if(identical(Sys.info()[["effective_user"]], "root"))
  out <- withr::local_tempdir()
  write_rel(out, "keypaper", "W1")

  # Make `output` read-only once the partition has been written into
  # .nodes.building, so the final rename to nodes/ is refused -- the state a
  # full or remounted disk leaves behind mid-assembly.
  real_execute <- DBI::dbExecute
  local_mocked_bindings(
    dbExecute = function(conn, statement, ...) {
      res <- real_execute(conn, statement, ...)
      if (startsWith(trimws(statement), "COPY")) Sys.chmod(out, "0555")
      res
    },
    .package = "DBI"
  )
  withr::defer(Sys.chmod(out, "0755"))

  con <- DBI::dbConnect(duckdb::duckdb())
  on.exit(DBI::dbDisconnect(con, shutdown = TRUE), add = TRUE)
  expect_error(
    suppressWarnings(.assemble_nodes(out, con = con)),
    "Could not move assembled nodes into place: .*nodes"
  )
  expect_false(dir.exists(file.path(out, "nodes")))
})
