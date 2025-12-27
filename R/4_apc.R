#TODO
#' @export

local_cluster_ctdf <- function(ctdf) {
  x = ctdf[!is.na(.putative_cluster), .(.id, .putative_cluster, location)]

  x[,
    canditate_cl := {
      coords = st_coordinates(location)
      ap = apcluster::apcluster(apcluster::negDistMat(r = 2), coords, q = 0.2)

      cl = integer(.N)
      for (k in seq_along(ap@clusters)) {
        cl[ap@clusters[[k]]] = k
      }

      cl
    },
    by = .putative_cluster
  ]

  # TODO insure temporal separation!

  x[,
    putative_cluster := paste(
      .putative_cluster,
      canditate_cl,
      sep = "_"
    ) |>
      forcats::fct_inorder() |>
      as.integer()
  ]

  out = x[, .(.id, putative_cluster)]
  setkey(out, .id)

  ctdf[out, .putative_cluster := i.putative_cluster]
}
