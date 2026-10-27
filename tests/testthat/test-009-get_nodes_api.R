# API path of pro_snowball_get_nodes(), with openalexPro mocked.
#
# test-004 replays one VCR cassette, which pins the request URLs for exactly
# one keypaper set at workers = 1. These tests replace pro_query() /
# pro_request() / pro_request_parquet() with recorders, so the arguments the
# pipeline hands to openalexPro can be asserted directly, and paths the
# cassette cannot reach (DOI input, workers > 1, an empty API answer) run
# offline.

oa <- function(x) paste0("https://openalex.org/", x)

# Tiny closed graph: W1, W2 are keypapers; W3 cites W1; W1 cites W4.
api_records <- list(
  keypaper = data.frame(id = oa(c("W2", "W1")), title = c("two", "one")),
  citing   = data.frame(id = oa("W3"), title = "three"),
  cited    = data.frame(id = oa("W4"), title = "four")
)
api_records$keypaper$referenced_works <- list(character(0), oa("W4"))
api_records$citing$referenced_works   <- list(oa("W1"))
api_records$cited$referenced_works    <- list(character(0))

#' Mock the three openalexPro calls and record their arguments
#' @return An environment with `query`, `request` and `parquet` lists.
mock_openalexPro <- function(records = api_records, env = parent.frame()) {
  calls <- new.env()
  calls$query <- list()
  calls$request <- list()
  calls$parquet <- list()
  testthat::local_mocked_bindings(
    pro_query = function(...) {
      calls$query[[length(calls$query) + 1L]] <- list(...)
      "mock://query"
    },
    pro_request = function(query_url, output, ...) {
      calls$request[[length(calls$request) + 1L]] <-
        c(list(query_url = query_url, output = output), list(...))
      dir.create(output, recursive = TRUE, showWarnings = FALSE)
      output
    },
    pro_request_parquet = function(input_json, output, add_columns, ...) {
      calls$parquet[[length(calls$parquet) + 1L]] <-
        c(list(input_json = input_json, output = output,
               add_columns = add_columns), list(...))
      rec <- records[[add_columns$relation]]
      if (!is.null(rec) && nrow(rec) > 0L) {
        rec$oa_input <- add_columns$oa_input
        rec$relation <- add_columns$relation
        d <- file.path(output, "query=chunk_1")
        dir.create(d, recursive = TRUE, showWarnings = FALSE)
        arrow::write_parquet(rec, file.path(d, "page_1.parquet"))
      }
      output
    },
    .package = "openalexPro",
    .env = env
  )
  calls
}

test_that("the API path builds a complete snowball from openalexPro output", {
  calls <- mock_openalexPro()
  out <- withr::local_tempdir()
  res <- pro_snowball(identifier = c("W1", "W2"), output = out,
                      verbose = FALSE)
  sb <- read_snowball(res, return_data = TRUE, shorten_ids = TRUE)

  expect_setequal(sb$nodes$id, c("W1", "W2", "W3", "W4"))
  expect_setequal(sb$nodes$id[sb$nodes$is_keypaper], c("W1", "W2"))
  expect_identical(sb$nodes$id[sb$nodes$is_citing], "W3")
  expect_identical(sb$nodes$id[sb$nodes$is_cited], "W4")
  expect_type(sb$nodes$oa_input, "logical")

  edges <- sb$edges[order(sb$edges$from), c("from", "to", "edge_type")]
  expect_identical(edges$from, c("W1", "W3"))
  expect_identical(edges$to, c("W4", "W1"))
  expect_true(all(edges$edge_type == "core"))

  meta <- read_snowball(res, meta = TRUE)$meta
  expect_identical(meta$mode, "api")
  expect_identical(meta$keypapers, paste(oa(c("W1", "W2")), collapse = ","))
})

test_that("the API path queries keypapers, then citing and cited by sorted id", {
  calls <- mock_openalexPro()
  out <- withr::local_tempdir()
  pro_snowball_get_nodes(identifier = c("W2", "W1"), output = out,
                         endpoint = "https://oa.internal/", verbose = FALSE)

  expect_length(calls$query, 3L)
  expect_identical(calls$query[[1]]$id, c("W2", "W1"))
  # Keypaper ids come back from the parquet sorted, whatever the input order:
  # the cites / cited_by URLs are a function of the set, not the order.
  expect_identical(calls$query[[2]]$cites, oa(c("W1", "W2")))
  expect_identical(calls$query[[3]]$cited_by, oa(c("W1", "W2")))
  for (q in calls$query) {
    expect_identical(q$entity, "works")
    expect_identical(q$endpoint, "https://oa.internal")
    expect_identical(q$chunk_limit, 50L)
  }

  rels <- vapply(calls$parquet, function(p) p$add_columns$relation, "")
  expect_identical(rels, c("keypaper", "citing", "cited"))
  oa_input <- vapply(calls$parquet, function(p) p$add_columns$oa_input, "")
  expect_identical(oa_input, c("TRUE", "FALSE", "FALSE"))
  expect_identical(
    basename(vapply(calls$request, `[[`, "", "output")),
    c("keypaper_json", "citing_json", "cited_json")
  )
  # workers = 1 is sequential: 1 for pro_request(), NULL for the converter.
  expect_identical(calls$request[[1]]$workers, 1L)
  expect_null(calls$parquet[[1]]$workers)
})

