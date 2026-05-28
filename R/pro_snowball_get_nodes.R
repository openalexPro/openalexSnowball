#' A function to get the nodes for a snowball search
#' @param identifier Character vector of openalex identifiers.
#' @param doi Character vector of dois.
#' @param limit If `citedOnly` only works cited by the keypaper are retrieved,
#'   `citingOnly` retrieves only works citing the keypaper. Default: `NULL`
#'   where all will be retrieved. 'none' is equal to `NULL`
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
  output = tempfile(fileext = ".snowball"),
  verbose = FALSE
) {
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

  if (dir.exists(output)) {
    if (verbose) {
      message(
        "Deleting and recreating `",
        output,
        "` to avoid inconsistencies."
      )
    }
    unlink(output, recursive = TRUE)
  }
  dir.create(output, recursive = TRUE)

  # Create and setup in memory DuckDB --------------------------------------

  con <- DBI::dbConnect(duckdb::duckdb())

  on.exit(
    try(DBI::dbDisconnect(con, shutdown = TRUE), silent = TRUE),
    add = TRUE
  )

  # fetching keypapers -----------------------------------------------------

  if (verbose) {
    message("Collecting keypapers...")
  }

  ifelse(
    !is.null(identifier),
    qu <- openalexPro::pro_query(
      id = identifier,
      entity = "works"
    ),
    qu <- openalexPro::pro_query(
      doi = doi,
      entity = "works"
    )
  )
  openalexPro::pro_request(
    query_url = qu,
    output = file.path(output, "keypaper_json"),
    verbose = verbose,
    progress = verbose
  ) |>
    openalexPro::pro_request_parquet(
      output = file.path(output, "keypaper_parquet"),
      add_columns = list(oa_input = "TRUE", relation = "keypaper"),
      verbose = verbose
    )

  # Getting keypaper ids as returned by OpenAlex ---------------------------

  keypaper_ids <- sprintf(
    "
    SELECT
      id
    FROM
      read_parquet( '%s/**/*.parquet' )
    ",
    file.path(output, "keypaper_parquet")
  ) |>
    DBI::dbGetQuery(conn = con) |>
    unlist() |>
    as.vector()

  # fetching documents citing the target keypapers (incoming - to: keypaper)
  # ----

  if (limit != "onlyCited") {
    if (verbose) {
      message(
        "Collecting all documents citing the target keypapers (to = keypaper)..."
      )
    }

    openalexPro::pro_query(
      cites = keypaper_ids,
      entity = "works"
    ) |>
      openalexPro::pro_request(
        output = file.path(output, "citing_json"),
        verbose = verbose,
        progress = verbose
      ) |>
      openalexPro::pro_request_parquet(
        output = file.path(output, "citing_parquet"),
        add_columns = list(oa_input = "FALSE", relation = "citing"),
        verbose = verbose
      )
  }

  # fetching documents cited by the keypapers (outgoing - from: keypaper)
  # ----

  if (limit != "onlyCiting") {
    if (verbose) {
      message(
        "Collecting all documents cited by the target keypapers ..."
      )
    }

    openalexPro::pro_query(
      cited_by = keypaper_ids,
      entity = "works"
    ) |>
      openalexPro::pro_request(
        output = file.path(output, "cited_json"),
        verbose = verbose,
        progress = verbose
      ) |>
      openalexPro::pro_request_parquet(
        output = file.path(output, "cited_parquet"),
        add_columns = list(oa_input = "FALSE", relation = "cited"),
        verbose = verbose
      )
  }

  # Combine individual parquet files to nodes parquet ----------------------

  parquet_sources <- c(file.path(output, "keypaper_parquet", "**", "*.parquet"))

  cited_parquet_dir <- file.path(output, "cited_parquet")
  if (
    dir.exists(cited_parquet_dir) &&
      length(list.files(
        cited_parquet_dir,
        pattern = "\\.parquet$",
        recursive = TRUE
      )) > 0
  ) {
    parquet_sources <- c(
      parquet_sources,
      file.path(output, "cited_parquet", "**", "*.parquet")
    )
  }

  citing_parquet_dir <- file.path(output, "citing_parquet")
  if (
    dir.exists(citing_parquet_dir) &&
      length(list.files(
        citing_parquet_dir,
        pattern = "\\.parquet$",
        recursive = TRUE
      )) > 0
  ) {
    parquet_sources <- c(
      parquet_sources,
      file.path(output, "citing_parquet", "**", "*.parquet")
    )
  }

  parquet_sources_sql <- paste(
    sprintf("'%s'", parquet_sources),
    collapse = ",\n          "
  )

  sprintf(
    "
      COPY (
        SELECT
          * REPLACE (CAST(oa_input AS BOOLEAN) AS oa_input)
        FROM
        read_parquet(
          [%s],
          union_by_name = true
        )
      ) TO
        '%s'
        (FORMAT PARQUET, COMPRESSION SNAPPY, APPEND, PARTITION_BY 'relation')
      ",
    parquet_sources_sql,
    file.path(output, "nodes")
  ) |>
    DBI::dbExecute(conn = con)

  # Cleanup intermediate directories --------------------------------------

  unlink(file.path(output, "keypaper_json"), recursive = TRUE)
  unlink(file.path(output, "keypaper_parquet"), recursive = TRUE)
  unlink(file.path(output, "citing_json"), recursive = TRUE)
  unlink(file.path(output, "citing_parquet"), recursive = TRUE)
  unlink(file.path(output, "cited_json"), recursive = TRUE)
  unlink(file.path(output, "cited_parquet"), recursive = TRUE)

  # Return path to nodes ------------------------------------------------

  return(normalizePath(file.path(output, "nodes")))
}
