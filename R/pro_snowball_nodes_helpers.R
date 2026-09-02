# pro_snowball_nodes_helpers ---
# The node-gathering stage split into a source-agnostic assembly step and two
# interchangeable fetchers. Only the fetch differs between the API and the
# snapshot; everything downstream -- the union COPY, pro_snowball_extract_edges()
# and read_snowball() -- is already generic.

#' Fetch keypaper, citing and cited nodes from the OpenAlex API
#'
#' The original body of [pro_snowball_get_nodes()], unchanged in behaviour.
#'
#' @param keypaper_ids Long-form OpenAlex IDs.
#' @param output Snowball output directory.
#' @param limit One of `"none"`, `"onlyCiting"`, `"onlyCited"`.
#' @param verbose Print progress.
#' @return Invisibly `NULL`; writes `*_parquet` directories under `output`.
#' @noRd
.nodes_from_api <- function(keypaper_ids, output, limit, verbose) {
  if (limit != "onlyCited") {
    if (verbose) {
      message(
        "Collecting all documents citing the target keypapers (to = keypaper)..."
      )
    }
    openalexPro::pro_query(cites = keypaper_ids, entity = "works") |>
      openalexPro::pro_request(
        output = file.path(output, "citing_json"),
        verbose = verbose, progress = verbose
      ) |>
      openalexPro::pro_request_parquet(
        output = file.path(output, "citing_parquet"),
        add_columns = list(oa_input = "FALSE", relation = "citing"),
        verbose = verbose
      )
  }

  if (limit != "onlyCiting") {
    if (verbose) {
      message("Collecting all documents cited by the keypapers ...")
    }
    openalexPro::pro_query(cited_by = keypaper_ids, entity = "works") |>
      openalexPro::pro_request(
        output = file.path(output, "cited_json"),
        verbose = verbose, progress = verbose
      ) |>
      openalexPro::pro_request_parquet(
        output = file.path(output, "cited_parquet"),
        add_columns = list(oa_input = "FALSE", relation = "cited"),
        verbose = verbose
      )
  }
  invisible(NULL)
}

#' Fetch keypaper, citing and cited nodes from a local snapshot
#'
#' The offline counterpart of [.nodes_from_api()]. Two fidelity points are
#' deliberate, because the API path behaves this way and node counts must
#' match:
#'
#' * **No cross-relation de-duplication.** A work that both cites one keypaper
#'   and is cited by another legitimately appears in two `relation` partitions.
#' * **Keypapers are not excluded** from the citing/cited sets.
#'
#' @inheritParams .nodes_from_api
#' @param snapshot Path to the snapshot root or its `parquet/` directory.
#' @param max_results Passed to [openalexSnapshot::get_citing()].
#' @noRd
.nodes_from_snapshot <- function(keypaper_ids, snapshot, output, limit,
                                 verbose, max_results = 100000L) {
  fetch <- function(ids, rel) {
    if (length(ids) == 0L) return(invisible(NULL))
    openalexSnapshot::lookup_by_id(
      ids        = ids,
      root_dir   = snapshot,
      index_file = .snapshot_index(snapshot, "id"),
      backend    = "r",
      # String literals, matching openalexPro::pro_request_parquet(); the cast
      # to BOOLEAN happens once in .assemble_nodes(), shared with the API path.
      add_columns = list(
        oa_input = if (rel == "keypaper") "TRUE" else "FALSE",
        relation = rel
      ),
      output  = file.path(output, paste0(rel, "_parquet")),
      verbose = verbose
    )
    invisible(NULL)
  }

  # A keypaper that resolves but is absent from the corpus would silently
  # yield a snowball with no seed -- and edge classification would quietly
  # change, since core/extended depend on which endpoints are keypapers.
  found <- openalexSnapshot::lookup_by_id(
    ids = keypaper_ids, index_file = .snapshot_index(snapshot, "id"),
    backend = "r", columns = "id", verbose = FALSE
  )
  missing <- setdiff(keypaper_ids, found$id)
  if (length(missing) == length(keypaper_ids)) {
    stop("None of the keypapers are present in the snapshot: ",
         paste(utils::head(missing, 5L), collapse = ", "),
         if (length(missing) > 5L) paste0(", and ", length(missing) - 5L, " more") else "",
         call. = FALSE)
  }
  if (length(missing)) {
    warning(length(missing), " keypaper(s) are not present in the snapshot and ",
            "were dropped: ", paste(utils::head(missing, 5L), collapse = ", "),
            if (length(missing) > 5L) paste0(", and ", length(missing) - 5L, " more") else "",
            call. = FALSE)
    keypaper_ids <- found$id
  }

  fetch(keypaper_ids, "keypaper")

  if (limit != "onlyCited") {
    if (verbose) message("Collecting citing documents from the snapshot ...")
    ids <- openalexSnapshot::get_citing(
      keypaper_ids, root_dir = snapshot, return = "ids",
      max_results = max_results, verbose = verbose
    )
    fetch(ids, "citing")
  }

  if (limit != "onlyCiting") {
    if (verbose) message("Collecting cited documents from the snapshot ...")
    ids <- openalexSnapshot::get_cited(
      keypaper_ids, root_dir = snapshot, return = "ids",
      max_results = max_results, verbose = verbose
    )
    fetch(ids, "cited")
  }
  invisible(NULL)
}

