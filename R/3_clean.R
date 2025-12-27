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

  x[,
    lof := {
      kmax = nrow(.SD) |>
        sqrt() |>
        ceiling()

      k_vals = 2:kmax
      lof_vals = lapply(
        k_vals,
        \(kk) dbscan::lof(st_coordinates(location), minPts = kk)
      )
      o = do.call(cbind, lof_vals)
      apply(o, 1, median)
    },
    by = .putative_cluster
  ]

  x[, Qnt := quantile(lof, Q), by = .putative_cluster]

  x = x[lof > Qnt]

  ctdf[.id %in% x$.i, .putative_cluster := NA]

  ctdf[,
    cluster := .as_inorder_int(cluster)
  ]
}
