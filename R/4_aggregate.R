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
    warning(
      sprintf(
        "aggregate_ctdf(): no consecutive clusters within dist = %s; returning input unchanged.",
        format(dist_u)
      ),
      call. = FALSE
    )
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


#' Aggregate a ctdf.
#'
#' @param ctdf A `ctdf` object.
#' @param dist aggregation scale (numeric treated as km )
#' @export

aggregate_ctdf <- function(ctdf, dist) {
  .check_ctdf(ctdf)

  repeat {
    n_prev = max(ctdf$cluster, na.rm = TRUE)

    .aggregate_ctdf(ctdf, dist = dist)

    if (max(ctdf$cluster, na.rm = TRUE) == n_prev) break
  }

  ctdf[,
    cluster := .as_inorder_int(cluster)
  ]
}
