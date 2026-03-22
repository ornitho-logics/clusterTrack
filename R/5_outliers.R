.outliers_lof <- function(ctdf, minPts = NULL) {
  score_args = if (is.null(minPts)) list() else list(minPts = minPts)

  x = ctdf[cluster > 0]

  o = x[,
    .(outlier_lof = {
      xy = st_coordinates(.SD$location)
      do.call(lof, c(list(x = xy), score_args))
    }),
    by = cluster
  ]

  cbind(x[, .(.id)], o)
}

.outliers_glosh <- function(ctdf, k = NULL) {
  score_args = if (is.null(k)) list() else list(k = k)

  x = ctdf[cluster > 0]

  o = x[,
    .(outlier_glosh = {
      xy = st_coordinates(.SD$location)
      do.call(glosh, c(list(x = xy), score_args))
    }),
    by = cluster
  ]

  cbind(x[, .(.id)], o)
}


.cluster_geometry_metrics <- function(ctdf) {
  ctdf[
    cluster > 0,
    {
      coh = sf::st_union(location) |>
        sf::st_convex_hull()

      rect = sf::st_minimum_rotated_rectangle(coh)
      xy = sf::st_coordinates(rect)
      edges = sqrt(diff(xy[, "X"])^2 + diff(xy[, "Y"])^2)

      width = min(edges)
      length = max(edges)

      .(
        shape_score = 1 - width / length,
        convex_hull_area = as.numeric(sf::st_area(coh))
      )
    },
    by = cluster
  ]
}

#' Score outliers in a `ctdf`
#'
#' Computes outlier scores in a `ctdf`.
#'
#' Outlier scores are computed independently within each cluster.
#'
#' @param ctdf A `ctdf` object.
#' @param minPts Optional integer passed to [dbscan::lof()].
#' @param k Optional integer passed to [dbscan::glosh()].
#'
#' @return A copy of `ctdf` with appended outlier score columns.
#' @export
#'
#' @examples
#' data(mini_ruff)
#' x = as_ctdf(mini_ruff)
#' x = cluster_track(x)
#' z = outliers(x)
outliers <- function(
  ctdf,
  minPts,
  k
) {
  .check_ctdf(ctdf)

  minPts2 = if (missing(minPts)) NULL else minPts
  k2 = if (missing(k)) NULL else k

  o_lof = .outliers_lof(ctdf, minPts = minPts2)
  o_glosh = .outliers_glosh(ctdf, k = k2)
  o_cl_geom = .cluster_geometry_metrics(ctdf)

  o = merge(ctdf, o_lof, all.x = TRUE, by = c(".id", "cluster"), sort = FALSE)
  o = merge(o, o_glosh, all.x = TRUE, by = c(".id", "cluster"), sort = FALSE)
  o = merge(o, o_cl_geom, all.x = TRUE, by = "cluster", sort = FALSE)

  o
}
