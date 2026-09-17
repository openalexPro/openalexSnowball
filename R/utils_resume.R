# Resume support.
#
# A 2137-keypaper run OOMed in the final assembly after 5.7 hours of API
# fetching. The fetched data was not destroyed by the failure -- the cleanup
# unlink()s run *after* assembly, so every intermediate directory was still on
# disk -- but `output` defaults to tempfile(), which lives under tempdir() and
# is removed when the R session ends. The work was recoverable and was lost
# anyway.
#
# So the machinery here is small on purpose: the checkpoint already exists.
# What was missing was (a) not destroying it on restart, (b) knowing which
# stages had finished, and (c) telling the user where it is.

#' Stage-completion marker directory
#' @noRd
.osb_done_dir <- function(output) file.path(output, ".osb_done")

#' Has a stage completed?
#'
#' Directory existence is not a completion signal: a partitioned COPY creates
#' its directory on the first file, and `pro_request()` creates a leaf
#' directory before fetching page one. An explicit marker, written only on
#' success, is the only honest answer -- the same reason
#' `openalexSnapshot::build_citation_index()` uses `.done` markers.
#'
#' @noRd
.osb_stage_done <- function(output, stage) {
  file.exists(file.path(.osb_done_dir(output), stage))
}

#' Record a stage as complete
#' @noRd
.osb_mark_done <- function(output, stage) {
  d <- .osb_done_dir(output)
  dir.create(d, recursive = TRUE, showWarnings = FALSE)
  file.create(file.path(d, stage))
  invisible(TRUE)
}

#' Path of the run manifest
#' @noRd
.osb_manifest_path <- function(output) file.path(output, "_snowball_run.parquet")

#' The parameters that define *which* snowball this is
#'
#' Deliberately not everything: `verbose`, `workers` and `duckdb_config` do
#' not change the result, and "resume with fewer workers and a smaller memory
#' limit" is the single most likely reason anyone resumes at all.
#'
#' @noRd
.osb_run_params <- function(identifier, doi, snapshot, limit, endpoint,
                            max_results, select) {
  seeds <- sort(unique(as.character(c(identifier, doi))))
  data.frame(
    seed_hash   = rlang::hash(seeds),
    n_seeds     = length(seeds),
    mode        = if (is.null(snapshot)) "api" else "snapshot",
    snapshot    = if (is.null(snapshot)) NA_character_ else as.character(snapshot),
    limit       = as.character(limit %||% "none"),
    endpoint    = as.character(endpoint),
    max_results = as.numeric(max_results %||% NA_real_),
    select      = paste(select %||% character(0), collapse = ","),
    pkg_version = as.character(utils::packageVersion("openalexSnowball")),
    stringsAsFactors = FALSE
  )
}

#' Write the run manifest
#' @noRd
.osb_write_manifest <- function(output, params) {
  dir.create(output, recursive = TRUE, showWarnings = FALSE)
  path <- .osb_manifest_path(output)
  # Write beside the target and rename: atomic, and it avoids touching a file
  # another handle may still hold open (see the mmap note in
  # .osb_check_manifest()).
  tmp <- paste0(path, ".tmp")
  arrow::write_parquet(params, tmp)
  if (!file.rename(tmp, path)) {
    unlink(tmp, force = TRUE)
    stop("Could not write the run manifest: ", path, call. = FALSE)
  }
  invisible(path)
}

#' Check a resumed run against the manifest of the interrupted one
#'
#' Any data-affecting difference is a hard error naming the field. This is the
#' most important safety property of `resume`: continuing with a different
#' keypaper set, `limit` or `snapshot` would splice two different snowballs
#' into one output, and the result would be silently, unrecoverably wrong.
#'
#' @noRd
.osb_check_manifest <- function(output, params) {
  path <- .osb_manifest_path(output)
  if (!file.exists(path)) {
    stop("`", output, "` exists but was not produced by a resumable run ",
         "(no _snowball_run.parquet).\n",
         "Delete it, or call with `resume = FALSE` to overwrite it.",
         call. = FALSE)
  }
  # mmap = FALSE matters on Windows: arrow memory-maps the file by default,
  # and the mapping stays open long enough that rewriting the manifest a
  # moment later fails with "[Windows error 1224] The requested operation
  # cannot be performed on a file with a user-mapped section open."
  old <- as.data.frame(arrow::read_parquet(path, mmap = FALSE))
  cmp <- c("seed_hash", "mode", "snapshot", "limit", "endpoint",
           "max_results", "select")
  diffs <- character(0)
  for (f in cmp) {
    a <- old[[f]]
    b <- params[[f]]
    same <- (is.na(a) && is.na(b)) || isTRUE(a == b)
    if (!same) {
      diffs <- c(diffs, sprintf("  %s: was %s, now %s", f,
                                format(a), format(b)))
    }
  }
  if (length(diffs) > 0L) {
    stop("Cannot resume: this call does not describe the same snowball as ",
         "the one in `", output, "`.\n",
         paste(diffs, collapse = "\n"),
         "\nResuming would merge two different snowballs into one output.",
         call. = FALSE)
  }
  invisible(TRUE)
}

#' Is `output` inside the session's temporary directory?
#'
#' Worth saying out loud on failure: it is exactly what turned a recoverable
#' crash into six lost hours.
#'
#' @noRd
.osb_is_temp <- function(output) {
  td <- normalizePath(tempdir(), mustWork = FALSE)
  startsWith(normalizePath(output, mustWork = FALSE), td)
}

#' Re-throw an error with the information needed to resume
#'
#' @param output Snowball output directory.
#' @param stage Stage that was running.
#' @param e The original condition.
#' @noRd
.osb_rethrow_resumable <- function(output, stage, e) {
  done <- list.files(.osb_done_dir(output))
  msg <- paste0(
    "Snowball failed during stage '", stage, "'.\n\n",
    "  Intermediate results are preserved at:\n    ", output, "\n",
    if (length(done)) {
      paste0("  Completed stages: ", paste(sort(done), collapse = ", "), "\n")
    } else {
      ""
    },
    "\n  Resume with:\n",
    "    pro_snowball(..., output = \"", output, "\", resume = TRUE)\n",
    if (.osb_is_temp(output)) {
      paste0(
        "\n  WARNING: that path is under tempdir() and will be DELETED when\n",
        "  this R session ends. Copy it elsewhere now, or re-run with an\n",
        "  explicit `output =` on a persistent disk.\n"
      )
    } else {
      ""
    },
    "\n  Caused by: ", conditionMessage(e)
  )
  stop(msg, call. = FALSE)
}

#' Remove the intermediate fetch/convert directories
#'
#' @noRd
.osb_clean_intermediates <- function(output) {
  for (d in c("keypaper_json", "keypaper_parquet",
              "citing_json", "citing_parquet",
              "cited_json", "cited_parquet")) {
    unlink(file.path(output, d), recursive = TRUE)
  }
  invisible(TRUE)
}
