# pro_snowball_nodes_helpers ---
# The node-gathering stage split into a source-agnostic assembly step and two
# interchangeable fetchers. Only the fetch differs between the API and the
# snapshot; everything downstream -- the union COPY, pro_snowball_extract_edges()
# and read_snowball() -- is already generic.

#' Normalise a worker count for the two conventions in the callees
#'
#' `openalexPro::pro_request()` takes `workers = 1` for sequential;
#' `pro_request_parquet()`, `openalexSnapshot::lookup_by_id()` and the
#' `get_*()` functions take `workers = NULL`. This keeps that mapping in one
#' place instead of repeating it at every call site.
#'
#' @param workers Positive integer.
#' @return `NULL` when `workers <= 1`, otherwise the integer.
#' @noRd
.par_workers <- function(workers) {
  if (is.null(workers) || workers <= 1L) NULL else as.integer(workers)
}

#' Validate the `workers` argument
#' @noRd
.check_workers <- function(workers) {
  if (length(workers) != 1L || is.na(workers) || !is.numeric(workers) ||
      workers < 1 || workers != as.integer(workers)) {
    stop("`workers` must be a single positive whole number.", call. = FALSE)
  }
  as.integer(workers)
}

#' Choose a chunk size for the API filter, given the worker count
#'
#' `openalexPro::pro_query()` splits a `cites`/`cited_by` filter into separate
#' URLs of `chunk_limit` ids each, and `pro_request()` fetches those URLs in
#' parallel. The two never agreed on a number: `pro_query()` has no knowledge of
#' `workers`, so with the 50-id default, 100 keypapers over 6 workers produce
#' two chunks and leave four workers idle.
#'
#' Chunks are split by id count while cost is driven by results, so one chunk
#' holding a heavily cited paper dominates and the rest finish early. Aiming
#' for ~2x as many chunks as workers gives the scheduler something to balance
#' with, rather than exactly one chunk each.
#'
#' The floor of 10 matters: every chunk pays its own initial request and cursor
#' setup, and the total page count is fixed by the result volume, so shrinking
#' chunks indefinitely adds overhead without removing work. Parallelism here is
#' also capped by the OpenAlex rate limit, not by cores.
#'
#' Note this cannot help the case that hurts most -- few keypapers with many
#' citers each is pagination-bound inside a single chunk, and cursor paging is
#' sequential by construction.
#'
#' @param n_ids Number of keypaper ids being filtered on.
#' @param workers Worker count.
#' @param override Explicit `chunk_limit`, or `NULL` to derive one.
#' @return An integer chunk size.
#' @noRd
.chunk_limit_for <- function(n_ids, workers, override = NULL) {
  if (!is.null(override)) return(as.integer(override))
  if (is.null(workers) || workers <= 1L) return(50L)   # unchanged default
  max(10L, min(50L, as.integer(ceiling(n_ids / (2L * workers)))))
}

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
.nodes_from_api <- function(keypaper_ids, output, limit, verbose, workers = 1L,
                            chunk_limit = NULL) {
  chunk_limit <- .chunk_limit_for(length(keypaper_ids), workers, chunk_limit)
  if (verbose && workers > 1L) {
    message("Using chunk_limit = ", chunk_limit, " for ", workers, " workers (",
            ceiling(length(keypaper_ids) / chunk_limit), " chunk URLs)")
  }
  if (limit != "onlyCited") {
    if (verbose) {
      message(
        "Collecting all documents citing the target keypapers (to = keypaper)..."
      )
    }
    openalexPro::pro_query(cites = keypaper_ids, entity = "works",
                           chunk_limit = chunk_limit) |>
      openalexPro::pro_request(
        output = file.path(output, "citing_json"),
        workers = workers,
        verbose = verbose, progress = verbose
      ) |>
      openalexPro::pro_request_parquet(
        output = file.path(output, "citing_parquet"),
        add_columns = list(oa_input = "FALSE", relation = "citing"),
        workers = .par_workers(workers),
        verbose = verbose
      )
  }

  if (limit != "onlyCiting") {
    if (verbose) {
      message("Collecting all documents cited by the keypapers ...")
    }
    openalexPro::pro_query(cited_by = keypaper_ids, entity = "works",
                           chunk_limit = chunk_limit) |>
      openalexPro::pro_request(
        output = file.path(output, "cited_json"),
        workers = workers,
        verbose = verbose, progress = verbose
      ) |>
      openalexPro::pro_request_parquet(
        output = file.path(output, "cited_parquet"),
        add_columns = list(oa_input = "FALSE", relation = "cited"),
        workers = .par_workers(workers),
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
                                 verbose, max_results = 100000L,
                                 workers = 1L, select = NULL) {
  # `referenced_works` is what the edge extraction unnests, and id/oa_input/
  # relation carry the structure, so any projection must retain them.
  if (!is.null(select)) {
    select <- unique(c("id", "referenced_works", select))
  }
  fetch <- function(ids, rel) {
    if (length(ids) == 0L) return(invisible(NULL))
    openalexSnapshot::lookup_by_id(
      ids        = ids,
      root_dir   = snapshot,
      index_file = .snapshot_index(snapshot, "id"),
      backend    = "r",
      columns    = select,
      # String literals, matching openalexPro::pro_request_parquet(); the cast
      # to BOOLEAN happens once in .assemble_nodes(), shared with the API path.
      add_columns = list(
        oa_input = if (rel == "keypaper") "TRUE" else "FALSE",
        relation = rel
      ),
      output  = file.path(output, paste0(rel, "_parquet")),
      workers = .par_workers(workers),
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
      max_results = max_results, workers = .par_workers(workers),
      verbose = verbose
    )
    fetch(ids, "citing")
  }

  if (limit != "onlyCiting") {
    if (verbose) message("Collecting cited documents from the snapshot ...")
    ids <- openalexSnapshot::get_cited(
      keypaper_ids, root_dir = snapshot, return = "ids",
      max_results = max_results, workers = .par_workers(workers),
      verbose = verbose
    )
    fetch(ids, "cited")
  }
  invisible(NULL)
}

#' Path to an index inside a snapshot
#'
#' The layouts differ by index: `works_id_idx/` is a hive-partitioned
#' directory, while `works_doi_idx.parquet` is still a single sorted file.
#' @noRd
.snapshot_index <- function(snapshot, kind = c("id", "doi")) {
  kind <- match.arg(kind)
  root <- if (dir.exists(file.path(snapshot, "parquet"))) {
    file.path(snapshot, "parquet")
  } else {
    snapshot
  }
  switch(kind,
    id  = file.path(root, "works_id_idx"),
    doi = file.path(root, "works_doi_idx.parquet")
  )
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

  # One row per work, keypaper winning over citing winning over cited.
  #
  # This mirrors openalexR::oa_snowball(), which does
  # `nodes[!duplicated(nodes$id), ]` over `list(paper, citing, cited)` -- first
  # occurrence wins, in that order. Without it the node set duplicates in two
  # independent ways:
  #
  #   * ACROSS relations, on both paths. A keypaper that also cites another
  #     keypaper appears twice, once with oa_input TRUE and once FALSE -- the
  #     same work carrying contradictory metadata, and any join on id fans out.
  #     Measured at 75 duplicated ids in a clustered 40-keypaper snowball.
  #
  #   * WITHIN a relation, on the API path only. pro_query() chunks cites and
  #     cited_by at 50 ids into separate URLs, fetched and converted
  #     independently; a work citing keypapers in two chunks is written twice.
  #     Measured at 1.09x on `cited` for 60 keypapers. The snapshot path is
  #     immune because get_citing()/get_cited() return unique ids.
  #
  # A plain DISTINCT would not do it: the duplicate rows differ in `relation`
  # and `oa_input`, so both would survive.
  #
  # Collapsing to one row per work would lose the fact that a work can hold
  # more than one relation at once, so the three roles are recorded as
  # booleans BEFORE the collapse. `bool_or(...) OVER (PARTITION BY id)` sees
  # every row for that work; the QUALIFY then keeps one of them.
  #
  # `relation` is retained as the precedence winner, so it stays a usable hive
  # partition key and existing code keeps working -- but it is lossy by
  # construction, and `is_keypaper` / `is_citing` / `is_cited` are the honest
  # answer. A work that both cites a keypaper and is cited by one reports
  # relation = "citing" and is_citing = is_cited = TRUE.
  #
  # Note `relation` is an openalexSnowball column: openalexR's nodes carry only
  # `oa_input`. The precedence order matches its dedup order all the same, so
  # the surviving row is the one openalexR would have kept.
  sprintf(
    "
      COPY (
        SELECT
          * REPLACE (CAST(oa_input AS BOOLEAN) AS oa_input%s),
          bool_or(relation = 'keypaper') OVER (PARTITION BY id) AS is_keypaper,
          bool_or(relation = 'citing')   OVER (PARTITION BY id) AS is_citing,
          bool_or(relation = 'cited')    OVER (PARTITION BY id) AS is_cited
        FROM
        read_parquet(
          [%s],
          union_by_name = true
        )
        QUALIFY row_number() OVER (
          PARTITION BY id
          ORDER BY CASE relation
                     WHEN 'keypaper' THEN 1
                     WHEN 'citing'   THEN 2
                     ELSE                 3
                   END
        ) = 1
      ) TO
        '%s'
        (FORMAT PARQUET, COMPRESSION SNAPPY, APPEND, PARTITION_BY 'relation')
      ",
    replace_refs, sources_sql, file.path(output, "nodes")
  ) |>
    DBI::dbExecute(conn = con)

  normalizePath(file.path(output, "nodes"))
}

#' Record how a snowball was produced
#'
#' Without this an offline snowball is indistinguishable from an online one on
#' disk, and the snapshot vintage its results are frozen at is invisible. That
#' is a reproducibility problem rather than a nicety: a review built from
#' offline results should be able to state which snapshot it used.
#'
#' @param output Snowball output directory.
#' @param mode `"api"` or `"snapshot"`.
#' @param snapshot Snapshot path, or `NULL`.
#' @param keypapers Resolved keypaper ids.
#' @param limit The `limit` in force.
#' @noRd
.write_snowball_meta <- function(output, mode, snapshot, keypapers, limit) {
  built_at <- NA_character_
  if (!is.null(snapshot)) {
    meta_file <- file.path(
      if (dir.exists(file.path(snapshot, "parquet"))) {
        file.path(snapshot, "parquet")
      } else {
        snapshot
      },
      "works_cite_idx", "_index_meta.parquet"
    )
    if (file.exists(meta_file)) {
      built_at <- as.character(
        as.data.frame(arrow::read_parquet(meta_file))$built_at[[1L]]
      )
    }
  }

  arrow::write_parquet(
    data.frame(
      mode              = mode,
      snapshot_root     = if (is.null(snapshot)) NA_character_ else snapshot,
      snapshot_built_at = built_at,
      keypapers         = paste(keypapers, collapse = ","),
      limit             = limit,
      created_at        = as.character(Sys.time()),
      openalexSnowball  = as.character(utils::packageVersion("openalexSnowball")),
      openalexPro       = as.character(utils::packageVersion("openalexPro")),
      stringsAsFactors  = FALSE
    ),
    file.path(output, "snowball_meta.parquet")
  )
  invisible(NULL)
}
