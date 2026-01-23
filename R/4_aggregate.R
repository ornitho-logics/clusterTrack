.aggregate_ctdf <- function(ctdf, dist) {
  dist_u = units::set_units(dist, "km")

  x = ctdf[cluster > 0]

  dom = x[,
    .(
      t_key = median(timestamp),
      geometry = sf::st_union(location) |>
        sf::st_convex_hull() |>
        sf::st_centroid()
    ),
    by = cluster
  ]

  dom[, next_cluster := shift(cluster, type = "lead")]

  dom[, lead_i := shift(.I, type = "lead")]
  dom[
    !is.na(lead_i),
    next_cluster_is_nb := {
      m = sf::st_is_within_distance(
        geometry,
        dom$geometry[lead_i],
        dist = dist_u,
        sparse = FALSE
      )
      as.logical(m[1, 1])
    },
    by = .I
  ]

  dom[is.na(lead_i), next_cluster_is_nb := FALSE]
  dom[, lead_i := NULL]

  edges = dom[next_cluster_is_nb == TRUE, .(cluster, next_cluster)]

  if (!nrow(edges)) {
    return(ctdf)
  }

  g = igraph::graph_from_data_frame(
    edges,
    directed = FALSE,
    vertices = data.table::data.table(name = dom$cluster)
  )

  cc = igraph::components(g)$membership

  map = data.table(
    cluster = names(cc) |> as.integer(),
    merged = cc
  )[order(cluster)]

  dom[map, on = .(cluster), new_cluster := i.merged]

  dom[, new_cluster := .as_inorder_int(new_cluster)]

  ctdf[
    dom,
    on = .(cluster),
    cluster := i.new_cluster
  ]
}

#' Aggregate (merge) adjacent clusters by spatial proximity
#'
#' Iteratively merges temporally adjacent `cluster` ids whose locations are within
#' `dist` of each other. This is a repair/aggregation step for an existing clustering:
#' it does not compute clusters from scratch, it merges neighbouring ones.
#'
#' @details
#' Merging is put as a graph problem. An undirected adjacency graph is constructed with one
#' vertex per `cluster`. An edge is added between two vertices corresponding to consecutive cluster
#' ids (`cluster` and `cluster + 1`) if the distance between their geometries is less
#' than `dist`. clusters are merged by taking connected components of this graph.
#' The procedure is repeated until no further merges occur.
#'
#' Representative geometry for each cluster is computed as the centroid of the convex hull of all
#' points in that cluster.
#'
#' This updates `cluster` by reference.
#'
#' @param ctdf A `ctdf` object. Must contain `cluster`, `timestamp`, and `location`.
#' @param dist Aggregation scale in km.
#'
#' @return The input `ctdf`, invisibly, with `cluster` updated in-place.
#'
#' @export
aggregate_ctdf <- function(ctdf, dist) {
  .check_ctdf(ctdf)

  repeat {
    n_prev = max(ctdf$cluster, na.rm = TRUE)

    .aggregate_ctdf(ctdf, dist = dist)

    if (max(ctdf$cluster, na.rm = TRUE) == n_prev) break
  }
}
