# DuckDB connection configuration.
#
# Until 0.15.0 both connections in this package were bare
# `dbConnect(duckdb::duckdb())`, so every DuckDB default applied:
#
#   memory_limit              ~80% of system RAM
#   threads                   all cores
#   preserve_insertion_order  true
#   temp_directory            `.tmp`, RELATIVE TO THE WORKING DIRECTORY
#
# Two of those are actively wrong here. The memory limit assumes the process
# owns the machine, which is false whenever several pro_snowball() calls run
# from a worker pool -- three concurrent callers on a 36 GB box promise 86 GB.
# And a working-directory-relative spill path is shared by all of them, which
# is the colliding-spill-file corruption openalexSnapshot documents in
# build_citation_index().

`%||%` <- function(x, y) if (is.null(x)) y else x

#' Configuration for the DuckDB connections used by a snowball
#'
#' `pro_snowball()` opens DuckDB twice -- once to assemble `nodes/`, once to
#' extract `edges/`. This builds the settings applied to both.
#'
#' @param memory_limit DuckDB `memory_limit`. `"auto"` (the default) derives a
#'   budget from physical RAM and `concurrency`; `NULL` leaves DuckDB's own
#'   default of ~80% of RAM; anything else is passed through (e.g. `"8GB"`).
#' @param temp_directory Root for DuckDB's spill files. `"auto"` (the default)
#'   uses a private directory under [tempdir()]. A path you supply is treated
#'   as a **root**: a `<pid>-<output hash>/<stage>` leaf is always appended, so
#'   setting one path for a whole worker pool stays safe. `NULL` leaves
#'   DuckDB's `.tmp`, which concurrent callers share -- not recommended.
#' @param threads `SET threads`. `"auto"` divides the available cores by
#'   `concurrency`; `NULL` leaves DuckDB's default.
#' @param preserve_insertion_order Defaults to `FALSE`. Row order on disk is
#'   not part of this package's contract -- [read_snowball()] sorts nodes by
#'   `(desc(oa_input), id)` and edges by `(from, to)` -- and preserving it
#'   makes the partitioned writes buffer.
#' @param partitioned_write_max_open_files `NULL` (default) leaves DuckDB's
#'   100. Do not raise it here: `nodes/` and `edges/` have three partitions
#'   each, so 100 is already ~33x what is needed, and each open file carries a
#'   write buffer. (openalexSnapshot raises it to 512, but that write fans out
#'   over hundreds of partitions.)
#' @param max_temp_directory_size `NULL` (default) leaves DuckDB's 90% of free
#'   disk.
#' @param concurrency How many `pro_snowball()` calls you intend to run at the
#'   same time. Used to divide the memory and thread budgets. There is no
#'   portable way to detect sibling R processes, so this is declared rather
#'   than discovered -- set it once for a worker pool:
#'   `options(openalexSnowball.duckdb_config = list(concurrency = 4))`.
#'
#' @return A list of class `openalexSnowball_duckdb_config`.
#'
#' @details
#' Settings resolve **per field**, not per object: an explicit argument field
#' beats the same field of `getOption("openalexSnowball.duckdb_config")`,
#' which beats the package default. So setting one field in the option does
#' not silently discard the safe defaults for the others, and passing
#' `duckdb_config = list(threads = 2)` at a call site does not discard a
#' session-wide memory budget.
#'
#' Note that `memory_limit` is a fairness and blast-radius control rather than
#' a correctness one: lowering it does not make a query fit, it makes a
#' failure arrive sooner and stops one run from starving the others.
#'
#' @examples
#' snowball_duckdb_config(memory_limit = "8GB", concurrency = 4)
#'
#' @md
#' @export
snowball_duckdb_config <- function(
  memory_limit = "auto",
  temp_directory = "auto",
  threads = "auto",
  preserve_insertion_order = FALSE,
  partitioned_write_max_open_files = NULL,
  max_temp_directory_size = NULL,
  concurrency = 1L
) {
  cfg <- list(
    memory_limit = memory_limit,
    temp_directory = temp_directory,
    threads = threads,
    preserve_insertion_order = preserve_insertion_order,
    partitioned_write_max_open_files = partitioned_write_max_open_files,
    max_temp_directory_size = max_temp_directory_size,
    concurrency = concurrency
  )
  structure(.osb_validate_duckdb_config(cfg),
            class = "openalexSnowball_duckdb_config")
}

#' Valid configuration field names
#' @noRd
.osb_duckdb_fields <- c(
  "memory_limit", "temp_directory", "threads", "preserve_insertion_order",
  "partitioned_write_max_open_files", "max_temp_directory_size", "concurrency"
)

