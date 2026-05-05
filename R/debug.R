.new_putative_cluster_trace = function(trace) {
  if (!isTRUE(trace)) {
    return(list(
      capture = function(ctdf, stage) invisible(NULL),
      finalize = function() NULL
    ))
  }

  e = new.env(parent = emptyenv())
  e$id = NULL
  e$stage = character()
  e$value = list()
  e$n = 0

  list(
    capture = function(ctdf, stage) {
      e$n = e$n + 1
      e$stage[e$n] = stage

      if (is.null(e$id)) {
        e$id = ctdf$.id
      }

      e$value[[e$n]] = copy(ctdf$.putative_cluster)

      invisible(NULL)
    },

    finalize = function() {
      out = data.table(.id = e$id)
      out[, (e$stage) := e$value]
      out
    }
  )
}


#' Extract putative-cluster trace
#'
#' @param x A `ctdf` object returned by `cluster_track(trace = TRUE)`.
#'
#' @return A `data.table`, or `NULL`.
#' @export
#' @examples
#' data(mini_ruff)
#'
#' x = as_ctdf(mini_ruff)
#' cluster_track(x, trace = TRUE)
#'
#' tr = putative_cluster_trace(x)
#' tr
putative_cluster_trace = function(x) {
  attr(x, "putative_cluster_trace", exact = TRUE)
}
