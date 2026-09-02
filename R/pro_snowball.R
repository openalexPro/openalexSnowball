#' A function to perform a snowball search and convert the result to a
#' tibble/data frame.
#' @param identifier Character vector of openalex identifiers.
#' @param doi Character vector of dois.
#' @param snapshot Path to a local OpenAlex snapshot (either a root directory
#'   containing `parquet/`, or the `parquet/` directory itself). When supplied,
#'   the whole snowball is built **offline** from the snapshot instead of the
#'   OpenAlex API; when `NULL` (the default) behaviour is unchanged.
#'
#'   Snapshot mode requires the indexes built by
#'   `openalexSnapshot::build_corpus_index()` and
#'   `openalexSnapshot::build_citation_index()`, plus
#'   `openalexSnapshot::build_doi_index()` if keypapers are given as DOIs.
#'
#'   The output construct is identical -- `nodes/` and `edges/` partitioned the
#'   same way, readable by [read_snowball()] -- but the **node columns differ**,
#'   because snapshot records are not API records. Snapshot nodes carry
#'   whatever the works corpus holds plus `oa_input` and `relation`; there is no
#'   `page` column, which is an API pagination artefact. Results are also frozen
#'   at the snapshot's vintage rather than live.
#' @param max_results Snapshot mode only: refuse to expand a keypaper with more
#'   citing works than this. A heavily cited work can have hundreds of thousands
#'   of citers, and extracting records for all of them would read most of the
#'   corpus.
#' @param output parquet dataset; default: temporary directory.
#' @param verbose Logical indicating whether to show a verbose information.
#'   Defaults to `FALSE`
#'
#' @return The folder of the results containing multiple subfolders.
#'
#' @export
#'
#' @importFrom duckdb duckdb duckdb_register_arrow
#' @importFrom DBI dbConnect dbDisconnect dbExecute
#' @importFrom arrow write_parquet
#'
#' @md
#'
pro_snowball <- function(
  identifier = NULL,
  doi = NULL,
  snapshot = NULL,
  max_results = 100000L,
  output = tempfile(fileext = ".snowball"),
  verbose = FALSE
) {
  if (!xor(is.null(identifier), is.null(doi))) {
    stop("Either `identifier` or `doi` needs to be specified!")
  }

  output <- normalizePath(output, mustWork = FALSE)

  if (dir.exists(output)) {
    if (verbose) {
      message(
        "Deleting and recreating `",
        output,
        "` to avoid inconsistencies."
      )
    }
    unlink(output, recursive = TRUE)
    dir.create(output, recursive = TRUE)
  }

  nodes <- pro_snowball_get_nodes(
    identifier = identifier,
    doi = doi,
    snapshot = snapshot,
    max_results = max_results,
    output = output,
    verbose = verbose
  )
  edges <- pro_snowball_extract_edges(
    nodes = nodes,
    output = output,
    verbose = verbose
  )

  unlink(
    c(
      file.path(output, "keypaper_json"),
      file.path(output, "keypaper_jsonl")
    ),
    recursive = TRUE
  )

  # Return path to snowball ------------------------------------------------

  return(normalizePath(output))
}