#' Validate a configuration list
#'
#' Unknown names are an error rather than a warning: a typo'd `memory_limit`
#' that silently did nothing would reproduce the very failure this exists to
#' prevent.
#'
#' @noRd
.osb_validate_duckdb_config <- function(cfg) {
  if (!is.list(cfg)) {
    stop("`duckdb_config` must be a list or a snowball_duckdb_config().",
         call. = FALSE)
  }
  unknown <- setdiff(names(cfg), .osb_duckdb_fields)
  if (length(unknown) > 0L) {
    stop("Unknown `duckdb_config` field(s): ", paste(unknown, collapse = ", "),
         ".\nValid fields: ", paste(.osb_duckdb_fields, collapse = ", "),
         call. = FALSE)
  }
  if (!is.null(cfg$concurrency)) {
    n <- cfg$concurrency
    if (length(n) != 1L || is.na(n) || !is.numeric(n) || n < 1) {
      stop("`concurrency` must be a single number >= 1.", call. = FALSE)
    }
  }
  cfg
}

#' Package defaults
#' @noRd
.osb_duckdb_defaults <- function() {
  list(
    memory_limit = "auto",
    temp_directory = "auto",
    threads = "auto",
    preserve_insertion_order = FALSE,
    partitioned_write_max_open_files = NULL,
    max_temp_directory_size = NULL,
    concurrency = 1L
  )
}

#' Resolve the effective configuration
#'
#' @param config A list, a [snowball_duckdb_config()], or `NULL`.
#' @return A complete configuration list.
#' @noRd
.osb_resolve_duckdb_config <- function(config = NULL) {
  out <- .osb_duckdb_defaults()
  for (src in list(getOption("openalexSnowball.duckdb_config"), config)) {
    if (is.null(src)) next
    src <- .osb_validate_duckdb_config(src)
    # Assign through list() so an explicit NULL overrides rather than deletes:
    # utils::modifyList() would drop the element, collapsing "leave DuckDB's
    # default alone" into "not specified".
    for (nm in names(src)) out[nm] <- list(src[[nm]])
  }
  out
}

# -- byte helpers ------------------------------------------------------------

#' @noRd
.osb_parse_bytes <- function(x) {
  x <- trimws(as.character(x))
  m <- regmatches(x, regexec("^([0-9.]+)\\s*([KMGTP]?)i?B?$", x,
                             ignore.case = TRUE))[[1L]]
  if (length(m) != 3L) return(NA_real_)
  mult <- switch(toupper(m[[3L]]),
    "K" = 1024, "M" = 1024^2, "G" = 1024^3, "T" = 1024^4, "P" = 1024^5, 1
  )
  as.numeric(m[[2L]]) * mult
}

#' Total physical RAM in bytes
#'
#' Derived from DuckDB rather than platform calls: a bare connection's
#' `memory_limit` is 80% of physical RAM, so dividing by 0.8 recovers the
#' total without `sysctl` / `/proc/meminfo` / a new dependency. Cached.
#'
#' @return Bytes, or `NA_real_`.
#' @noRd
.osb_total_ram_bytes <- local({
  cached <- NULL
  function() {
    if (!is.null(cached)) return(cached)
    out <- tryCatch({
      con <- DBI::dbConnect(duckdb::duckdb())
      on.exit(DBI::dbDisconnect(con, shutdown = TRUE), add = TRUE)
      v <- DBI::dbGetQuery(con, "SELECT current_setting('memory_limit') AS v")$v[[1L]]
      .osb_parse_bytes(v) / 0.8
    }, error = function(e) NA_real_)
    if (!is.na(out)) cached <<- out
    out
  }
})

#' Derive the memory limit for one connection
#'
#' Half of physical RAM, divided by the declared concurrency, floored at 1 GB.
#' Deliberately below DuckDB's own 80%, which assumes sole tenancy.
#'
#' @return A memory-limit string, or `NULL` to emit no `SET`.
#' @noRd
.osb_auto_memory <- function(concurrency = 1L) {
  total <- .osb_total_ram_bytes()
  if (!is.finite(total)) return(NULL)
  bytes <- max(1024^3, total * 0.5 / max(1L, as.integer(concurrency)))
  sprintf("%.0fMB", bytes / 1024^2)
}

#' Derive the thread count for one connection
#' @noRd
.osb_auto_threads <- function(concurrency = 1L) {
  cores <- tryCatch(parallelly::availableCores(), error = function(e) NA_integer_)
  if (!is.finite(cores)) return(NULL)
  max(1L, as.integer(floor(cores / max(1L, as.integer(concurrency)))))
}

