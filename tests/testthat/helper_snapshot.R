# Shared offline-snowball fixture.
#
# The corpus generator lives in openalexSnapshot (inst/testdata) so there is
# one copy rather than two that drift apart.

# `local = TRUE` evaluates it here rather than in globalenv. Under
# `devtools::test()` / `test_local()` the test environment does not see
# globalenv, so the default would define `make_tiny_corpus()` somewhere the
# tests cannot reach -- `test_dir()` happens to work, which is what hid it.
source(system.file("testdata/make_tiny_corpus.R", package = "openalexSnapshot"),
       local = TRUE)

#' Build a closed test corpus with all three indexes
#'
#' "Closed" meaning the works cite each other, which a real snapshot slice of a
#' single `updated_date=` partition generally is not -- works there cite older
#' works living in other partitions, so no core edges would exist.
#'
#' @return List with `root` (the parquet directory) and `ids` (short ids).
#' @noRd
make_snapshot_fixture <- function(env = parent.frame()) {
  tmp <- withr::local_tempdir(.local_envir = env)
  corpus <- make_tiny_corpus(tmp)
  openalexSnapshot::build_corpus_index(corpus_dir = corpus, backend = "r",
                                       verbose = FALSE)
  openalexSnapshot::build_doi_index(corpus_dir = corpus, verbose = FALSE)
  openalexSnapshot::build_citation_index(corpus_dir = corpus, verbose = FALSE)
  list(root = file.path(tmp, "parquet"), ids = tiny_ids())
}
