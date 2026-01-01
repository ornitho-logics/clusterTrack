#
#
local_cluster_ctdf <- function(ctdf, nmin = 3) {
  x = ctdf[!is.na(.putative_cluster)]

  x = x[,
    putative_cluster_local := sf_dtscan(
      st_as_sf(.SD),
      id_col = '.id',
      min_pts = nmin
    ),
    by = .putative_cluster
  ]

  x[,
    putative_cluster := paste(
      .putative_cluster,
      putative_cluster_local,
      sep = "_"
    ) |>
      forcats::fct_inorder() |>
      as.integer()
  ]

  x[putative_cluster_local == 0, putative_cluster := NA]

  out = x[, .(.id, putative_cluster)]
  setkey(out, .id)

  ctdf[out, .putative_cluster := i.putative_cluster]
}
