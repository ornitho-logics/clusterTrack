#' Clean putative clusters after slicing
#'
#' Slicing removes selected movement segments from a track and identifies
#' putative cluster regions. At this stage, putative clusters are not yet
#' valid clusters because they may still contain track fragments and outliers.
#' This function removes outliers and residual movement segments from
#' putative clusters.
#'
#' @param ctdf A cluster-track data.table after slicing
#' @return A cleaned cluster-track data.table containing only refined
#'   putative cluster points

#' @export

clean_ctdf <- function(ctdf, Q = 0.95) {
  .check_ctdf(ctdf)

  x = ctdf[!is.na(.putative_cluster)]
  x[, n := .N, by = .putative_cluster]
  x = x[n >= 5]

  x[,
    lof := {
      k = nrow(.SD) |>
        sqrt() |>
        floor()
      dbscan::lof(st_coordinates(location), minPts = min(k, 10)) # TODO
    },
    by = .putative_cluster
  ]

  x[, Qnt := quantile(lof, Q), by = .putative_cluster]

  x = x[lof > Qnt]

  cat(length(x$.id), "\n") |> print()
  cat(x$.id, sep = ",") |> print()

  ctdf[.id %in% x$.i, .putative_cluster := NA]
}
