# Offline snowball: pro_snowball(snapshot = ...).
#
# No network and no VCR cassettes -- the whole point is that this path never
# touches the API.

test_that("snapshot mode produces the same construct as the API path", {
  f <- make_snapshot_fixture()
  out <- withr::local_tempdir()
  unlink(out, recursive = TRUE)

  res <- pro_snowball(identifier = f$ids[c(1, 4)], snapshot = f$root,
                      output = out, verbose = FALSE)

  expect_equal(res, normalizePath(out))
  # nodes/ and edges/ and nothing else: all intermediates are cleaned up
  expect_setequal(list.files(res), c("nodes", "edges"))

  expect_setequal(
    list.files(file.path(res, "nodes")),
    c("relation=keypaper", "relation=citing", "relation=cited")
  )
  expect_true(all(list.files(file.path(res, "edges")) %in%
                    c("edge_type=core", "edge_type=extended", "edge_type=outside")))
})

test_that("read_snowball() reads the offline construct unmodified", {
  f <- make_snapshot_fixture()
  out <- withr::local_tempdir(); unlink(out, recursive = TRUE)
  res <- pro_snowball(identifier = f$ids[c(1, 4)], snapshot = f$root,
                      output = out, verbose = FALSE)

  sb <- read_snowball(res, return_data = TRUE, shorten_ids = TRUE)
  expect_named(sb, c("nodes", "edges"))
  expect_equal(sort(names(sb$edges)), c("edge_type", "from", "to"))
  expect_gt(nrow(sb$nodes), 0L)

  # oa_input is BOOLEAN after assembly, TRUE for exactly the keypapers
  expect_type(sb$nodes$oa_input, "logical")
  expect_setequal(sb$nodes$id[sb$nodes$oa_input], f$ids[c(1, 4)])

  # every edge_type filter combination works
  for (et in list("core", "extended", "outside", c("core", "extended"))) {
    expect_no_error(read_snowball(res, return_data = TRUE, edge_type = et))
  }
})

test_that("the three edge_type classes are mutually exclusive", {
  # The implementation in inst/extract_edges.sql makes them exclusive, while
  # ?read_snowball describes extended as a superset of core. This test pins the
  # actual behaviour so a future fix to either fails loudly rather than
  # changing semantics silently.
  f <- make_snapshot_fixture()
  out <- withr::local_tempdir(); unlink(out, recursive = TRUE)
  res <- pro_snowball(identifier = f$ids[c(1, 4)], snapshot = f$root,
                      output = out, verbose = FALSE)

  n <- function(et) nrow(read_snowball(res, return_data = TRUE,
                                       edge_type = et)$edges)
  expect_equal(n("core") + n("extended"), n(c("core", "extended")))
  expect_equal(n("core") + n("extended") + n("outside"),
               n(c("core", "extended", "outside")))
})

test_that("edges orient as A cites B and come only from referenced_works", {
  f <- make_snapshot_fixture()
  out <- withr::local_tempdir(); unlink(out, recursive = TRUE)
  res <- pro_snowball(identifier = f$ids[1], snapshot = f$root,
                      output = out, verbose = FALSE)

  sb <- read_snowball(res, return_data = TRUE, shorten_ids = TRUE)
  # `from` is always a node in the dataset; `to` may be outside it
  expect_true(all(sb$edges$from %in% sb$nodes$id))
  expect_true(any(!sb$edges$to %in% sb$nodes$id))   # the dangling refs
})

test_that("snapshot nodes use the snapshot-native schema", {
  f <- make_snapshot_fixture()
  out <- withr::local_tempdir(); unlink(out, recursive = TRUE)
  res <- pro_snowball(identifier = f$ids[1], snapshot = f$root,
                      output = out, verbose = FALSE)

  sb <- read_snowball(res, return_data = TRUE)
  # `page` is an API pagination artefact with no snapshot analogue; it is
  # deliberately absent rather than faked. Documented in ?pro_snowball.
  expect_false("page" %in% names(sb$nodes))
  expect_true(all(c("id", "oa_input", "relation", "referenced_works") %in%
                    names(sb$nodes)))
})

test_that("keypapers may be given as DOIs, with or without a resolver", {
  f <- make_snapshot_fixture()
  out <- withr::local_tempdir(); unlink(out, recursive = TRUE)

  # The second is a real SICI DOI containing [ ], supplied with a resolver:
  # it exercises DOI normalisation end to end through the whole snowball.
  res <- pro_snowball(
    doi = c("10.1234/test.1",
            "https://doi.org/10.1577/1548-8659(1973)35[142:amosss]2.0.co;2"),
    snapshot = f$root, output = out, verbose = FALSE)
  sb <- read_snowball(res, return_data = TRUE, shorten_ids = TRUE)
  expect_setequal(sb$nodes$id[sb$nodes$oa_input], f$ids[c(1, 4)])
})

test_that("a keypaper absent from the snapshot warns rather than vanishing", {
  f <- make_snapshot_fixture()
  out <- withr::local_tempdir(); unlink(out, recursive = TRUE)

  expect_warning(
    pro_snowball(identifier = c(f$ids[1], "W999999999"), snapshot = f$root,
                 output = out, verbose = FALSE),
    "not present in the snapshot"
  )
})

test_that("no resolvable keypaper is an error, not an empty snowball", {
  f <- make_snapshot_fixture()
  out <- withr::local_tempdir(); unlink(out, recursive = TRUE)

  expect_error(
    pro_snowball(identifier = "W999999999", snapshot = f$root, output = out,
                 verbose = FALSE),
    "None of the keypapers"
  )
})

test_that("snapshot may be given as a root_dir or as the parquet dir", {
  f <- make_snapshot_fixture()
  root_dir <- dirname(f$root)

  o1 <- withr::local_tempdir(); unlink(o1, recursive = TRUE)
  o2 <- withr::local_tempdir(); unlink(o2, recursive = TRUE)
  a <- pro_snowball(identifier = f$ids[1], snapshot = f$root, output = o1,
                    verbose = FALSE)
  b <- pro_snowball(identifier = f$ids[1], snapshot = root_dir, output = o2,
                    verbose = FALSE)

  na <- read_snowball(a, return_data = TRUE)$nodes
  nb <- read_snowball(b, return_data = TRUE)$nodes
  expect_equal(sort(na$id), sort(nb$id))
})

test_that("a missing citation index names the builder that creates it", {
  tmp <- withr::local_tempdir()
  corpus <- make_tiny_corpus(tmp)
  openalexSnapshot::build_corpus_index(corpus_dir = corpus, backend = "r",
                                       verbose = FALSE)
  out <- withr::local_tempdir(); unlink(out, recursive = TRUE)

  expect_error(
    pro_snowball(identifier = tiny_ids()[1], snapshot = file.path(tmp, "parquet"),
                 output = out, verbose = FALSE),
    "build_citation_index"
  )
})
