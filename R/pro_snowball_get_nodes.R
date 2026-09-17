#' A function to get the nodes for a snowball search
#' @param identifier Character vector of openalex identifiers.
#' @param doi Character vector of dois.
#' @param limit If `citedOnly` only works cited by the keypaper are retrieved,
#'   `citingOnly` retrieves only works citing the keypaper. Default: `NULL`
#'   where all will be retrieved. 'none' is equal to `NULL`
#' @param snapshot Path to a local OpenAlex snapshot (either a root directory
#'   containing `parquet/`, or the `parquet/` directory itself). When supplied,
#'   nodes are gathered offline from the snapshot instead of the OpenAlex API.
#'   Requires the indexes built by `openalexSnapshot::build_corpus_index()` and
#'   `build_citation_index()`. Default `NULL` (use the API).
#' @param max_results Snapshot mode only: refuse to expand a keypaper with more
#'   citing works than this. See `openalexSnapshot::get_citing()`.
#' @param workers Number of parallel workers. Default `1` (sequential).
#' @param chunk_limit API mode only: ids per filter URL. `NULL` (default)
#'   derives one from `workers`; see `pro_snowball()`.
#' @param select Snapshot mode only: node columns to keep. See `pro_snowball()`.
#' @param endpoint API mode only: base URL of the OpenAlex API. See
#'   `pro_snowball()`.
#' @param duckdb_config DuckDB settings for the assembly connection. See
#'   [snowball_duckdb_config()].
#' @param resume Keep an existing `output` and continue from where a previous
#'   run stopped, instead of deleting it. Default `FALSE`.
#' @param prepared Internal. `TRUE` means the caller has already created or
#'   cleaned `output` and this function must not delete it.
#' @param cleanup Remove the intermediate `*_json` / `*_parquet` directories
#'   once the nodes are assembled. Default `TRUE`. [pro_snowball()] passes
#'   `FALSE` and cleans up after edge extraction instead, so that a failure
#'   there is still resumable.
#' @param output parquet dataset; default: temporary directory.
#' @param verbose Logical indicating whether to show a verbose information.
#'   Defaults to `FALSE`
#'
#' @return Path to the nodes parquet dataset
#'
#' @export
#'
#' @importFrom duckdb duckdb
#' @importFrom DBI dbConnect dbDisconnect dbExecute dbGetQuery
#'
#' @md
#'
pro_snowball_get_nodes <- function(
  identifier = NULL,
  doi = NULL,
  limit = NULL,
  snapshot = NULL,
  max_results = 100000L,
  workers = 1L,
  chunk_limit = NULL,
  select = NULL,
  endpoint = "https://api.openalex.org",
  duckdb_config = NULL,
  resume = FALSE,
  cleanup = TRUE,
  prepared = FALSE,
  output = tempfile(fileext = ".snowball"),
  verbose = FALSE
) {
  workers <- .check_workers(workers)
  endpoint <- .check_endpoint(endpoint)
  cfg <- .osb_resolve_duckdb_config(duckdb_config)
  if (is.null(limit)) {
    limit <- "none"
  }

  if (!(limit %in% c("onlyCiting", "onlyCited", "none"))) {
    stop("`limit` has to be `NULL`, 'onlyCited' or 'onlyCiting'!")
  }

  if (!xor(is.null(identifier), is.null(doi))) {
    stop("Either `identifier` or `doi` needs to be specified!")
  }

  output <- normalizePath(output, mustWork = FALSE)

  # `prepared = TRUE` means the caller owns the directory lifecycle and has
  # already created or cleaned it -- pro_snowball() does, and it writes the
  # run manifest there before calling us, which this wipe would delete.
  if (dir.exists(output) && !isTRUE(resume) && !isTRUE(prepared)) {
    if (verbose) {
      message(
        "Deleting and recreating `",
        output,
        "` to avoid inconsistencies."
      )
    }
    unlink(output, recursive = TRUE)
  }
  dir.create(output, recursive = TRUE, showWarnings = FALSE)

  # Nothing to do if a previous run already assembled the nodes.
  if (isTRUE(resume) && .osb_stage_done(output, "nodes") &&
      dir.exists(file.path(output, "nodes"))) {
    if (verbose) message("Resuming: nodes/ already assembled.")
    return(normalizePath(file.path(output, "nodes")))
  }

  # Create and setup in memory DuckDB --------------------------------------

  # Configured rather than bare: see R/utils_duckdb.R for why DuckDB's
  # defaults (80% of RAM per instance, and a spill directory relative to the
  # working directory) are wrong for a package callers run several of at once.
  duck <- .osb_con(cfg, tag = "nodes", output = output)
  con <- duck$con

  on.exit(
    {
      try(DBI::dbDisconnect(con, shutdown = TRUE), silent = TRUE)
      if (!is.null(duck$temp_dir)) {
        unlink(duck$temp_dir, recursive = TRUE, force = TRUE)
      }
    },
    add = TRUE
  )

  # Gather nodes: from the snapshot when one is given, else from the API ----

  if (is.null(snapshot)) {
    if (verbose) message("Collecting keypapers...")

    # pro_query() chunks the `openalex` id filter exactly as it chunks
    # cites/cited_by, so a large keypaper set becomes many URLs. They used to
    # be fetched and converted strictly sequentially even at workers = 12 --
    # ~43 URLs for 2137 seeds, straight on the critical path. Derive the
    # chunk size from `workers` for the same reason .nodes_from_api() does.
    kp_chunk <- .chunk_limit_for(
      length(if (!is.null(identifier)) identifier else doi),
      workers, chunk_limit
    )
    qu <- if (!is.null(identifier)) {
      openalexPro::pro_query(id = identifier, entity = "works",
                             endpoint = endpoint, chunk_limit = kp_chunk)
    } else {
      openalexPro::pro_query(doi = doi, entity = "works",
                             endpoint = endpoint, chunk_limit = kp_chunk)
    }
    openalexPro::pro_request(
      query_url = qu,
      output = file.path(output, "keypaper_json"),
      workers = workers,
      resume = resume,
      verbose = verbose,
      progress = verbose
    ) |>
      openalexPro::pro_request_parquet(
        output = file.path(output, "keypaper_parquet"),
        add_columns = list(oa_input = "TRUE", relation = "keypaper"),
        workers = .par_workers(workers),
        resume = resume,
        verbose = verbose
      )

    # A keypaper present locally may no longer resolve through the API -- works
    # get merged or withdrawn, and the API returns nothing for the old id.
    # Without this check the next statement fails with a bare DuckDB glob
    # error naming a temp path, which says nothing about the cause.
    kp_dir <- file.path(output, "keypaper_parquet")
    if (!dir.exists(kp_dir) ||
        length(list.files(kp_dir, pattern = "\\.parquet$", recursive = TRUE)) == 0L) {
      stop("The OpenAlex API returned no records for the requested keypaper(s): ",
           paste(utils::head(if (!is.null(identifier)) identifier else doi, 5L),
                 collapse = ", "),
           ".\nThey may have been merged or withdrawn since. Check them at ",
           "https://api.openalex.org/works?filter=openalex:<id>",
           call. = FALSE)
    }

    keypaper_ids <- .osb_keypaper_ids(con, kp_dir)

    .nodes_from_api(keypaper_ids, output, limit, verbose, workers = workers,
                    chunk_limit = chunk_limit, endpoint = endpoint,
                    resume = resume)
  } else {
    if (verbose) message("Resolving keypapers against the snapshot ...")
    keypaper_ids <- .keypaper_ids_snapshot(identifier, doi, snapshot, verbose)
    if (length(keypaper_ids) == 0L) {
      stop("No keypapers could be resolved against the snapshot.", call. = FALSE)
    }
    .nodes_from_snapshot(keypaper_ids, snapshot, output, limit, verbose,
                         max_results = max_results, workers = workers,
                         select = select)
  }

  .write_snowball_meta(
    output,
    mode      = if (is.null(snapshot)) "api" else "snapshot",
    snapshot  = snapshot,
    keypapers = keypaper_ids,
    limit     = limit
  )

  # Combine individual parquet files to nodes parquet ----------------------

  .assemble_nodes(output, con = con, verbose = verbose)
  .osb_mark_done(output, "nodes")

  # Cleanup intermediate directories --------------------------------------
  #
  # `cleanup = FALSE` when called from pro_snowball(), which defers this
  # until after edge extraction: these directories are what a resume needs,
  # and removing them here meant an edges-stage crash destroyed them.
  if (isTRUE(cleanup)) .osb_clean_intermediates(output)

  # Return path to nodes ------------------------------------------------

  return(normalizePath(file.path(output, "nodes")))
}
