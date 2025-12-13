#' @export

cluster_ <- function(
  ctdf,
  nmin = 3
) {
  if (nrow(ctdf[!is.na(.putative_cluster)]) == 0) {
    warning("No valid putative clusters found!")
    return(NULL)
  }

  x = ctdf[!is.na(.putative_cluster), .(.id, .putative_cluster, location)]

  x = x[.putative_cluster == 23]

  x[,
    cluster := {
      coords = st_coordinates(x$location)
      ap = apcluster(negDistMat(r = 2), coords, q = 0.2)
      labels(ap) |>
        as.factor() |>
        as.integer()
    },
    by = .putative_cluster
  ]

  #' mapview::mapview(st_as_sf(x[.putative_cluster == 22]), zcol = ".putative_cluster")
  #'
  #'
}
