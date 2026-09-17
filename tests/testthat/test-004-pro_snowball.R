library(testthat)
suppressPackageStartupMessages(library(dplyr))

# ── Shared setup (run once per file) ─────────────────────────────────────────
# VCR cassettes are active for the entire file scope so all test_that blocks
# below can use the pre-built objects without re-running the API calls.

output_dir <- file.path(tempdir(), "snowball")
unlink(output_dir, recursive = TRUE, force = TRUE)

# Reference results from openalexR
vcr::local_cassette("oa_snowball")
results_openalexR <- openalexR::oa_snowball(
  identifier = c("W3045921891", "W3046863325"),
  verbose = FALSE
)
results_openalexR$nodes <- results_openalexR$nodes |>
  dplyr::arrange(dplyr::desc(oa_input), id)
results_openalexR$edges <- results_openalexR$edges |>
  dplyr::arrange(from, to)

# Build the pro_snowball output once; all tests read from output_dir
vcr::local_cassette("pro_snowball")
output_dir <- pro_snowball(
  identifier = c("W3045921891", "W3046863325"),
  output = output_dir,
  verbose = FALSE
)

# Load the snowball for reuse across tests
results_pro <- read_snowball(
  output_dir,
  return_data = TRUE,
  shorten_ids = TRUE,
  edge_type = "core"
)

# Diffs used in the correctness tests
nodes_diff <- dplyr::anti_join(
  results_pro$nodes |> dplyr::select(id, oa_input),
  results_openalexR$nodes |> dplyr::select(id, oa_input),
  by = dplyr::join_by(id, oa_input)
)
edges_diff <- dplyr::anti_join(
  results_pro$edges |> dplyr::filter(edge_type == "core"),
  results_openalexR$edges,
  by = dplyr::join_by(from, to)
)

# ── Structure ─────────────────────────────────────────────────────────────────

test_that("pro_snowball result has nodes and edges", {
  expect_snapshot(names(results_pro))
})

test_that("pro_snowball nodes have expected shape", {
  expect_snapshot({
    nrow(results_pro$nodes)
    sort(names(results_pro$nodes))
  })
})

test_that("pro_snowball edges have expected shape", {
  expect_snapshot({
    nrow(results_pro$edges)
    sort(names(results_pro$edges))
  })
})

# ── read_snowball() edge_type variants ────────────────────────────────────────

# These used to snapshot print(read_snowball(...)) in full, which includes the
# type header of the nested `authorships` struct. That header is produced by
# DuckDB's JSON type inference, and its field order is not stable across
# DuckDB versions -- local 1.5.4 renders
# `author_position, author, institutions, ...` where CI's 1.5.5 renders
# `author, author_position, affiliations, ...`. Identical data, different
# rendering, and the snapshot broke on the difference.
#
# So snapshot what these tests are actually about: the edge set selected by
# `edge_type`, plus the shape of the result. The node schema is covered by
# "pro_snowball nodes have expected shape" (sorted names) and the node content
# by "pro_snowball nodes content (id / oa_input / relation)"; nothing is lost
# here except a dependency on how DuckDB spells a nested type this week.
snap_snowball <- function(...) {
  sb <- read_snowball(output_dir, return_data = TRUE, shorten_ids = TRUE, ...)
  list(
    n_nodes   = nrow(sb$nodes),
    n_edges   = nrow(sb$edges),
    node_cols = sort(names(sb$nodes)),
    edges     = as.data.frame(
      dplyr::arrange(sb$edges, .data$edge_type, .data$from, .data$to)
    )
  )
}

test_that("read_snowball with edge_type = 'core'", {
  expect_snapshot(snap_snowball(edge_type = "core"))
})

test_that("read_snowball with edge_type = 'extended'", {
  expect_snapshot(snap_snowball(edge_type = "extended"))
})

test_that("read_snowball with edge_type = c('extended', 'core')", {
  expect_snapshot(snap_snowball(edge_type = c("extended", "core")))
})

test_that("read_snowball with edge_type = 'outside'", {
  expect_snapshot(snap_snowball(edge_type = "outside"))
})

# ── Content ───────────────────────────────────────────────────────────────────

test_that("pro_snowball nodes content (id / oa_input / relation)", {
  expect_snapshot(
    results_pro$nodes |>
      dplyr::select(id, oa_input, relation) |>
      dplyr::arrange(oa_input, relation) |>
      dplyr::collect() |>
      print(n = Inf)
  )
})

test_that("pro_snowball edges content", {
  expect_snapshot(
    results_pro$edges |>
      dplyr::arrange(edge_type, from, to) |>
      dplyr::collect() |>
      print(n = Inf)
  )
})

# ── Correctness vs openalexR ──────────────────────────────────────────────────

test_that("pro_snowball nodes match openalexR reference (zero diff)", {
  expect_snapshot(print(nodes_diff, n = Inf))
  expect_equal(nrow(nodes_diff), 0L)
})

test_that("pro_snowball edges match openalexR reference (zero diff)", {
  expect_snapshot(print(edges_diff, n = Inf))
  expect_equal(nrow(edges_diff), 0L)
})

# ── Teardown ──────────────────────────────────────────────────────────────────
unlink(output_dir, recursive = TRUE, force = TRUE)