#' A private spill directory for one stage of one call
#'
#' `tempdir()` is per R process, so a `future::multisession` pool gives each
#' concurrent `pro_snowball()` a distinct root for free -- no lockfile, no
#' registry. R removes it at session exit, so abandoned spill from a crashed
#' run cannot accumulate; the failed 2137-seed run would otherwise have left
#' tens of GB in whatever directory the user had happened to `setwd()` to.
#'
#' Keyed on `output` as well as the pid so two sequential calls in one process
#' stay apart, and stable across a resumed run.
#'
#' @param root Root directory; `"auto"` uses `tempdir()`.
#' @param tag Stage name (`"nodes"`, `"edges"`, ...).
#' @param output The snowball output directory.
#' @noRd
.osb_temp_dir <- function(root, tag, output = NULL) {
  base <- if (identical(root, "auto") || is.null(root)) {
    file.path(tempdir(), "openalexSnowball")
  } else {
    root
  }
  key <- sprintf("%s-%s", Sys.getpid(),
                 substr(rlang::hash(output %||% "na"), 1L, 8L))
  file.path(base, key, gsub("[^A-Za-z0-9._-]", "_", tag))
}

#' Open a configured DuckDB connection
#'
#' @param cfg A resolved configuration (see [.osb_resolve_duckdb_config()]).
#' @param tag Stage name, used for the spill subdirectory.
#' @param output Snowball output directory, used to key the spill path.
#' @return A list with `con` and `temp_dir` (the latter `NULL` when DuckDB's
#'   default was left in place). The caller disconnects and unlinks.
#' @noRd
.osb_con <- function(cfg, tag = "main", output = NULL) {
  con <- DBI::dbConnect(duckdb::duckdb(), read_only = FALSE)

  set <- function(key, value) {
    DBI::dbExecute(con, paste0("SET ", key, " = ", value))
  }
  qstr <- function(x) paste0("'", gsub("'", "''", as.character(x)), "'")

  set("preserve_insertion_order",
      if (isTRUE(cfg$preserve_insertion_order)) "true" else "false")

  mem <- cfg$memory_limit
  if (identical(mem, "auto")) mem <- .osb_auto_memory(cfg$concurrency)
  if (!is.null(mem)) set("memory_limit", qstr(mem))

  thr <- cfg$threads
  if (identical(thr, "auto")) thr <- .osb_auto_threads(cfg$concurrency)
  if (!is.null(thr)) set("threads", as.integer(thr))

  temp_dir <- NULL
  if (!is.null(cfg$temp_directory)) {
    temp_dir <- .osb_temp_dir(cfg$temp_directory, tag, output)
    dir.create(temp_dir, recursive = TRUE, showWarnings = FALSE)
    set("temp_directory", qstr(temp_dir))
  }
  if (!is.null(cfg$max_temp_directory_size)) {
    set("max_temp_directory_size", qstr(cfg$max_temp_directory_size))
  }
  if (!is.null(cfg$partitioned_write_max_open_files)) {
    set("partitioned_write_max_open_files",
        as.integer(cfg$partitioned_write_max_open_files))
  }

  list(con = con, temp_dir = temp_dir)
}

#' Read the resolved keypaper ids from the keypaper parquet
#'
#' `ORDER BY id` is load-bearing, not tidiness. This vector is handed to
#' `pro_query(cites = ...)`, which joins the values into the filter string and
#' chunks them positionally -- so the scan order of `keypaper_parquet/`
#' determines the request URLs. DuckDB gives no ordering guarantee without an
#' explicit `ORDER BY`, and with `preserve_insertion_order = false` the order
#' becomes genuinely nondeterministic rather than merely undocumented, which
#' would make VCR cassette misses intermittent.
#'
#' Sorting makes the URLs a pure function of the *set* of keypapers,
#' independent of API return order, file layout, thread count and DuckDB
#' version -- which is what makes cassettes, and any HTTP caching, meaningful.
#'
#' @param con DuckDB connection.
#' @param kp_dir The `keypaper_parquet` directory.
#' @return Character vector of ids, sorted.
#' @noRd
.osb_keypaper_ids <- function(con, kp_dir) {
  sprintf(
    "SELECT id FROM read_parquet('%s/**/*.parquet') ORDER BY id",
    kp_dir
  ) |>
    DBI::dbGetQuery(conn = con) |>
    unlist() |>
    as.vector()
}