test_that("DOIs are handed to pro_query() as doi =, not id =", {
  calls <- mock_openalexPro()
  out <- withr::local_tempdir()
  pro_snowball_get_nodes(doi = c("10.1/a", "10.1/b"), output = out,
                         verbose = FALSE)
  expect_identical(calls$query[[1]]$doi, c("10.1/a", "10.1/b"))
  expect_null(calls$query[[1]]$id)
})

test_that("limit restricts which directions are requested", {
  calls <- mock_openalexPro()
  out <- withr::local_tempdir()
  pro_snowball_get_nodes(identifier = "W1", limit = "onlyCiting",
                         output = out, verbose = FALSE)
  expect_identical(names(calls$query[[2]])[1], "cites")
  expect_length(calls$query, 2L)

  calls <- mock_openalexPro()
  pro_snowball_get_nodes(identifier = "W1", limit = "onlyCited",
                         output = out, verbose = FALSE)
  expect_identical(names(calls$query[[2]])[1], "cited_by")
  expect_length(calls$query, 2L)
  nodes <- arrow::open_dataset(file.path(out, "nodes")) |> dplyr::collect()
  expect_false(any(nodes$is_citing))
})

test_that("workers > 1 shrinks chunk_limit and says so when verbose", {
  calls <- mock_openalexPro()
  out <- withr::local_tempdir()
  msgs <- testthat::capture_messages(
    pro_snowball_get_nodes(identifier = c("W1", "W2"), workers = 3L,
                           output = out, verbose = TRUE)
  )
  expect_true(any(grepl(
    "Using chunk_limit = 10 for 3 workers (1 chunk URLs)", msgs, fixed = TRUE
  )))
  expect_identical(calls$query[[2]]$chunk_limit, 10L)
  expect_identical(calls$request[[2]]$workers, 3L)
  expect_identical(calls$parquet[[2]]$workers, 3L)
})

test_that("verbose = TRUE reports each stage of the API path", {
  mock_openalexPro()
  out <- withr::local_tempdir()
  writeLines("stale", file.path(out, "stale.txt"))
  msgs <- testthat::capture_messages(
    res <- pro_snowball_get_nodes(identifier = c("W1", "W2"), output = out,
                                  verbose = TRUE)
  )
  expect_true(any(grepl("Deleting and recreating", msgs)))
  expect_true(any(grepl("Collecting keypapers", msgs)))
  expect_true(any(grepl("citing the target keypapers", msgs)))
  expect_true(any(grepl("cited by the keypapers", msgs)))
  expect_true(any(grepl("Wrote 2 nodes to relation = 'keypaper'", msgs)))
  # the pre-existing content was wiped, and cleanup = TRUE removed the
  # intermediates once the nodes were assembled
  expect_false(file.exists(file.path(out, "stale.txt")))
  expect_false(dir.exists(file.path(out, "keypaper_parquet")))
  expect_false(dir.exists(file.path(out, "citing_json")))
  expect_true(dir.exists(res))
})

test_that("keypapers the API no longer returns are a clear error", {
  # Works get merged or withdrawn; without the check DuckDB failed on an
  # empty glob naming a temp path.
  mock_openalexPro(records = list())
  out <- withr::local_tempdir()
  expect_error(
    pro_snowball_get_nodes(identifier = c("W1", "W2"), output = out,
                           verbose = FALSE),
    "returned no records for the requested keypaper\\(s\\): W1, W2"
  )
  expect_error(
    pro_snowball_get_nodes(doi = "10.1/gone", output = out, verbose = FALSE),
    "10.1/gone.*merged or withdrawn"
  )
})

test_that("resuming get_nodes with nodes already assembled makes no request", {
  calls <- mock_openalexPro()
  out <- withr::local_tempdir()
  pro_snowball_get_nodes(identifier = "W1", output = out, verbose = FALSE)
  n_before <- length(calls$query)

  expect_message(
    res <- pro_snowball_get_nodes(identifier = "W1", output = out,
                                  resume = TRUE, verbose = TRUE),
    "Resuming: nodes/ already assembled"
  )
  expect_identical(length(calls$query), n_before)
  expect_identical(res, normalizePath(file.path(out, "nodes")))
})

test_that("get_nodes validates limit and the identifier / doi choice", {
  expect_error(pro_snowball_get_nodes(identifier = "W1", limit = "both"),
               "`limit` has to be")
  expect_error(pro_snowball_get_nodes(), "Either `identifier` or `doi`")
  expect_error(pro_snowball_get_nodes(identifier = "W1", doi = "10.1/a"),
               "Either `identifier` or `doi`")
  expect_error(pro_snowball(), "Either `identifier` or `doi`")
  expect_error(pro_snowball(identifier = "W1", doi = "10.1/a"),
               "Either `identifier` or `doi`")
})
