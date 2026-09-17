# Resume.
#
# Uses the offline snapshot fixture rather than VCR: resume tests need to run
# the pipeline repeatedly and inspect what was and was not rebuilt, which
# wants a deterministic, network-free substrate.

complete_run <- function(env = parent.frame()) {
  fx <- make_snapshot_fixture(env = env)
  out <- withr::local_tempdir(.local_envir = env)
  res <- pro_snowball(identifier = fx$ids, snapshot = fx$root,
                      output = out, verbose = FALSE)
  list(fx = fx, out = out, res = res,
       nodes = read_snowball(res, return_data = TRUE)$nodes,
       edges = read_snowball(res, return_data = TRUE)$edges)
}

test_that("a completed run records its stages and manifest", {
  r <- complete_run()
  expect_true(file.exists(file.path(r$out, "_snowball_run.parquet")))
  expect_true(.osb_stage_done(r$out, "nodes"))
  expect_true(.osb_stage_done(r$out, "edges"))
})

test_that("resuming a complete run is a no-op", {
  r <- complete_run()
  before <- file.mtime(list.files(file.path(r$out, "nodes"), recursive = TRUE,
                                  full.names = TRUE))
  again <- pro_snowball(identifier = r$fx$ids, snapshot = r$fx$root,
                        output = r$out, resume = TRUE, verbose = FALSE)
  after <- file.mtime(list.files(file.path(r$out, "nodes"), recursive = TRUE,
                                 full.names = TRUE))
  expect_identical(before, after)
  expect_equal(nrow(read_snowball(again, return_data = TRUE)$nodes),
               nrow(r$nodes))
})

test_that("resume rebuilds only the edges when only edges are missing", {
  r <- complete_run()
  node_before <- file.mtime(list.files(file.path(r$out, "nodes"),
                                       recursive = TRUE, full.names = TRUE))
  unlink(file.path(r$out, "edges"), recursive = TRUE)
  unlink(file.path(.osb_done_dir(r$out), "edges"))

  res <- suppressWarnings(pro_snowball(
    identifier = r$fx$ids, snapshot = r$fx$root,
    output = r$out, resume = TRUE, verbose = FALSE
  ))
  got <- read_snowball(res, return_data = TRUE)

  expect_identical(
    file.mtime(list.files(file.path(r$out, "nodes"), recursive = TRUE,
                          full.names = TRUE)),
    node_before
  )
  expect_equal(nrow(got$edges), nrow(r$edges))
  expect_equal(nrow(got$nodes), nrow(r$nodes))
})

test_that("a forced re-assembly does not duplicate nodes", {
  # The regression test for the old APPEND: assembling twice into a surviving
  # nodes/ used to double every row, re-creating exactly the duplicate ids
  # that 0.12.1 removed.
  r <- complete_run()
  unlink(file.path(.osb_done_dir(r$out), "nodes"))
  unlink(file.path(.osb_done_dir(r$out), "edges"))

  res <- suppressWarnings(pro_snowball(
    identifier = r$fx$ids, snapshot = r$fx$root,
    output = r$out, resume = TRUE, verbose = FALSE
  ))
  n <- read_snowball(res, return_data = TRUE)$nodes
  expect_equal(nrow(n), nrow(r$nodes))
  expect_equal(nrow(n), dplyr::n_distinct(n$id))
})

test_that("resuming a different snowball is an error, naming the field", {
  # The most important safety property here: continuing with a different
  # seed set would splice two snowballs into one output, silently.
  r <- complete_run()
  unlink(file.path(.osb_done_dir(r$out), "edges"))
  expect_error(
    pro_snowball(identifier = r$fx$ids[1], snapshot = r$fx$root,
                 output = r$out, resume = TRUE, verbose = FALSE),
    "seed_hash"
  )
})

test_that("resume on a fresh path is not an error", {
  # So that `resume = TRUE` is safe to leave permanently in a script.
  fx <- make_snapshot_fixture()
  out <- file.path(withr::local_tempdir(), "never-existed")
  expect_no_error(
    res <- suppressWarnings(pro_snowball(
      identifier = fx$ids, snapshot = fx$root,
      output = out, resume = TRUE, verbose = FALSE
    ))
  )
  expect_gt(nrow(read_snowball(res, return_data = TRUE)$nodes), 0L)
})

test_that("resume into a directory that is not a snowball errors clearly", {
  fx <- make_snapshot_fixture()
  out <- withr::local_tempdir()
  writeLines("not a snowball", file.path(out, "stray.txt"))
  expect_error(
    pro_snowball(identifier = fx$ids, snapshot = fx$root,
                 output = out, resume = TRUE, verbose = FALSE),
    "not produced by a resumable run"
  )
})

test_that("resume = FALSE still wipes an existing output", {
  # Backwards compatibility guard.
  r <- complete_run()
  writeLines("marker", file.path(r$out, "marker.txt"))
  pro_snowball(identifier = r$fx$ids, snapshot = r$fx$root,
               output = r$out, verbose = FALSE)
  expect_false(file.exists(file.path(r$out, "marker.txt")))
})

test_that("intermediates are cleaned after edges, and kept on request", {
  r <- complete_run()
  # Cleanup is deferred until after edge extraction, but it does still happen.
  expect_false(dir.exists(file.path(r$out, "keypaper_parquet")))

  fx <- make_snapshot_fixture()
  out <- withr::local_tempdir()
  pro_snowball(identifier = fx$ids, snapshot = fx$root, output = out,
               keep_intermediates = TRUE, verbose = FALSE)
  expect_true(dir.exists(file.path(out, "keypaper_parquet")))
})

test_that("a failure names the output, the stage and how to resume", {
  fx <- make_snapshot_fixture()
  out <- withr::local_tempdir()
  # An unreadable snapshot path fails inside get_nodes.
  err <- tryCatch(
    pro_snowball(identifier = fx$ids, snapshot = file.path(out, "nope"),
                 output = out, verbose = FALSE),
    error = function(e) conditionMessage(e)
  )
  expect_match(err, "Snowball failed during stage")
  # basename, not the full path: pro_snowball() reports normalizePath(output),
  # which on Windows returns backslashes while withr::local_tempdir() hands
  # back forward slashes, so comparing the whole string fails there for no
  # interesting reason.
  expect_match(err, basename(out), fixed = TRUE)
  expect_match(err, "Intermediate results are preserved at")
  expect_match(err, "resume = TRUE")
  # and it must say so when the work is about to vanish with the session
  expect_match(err, "tempdir")
})

test_that("resume with a tempdir output warns that nothing will survive", {
  # This is the exact circumstance that turned a recoverable crash into six
  # lost hours, so it is worth saying before the run rather than after it.
  fx <- make_snapshot_fixture()
  # A path that does not exist yet, so the manifest check does not fire first.
  out <- file.path(withr::local_tempdir(), "fresh")
  expect_warning(
    pro_snowball(identifier = fx$ids, snapshot = fx$root, output = out,
                 resume = TRUE, verbose = FALSE),
    "nothing will survive"
  )
})