#' Path to an index inside a snapshot
#' @noRd
.snapshot_index <- function(snapshot, kind = c("id", "doi")) {
  kind <- match.arg(kind)
  root <- if (dir.exists(file.path(snapshot, "parquet"))) {
    file.path(snapshot, "parquet")
  } else {
    snapshot
  }
  file.path(root, paste0("works_", kind, "_idx.parquet"))
}

#' Resolve keypapers against a snapshot, without touching the API
#' @noRd
.keypaper_ids_snapshot <- function(identifier, doi, snapshot, verbose) {
  kp <- if (!is.null(identifier)) identifier else doi
  openalexSnapshot:::.oas_resolve_keypaper(
    kp, root_dir = snapshot, verbose = verbose
  )
}

#' Union the per-relation parquet directories into the nodes dataset
#'
#' Source-agnostic: both fetchers write the same `<relation>_parquet`
#' directories, so this is shared.
#'
#' @param output Snowball output directory.
#' @param verbose Print progress.
#' @return Path to the nodes dataset.
#' @noRd
.assemble_nodes <- function(output, con, verbose = FALSE) {
  have <- function(rel) {
    d <- file.path(output, paste0(rel, "_parquet"))
    dir.exists(d) &&
      length(list.files(d, pattern = "\\.parquet$", recursive = TRUE)) > 0L
  }
  rels <- c("keypaper", "citing", "cited")
  rels <- rels[vapply(rels, have, logical(1))]
  if (length(rels) == 0L) {
    stop("No nodes were collected.", call. = FALSE)
  }

  sources <- file.path(output, paste0(rels, "_parquet"), "**", "*.parquet")
  sources_sql <- paste(sprintf("'%s'", sources), collapse = ",\n          ")

  # referenced_works is a native list in API output but a JSON string in the
  # legacy snapshot corpus. inst/extract_edges.sql uses UNLIST(), which needs a
  # list, so normalise here rather than templating the SQL: one expression
  # evaluated over thousands of node rows, and extract_edges.sql stays a
  # static, readable artifact.
  probe <- DBI::dbGetQuery(con, sprintf(
    "SELECT column_type FROM (DESCRIBE SELECT referenced_works
       FROM read_parquet([%s], union_by_name = true) LIMIT 0)", sources_sql
  ))$column_type[[1L]]

  replace_refs <- if (grepl("\\[\\]$", probe)) {
    ""
  } else {
    ", json_extract_string(referenced_works, '$[*]') AS referenced_works"
  }

  sprintf(
    "
      COPY (
        SELECT
          * REPLACE (CAST(oa_input AS BOOLEAN) AS oa_input%s)
        FROM
        read_parquet(
          [%s],
          union_by_name = true
        )
      ) TO
        '%s'
        (FORMAT PARQUET, COMPRESSION SNAPPY, APPEND, PARTITION_BY 'relation')
      ",
    replace_refs, sources_sql, file.path(output, "nodes")
  ) |>
    DBI::dbExecute(conn = con)

  normalizePath(file.path(output, "nodes"))
}
