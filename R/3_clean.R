estimate_minPts = function(
  coords,
  k_floor = 10L,
  tol = 0.05,
  win = 3L
) {
  n = nrow(coords)

  k_max = min(n, 50L)

  ks = 2L:k_max
  lof_list = lapply(ks, \(k) dbscan::lof(coords, minPts = k))
  sds = vapply(lof_list, sd, numeric(1))

  if (length(sds) < (win + 1L)) {
    return(min(max(2L, floor(n / 2)), n))
  }

  rel = abs(diff(sds)) / pmax(sds[-1L], .Machine$double.eps)
  ok = rel < tol
  k0 = which(vapply(
    seq_along(ok),
    \(i) all(ok[i:min(length(ok), i + win - 1L)]),
    logical(1)
  ))[1]
  if (is.na(k0)) {
    return(min(max(2L, k_floor), n))
  }
  min(max(ks[k0 + 1L], 2L), n)
}

lof_max_over_range = function(coords, k_lb, k_ub) {
  ks = k_lb:k_ub
  lof_list = lapply(ks, \(k) dbscan::lof(coords, minPts = k))
  Reduce(pmax, lof_list)
}


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

clean_ctdf <- function(ctdf, Q = 0.8) {
  .check_ctdf(ctdf)

  x = ctdf[!is.na(.putative_cluster)]
  x[, n := .N, by = .putative_cluster]

  # x[,
  #   lof := {
  #     k = nrow(.SD) |>
  #       sqrt() |>
  #       floor()
  #     dbscan::lof(st_coordinates(location), minPts = min(k, 10)) # TODO
  #   },
  #   by = .putative_cluster
  # ]

  # median lof across k ranges
  x[,
    lof := {
      kmax = nrow(.SD) |>
        sqrt() |>
        ceiling()

      k_vals = 3L:kmax
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
}
