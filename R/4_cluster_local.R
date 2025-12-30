.tesselate <- function(x) {
  p = st_as_sf(x[, .(.id, location)]) |>
    st_make_valid()

  tess = st_combine(p) |>
    st_voronoi(point_order = TRUE, dTolerance = 1e-4) |>
    st_collection_extract("POLYGON")

  tess = st_cast(tess, "MULTIPOLYGON") |> st_geometry()

  st_set_geometry(p, tess)
}

.isolate_clusters <- function(tess) {
  nb = poly2nb(tess, queen = TRUE) |> suppressWarnings()
  g = graph_from_adj_list(nb, mode = "all") |> as_undirected()
  components(g)$membership
}


#' @export

local_cluster_ctdf <- function(ctdf, nmin = 3, threshold = 1) {
  x = ctdf[!is.na(.putative_cluster)]

  x = x[, .tesselate(.SD), by = .putative_cluster]

  x[, A := st_sfc(location) |> st_area() |> as.numeric()]

  x[, zA := scale(log(A)) |> as.numeric(), by = .putative_cluster]

  x[, keep := zA < threshold]

  x = x[(keep)]

  # isolate clusters and assign clusters ID-s

  x[,
    cluster := .isolate_clusters(st_sfc(location)),
    by = .putative_cluster
  ]

  #TODO
  # if one cluster detected, keep all data
  # insure temp contiguity after clustering
}
