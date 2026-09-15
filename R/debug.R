.new_putative_cluster_trace <- function(trace) {
  if (!isTRUE(trace)) {
    return(list(
      capture = function(ctdf, stage) invisible(NULL),
      finalize = function() NULL
    ))
  }

  e <- new.env(parent = emptyenv())
  e$id <- NULL
  e$stage <- character()
  e$value <- list()
  e$n <- 0

  list(
    capture = function(ctdf, stage) {
      e$n <- e$n + 1
      e$stage[e$n] <- stage

      if (is.null(e$id)) {
        e$id <- ctdf$.id
      }

      e$value[[e$n]] <- copy(ctdf$.putative_cluster)

      invisible(NULL)
    },

    finalize = function() {
      out <- data.table(.id = e$id)
      out[, (e$stage) := e$value]
      out
    }
  )
}


#' Extract putative-cluster trace
#'
#' Extracts the intermediate `.putative_cluster` assignments recorded during
#' [cluster_track()] when called with `trace = TRUE`.
#'
#' @param x A `ctdf` object returned by `cluster_track(trace = TRUE)`.
#' @param bind Logical. If `FALSE`, return the trace as a `data.table`.
#'   If `TRUE`, return a copy of `x` with the trace columns appended.
#'
#' @return
#' If `bind = FALSE`, a `data.table` containing `.id` and one column for each
#' recorded clustering stage. If `bind = TRUE`, a `ctdf` with the trace
#' columns appended. Returns `NULL` if no trace is stored.
#'
#' @details
#' The stored trace is aligned to the `ctdf` by `.id`. When `bind = TRUE`,
#' `.id` must be identical in the trace and `x`; otherwise an error is raised.
#' The input `x` is not modified.
#'
#' @examples
#' data(mini_ruff)
#'
#' x = as_ctdf(mini_ruff)
#' cluster_track(x, trace = TRUE)
#'
#' putative_cluster_trace(x)
#' putative_cluster_trace(x, bind = TRUE)
#'
#' @export
putative_cluster_trace <- function(x, bind = FALSE) {
  tr <- attr(x, "putative_cluster_trace", exact = TRUE)

  if (!bind || is.null(tr)) {
    return(tr)
  }

  if (!identical(x$.id, tr$.id)) {
    stop("Trace does not match ctdf.", call. = FALSE)
  }

  out <- copy(x)

  nams <- setdiff(names(tr), ".id")
  vals <- tr[, .SD, .SDcols = nams]

  out[, (nams) := vals]

  out
}
