#' Read snowball from Parquet Dataset
#'
#' This function reads a snowball from Apache Parquet format and returns a list
#' containing nodes and edges, which can be either Arrow Datasets or `tibble`s.
#'
#' @param snowball The directory of the Parquet files as poppulater by
#'   `pro_snowball()`.
#' @param edge_type type of the returned edges. Possible values are:
#' - **`core`**: only edges from or to the keypapers are selected
#' - **`extended`**, only edges between the `nodes` are selected
#'     (this includes `core` edges)
#' - **`outside`**: only  edges where either the `from` or the `to`
#'     is not in `nodes`
#' multiple are allowed.
#' @param return_data Logical indicating whether to return an `ArrowObject`
#'   representing the corpus (default) or a `tibble` containing the whole corpus
#'   shou,d be returned.
#' @param meta Also return provenance as a third list element `meta`: how the
#'   snowball was produced (`api` or `snapshot`), the snapshot path and the
#'   vintage of the citation index it was built from, the resolved keypapers,
#'   and package versions. Defaults to `FALSE`, which keeps the return shape
#'   `list(nodes, edges)`. The sidecar is written to disk either way.
#' @param shorten_ids If `TRUE` the ids will be shortened, i.e. the part
#'   `https://openalex.org/` will be removed
#'
#' @return A list containing two elements: nodes and edges, which are either
#'   `ArrowObject` representing the corpus or `tibble`s containing the data
#'   (plus `meta` when `meta = TRUE`).
#'
#'   `nodes` has one row per OpenAlex work -- `id` is a key -- and carries the
#'   role columns described below.
#'
#' @section Node roles:
#'
#' A work can hold more than one role in the same snowball: a keypaper that
#' cites another keypaper is both a keypaper and a citing work, and a work can
#' both cite one keypaper and be cited by another. Because `id` is a key, those
#' roles cannot each get their own row, so they are three independent flags on
#' the single row:
#'
#' * `is_keypaper` -- the work is one of the supplied keypapers.
#' * `is_citing` -- the work cites at least one keypaper.
#' * `is_cited` -- the work is cited by at least one keypaper.
#'
#' Any combination can be `TRUE`, and at least one always is. Filter on these:
#'
#' ```r
#' sb <- read_snowball(path, return_data = TRUE)
#'
#' subset(sb$nodes, is_citing)              # everything citing a keypaper
#' subset(sb$nodes, is_citing & is_cited)   # works in both directions
#' subset(sb$nodes, !is_keypaper)           # the snowballed neighbourhood
#' ```
#'
#' `relation` is also present and is the hive partition key of `nodes/`, but it
#' records only the **highest-precedence** role (`keypaper` > `citing` >
#' `cited`). A work that is both citing and cited reports
#' `relation = "citing"`, so `relation == "cited"` does **not** find every
#' cited work -- `is_cited` does. Use `relation` for partition pruning and the
#' booleans for filtering.
#'
#' The flags describe a work's role *in this snowball*, not a property of the
#' work: the same paper can be `is_cited` in one snowball and `is_citing` in
#' another.
#'
#' @md
#'
#' @importFrom dplyr filter select collect arrange desc
#' @importFrom rlang .env .data
#'
#' @export
read_snowball <- function(
  snowball = NULL,
  edge_type = c("core", "extended", "outside"),
  return_data = FALSE,
  shorten_ids = FALSE,
  meta = FALSE
) {
  if (is.null(snowball)) {
    stop("Directory `snowball` missing!")
  }

  if (!dir.exists(snowball)) {
    stop("Directory `snowball` does not exist!")
  }

  edge_type <- match.arg(edge_type, several.ok = TRUE)

  # Nodes ------------------------------------------------------------------

  nodes <- openalexPro::read_corpus(
    corpus = file.path(snowball, "nodes"),
    return_data = FALSE
  ) |>
    dplyr::arrange(
      dplyr::desc(oa_input),
      id
    )

  if (shorten_ids) {
    nodes <- nodes |>
      dplyr::mutate(
        id = gsub("^https://openalex.org/", "", id)
      )
  }

  # Edges ------------------------------------------------------------------

  edges <- openalexPro::read_corpus(
    corpus = file.path(snowball, "edges"),
    return_data = FALSE
  ) |>
    dplyr::filter(
      edge_type %in% .env$edge_type
    ) |>
    dplyr::arrange(
      from,
      to
    )

  if (shorten_ids) {
    edges <- edges |>
      dplyr::mutate(
        from = gsub("^https://openalex.org/", "", from),
        to = gsub("^https://openalex.org/", "", to)
      )
  }

  # Collect or not ---------------------------------------------------------

  if (return_data) {
    nodes <- dplyr::collect(nodes)
    edges <- dplyr::collect(edges)
  }

  # Return -----------------------------------------------------------------

  result <- list(
    nodes = nodes,
    edges = edges
  )

  # Provenance is opt-in. It carries a wall-clock `created_at`, so including it
  # by default would make any snapshot test of the returned object unstable --
  # and would change the return shape for existing callers. The sidecar is
  # always written to disk regardless, so nothing is lost by defaulting off.
  if (isTRUE(meta)) {
    meta_file <- file.path(snowball, "snowball_meta.parquet")
    result$meta <- if (file.exists(meta_file)) {
      as.data.frame(arrow::read_parquet(meta_file))
    } else {
      NULL
    }
  }

  return(result)
}

utils::globalVariables(c(".env", "from", "id", "oa_input", "to"))
