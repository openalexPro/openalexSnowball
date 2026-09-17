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
#' Validate and normalise an OpenAlex API endpoint
#'
#' Trailing slashes are stripped so that `"https://host/"` and `"https://host"`
#' build identical URLs -- `pro_query()` appends `/works`, and a doubled slash
#' is not merely cosmetic: some reverse proxies treat `//works` as a different
#' route and return 404.
#'
#' @param endpoint Character scalar.
#' @return The normalised endpoint.
#' @noRd
.check_endpoint <- function(endpoint) {
  if (!is.character(endpoint) || length(endpoint) != 1L || is.na(endpoint) ||
      !nzchar(trimws(endpoint))) {
    stop("`endpoint` must be a single non-empty character string.", call. = FALSE)
  }
  sub("/+$", "", trimws(endpoint))
}

.nodes_from_api <- function(keypaper_ids, output, limit, verbose, workers = 1L,
                            chunk_limit = NULL,
                            endpoint = "https://api.openalex.org") {
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
                           chunk_limit = chunk_limit, endpoint = endpoint) |>
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
                           chunk_limit = chunk_limit, endpoint = endpoint) |>
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
#' Two passes, because one pass does not fit in memory. The node set is ~51
#' columns wide and several are nested and large (`abstract`,
#' `abstract_inverted_index` as `MAP(VARCHAR, BIGINT[])`, `authorships`,
#' `locations`, `topics`, `referenced_works`). Computing the role flags and
#' the de-duplication with window functions over that row -- which is what
#' 0.12.1 and 0.13.0 did -- pushes every wide row through four *blocking*
#' operators: DuckDB materialises a window's entire input before emitting a
#' row, and `SELECT * REPLACE` defeats projection pruning. A 2137-keypaper
#' run hit a 28.7 GiB memory limit there; the same shape streamed fine on
#' 0.12.0.
#'
#' So the collapse is *decided* on a narrow projection and only then applied:
#'
#' * **Pass 1** reads `(id, relation)` plus the synthetic `filename` /
#'   `file_row_number` and aggregates to one row per work: the three role
#'   flags, and the physical location of the row that wins the precedence
#'   order. Parquet projection pushdown means the nested columns are never
#'   decoded.
#' * **Pass 2** scans the wide data once per relation and inner-joins that
#'   narrow table on `(filename, file_row_number)`. A location identifies at
#'   most one row and each work contributes exactly one location, so the join
#'   is 1:1 -- one row per `id`, no fan-out. The wide columns only ever travel
#'   the probe side, streaming into the parquet writer.
#'
#' Three details are load-bearing rather than stylistic:
#'
#' * **Every statement uses the same `read_parquet()` specification.**
#'   `union_by_name = true` over *all* sources is what makes the three hive
#'   partitions share one schema; `read_corpus()` opens `nodes/` with
#'   `arrow::open_dataset()`, which infers the schema from the first fragment
#'   and would break on a partition that differed. Relations are therefore
#'   selected with `WHERE relation = ...`, never by narrowing the file list.
#'   It costs nothing -- each file is constant in `relation`, so the predicate
#'   prunes whole row groups on statistics -- and it also guarantees pass 1
#'   and pass 2 see identical `filename` values.
#' * **`hive_partitioning = false`.** `pro_query()` chunks the `openalex` id
#'   filter exactly as it chunks `cites`/`cited_by`, so above 50 keypapers all
#'   three `*_parquet` directories acquire `query=chunk_N/` levels and DuckDB
#'   materialises `query` as a column -- the written node schema would then
#'   depend on how many keypapers were supplied (57 columns at two seeds, 58
#'   at 2137). Disabled, so it does not.
#' * **No `PARTITION_BY`.** The partitioned writer buffers up to
#'   `partitioned_write_flush_threshold` (524288) rows per thread with no byte
#'   cap, which for rows this wide is gigabytes on its own -- a second OOM
#'   that would have survived fixing the windows. Writing each partition
#'   directory explicitly produces the identical layout with a plain
#'   streaming writer.
#'
#' @param output Snowball output directory.
#' @param con A DuckDB connection.
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
  sources_sql <- paste(sprintf("'%s'", sources), collapse = ",\n             ")

  # The single scan specification shared by the probe and both passes.
  read_all <- sprintf(
    "read_parquet(
             [%s],
             union_by_name     = true,
             hive_partitioning = false,
             filename          = true,
             file_row_number   = true
           )",
    sources_sql
  )

  # referenced_works is a native list in API output but a JSON string in the
  # legacy snapshot corpus. inst/extract_edges.sql uses UNLIST(), which needs a
  # list, so normalise here rather than templating the SQL: one expression
  # evaluated over thousands of node rows, and extract_edges.sql stays a
  # static, readable artifact.
  probe <- DBI::dbGetQuery(con, sprintf(
    "SELECT column_type
       FROM (DESCRIBE SELECT referenced_works FROM %s LIMIT 0)", read_all
  ))$column_type[[1L]]

  replace_refs <- if (grepl("\\[\\]$", probe)) {
    ""
  } else {
    ", json_extract_string(referenced_works, '$[*]') AS referenced_works"
  }

  on.exit(
    try(DBI::dbExecute(con, "DROP TABLE IF EXISTS snowball_node_winners"),
        silent = TRUE),
    add = TRUE
  )

  # -- Pass 1: one row per work, decided on four narrow columns --------------
  #
  # A work can hold more than one role at once, so the roles are recorded as
  # booleans over every source row, BEFORE the collapse. They are the honest
  # answer; `relation` keeps only the highest-precedence role and is lossy by
  # construction (kept because it is the hive partition key).
  #
  # Duplicates arise in two independent ways, both handled here:
  #   * ACROSS relations, on both paths -- a keypaper that also cites a
  #     keypaper. Resolved by the precedence rank, mirroring
  #     openalexR::oa_snowball()'s nodes[!duplicated(nodes$id), ] over
  #     list(paper, citing, cited).
  #   * WITHIN a relation, on the API path only -- pro_query() chunks
  #     cites/cited_by at chunk_limit ids into separate URLs, so a work citing
  #     keypapers in two chunks is written into two query=chunk_N directories.
  #     Resolved by the (filename, file_row_number) tie-break.
  #
  # min() over a STRUCT compares field by field in declaration order, so this
  # one aggregate is exactly `ORDER BY p, filename, file_row_number LIMIT 1`.
  # It replaces all four window functions, and unlike the old QUALIFY -- whose
  # ORDER BY ranked only the relation -- the tie-break is total, so the result
  # is deterministic rather than whatever order the sort happened to produce.
  DBI::dbExecute(con, sprintf(
    "CREATE OR REPLACE TEMP TABLE snowball_node_winners AS
     SELECT id, is_keypaper, is_citing, is_cited,
            win.f AS win_file, win.r AS win_row
     FROM (
       SELECT
         id,
         bool_or(relation = 'keypaper') AS is_keypaper,
         bool_or(relation = 'citing')   AS is_citing,
         bool_or(relation = 'cited')    AS is_cited,
         min(struct_pack(
           p := CASE relation
                  WHEN 'keypaper' THEN 1
                  WHEN 'citing'   THEN 2
                  ELSE                 3
                END,
           f := filename,
           r := file_row_number
         )) AS win
       FROM %s
       GROUP BY id
     )", read_all
  ))

  # -- Pass 2: one streaming COPY per relation -------------------------------
  #
  # Expressed on the flags rather than on a stored winning relation, so the
  # predicates stay correct when a relation was never collected (limit =
  # "onlyCiting" / "onlyCited", or a snapshot that returned nothing for one).
  winner_cond <- c(
    keypaper = "is_keypaper",
    citing   = "NOT is_keypaper AND is_citing",
    cited    = "NOT is_keypaper AND NOT is_citing"
  )

  nodes_dir <- file.path(output, "nodes")
  # Build into a sidecar and rename. A same-filesystem directory rename is
  # atomic, which makes assembly idempotent (a re-run cannot append into an
  # existing nodes/ and re-create the duplicate ids 0.12.1 removed) and means
  # a killed process leaves .nodes.building, never a half-populated nodes/.
  building <- file.path(output, ".nodes.building")
  unlink(building, recursive = TRUE, force = TRUE)

  for (rel in rels) {
    # DuckDB writes no empty partition, and ?read_snowball documents that a
    # relation partition can legitimately be absent once works are promoted by
    # precedence; count first so that stays true.
    n_rel <- DBI::dbGetQuery(con, sprintf(
      "SELECT count(*) AS n FROM snowball_node_winners WHERE %s",
      winner_cond[[rel]]
    ))$n[[1L]]
    if (n_rel == 0L) {
      if (verbose) message("No works survive as relation = '", rel, "'.")
      next
    }

    part_dir <- file.path(building, paste0("relation=", rel))
    dir.create(part_dir, recursive = TRUE, showWarnings = FALSE)

    # The join key is a physical row address, so the build side carries no id
    # and no payload beyond three booleans. Filtering the winners inside the
    # subquery keeps its estimated cardinality below the scan's, so the
    # optimiser builds the hash table on the narrow side -- check with EXPLAIN
    # if this is ever edited.
    DBI::dbExecute(con, sprintf(
      "COPY (
         SELECT n.* EXCLUDE (relation, filename, file_row_number)
                    REPLACE (CAST(oa_input AS BOOLEAN) AS oa_input%s),
                w.is_keypaper, w.is_citing, w.is_cited
         FROM %s n
         JOIN (
           SELECT win_file, win_row, is_keypaper, is_citing, is_cited
           FROM snowball_node_winners
           WHERE %s
         ) w
           ON n.filename = w.win_file
          AND n.file_row_number = w.win_row
         WHERE n.relation = '%s'
       ) TO '%s' (FORMAT PARQUET, COMPRESSION SNAPPY)",
      replace_refs, read_all, winner_cond[[rel]], rel,
      file.path(part_dir, "data_0.parquet")
    ))

    if (verbose) message("Wrote ", n_rel, " nodes to relation = '", rel, "'.")
  }

  unlink(nodes_dir, recursive = TRUE, force = TRUE)
  if (!file.rename(building, nodes_dir)) {
    stop("Could not move assembled nodes into place: ", nodes_dir,
         call. = FALSE)
  }

  normalizePath(nodes_dir)
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
