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

#' Score outliers within- and between clusters of a `ctdf`
#'
#' Computes two point-level outlier scores for each observation assigned to a
#' non-noise cluster in a `ctdf`:
#' \itemize{
#'   \item local outlier factor via [dbscan::lof()]
#'   \item GLOSH via [dbscan::glosh()]
#' }
#'
#' Cluster-level geometry metrics are also computed for each non-noise cluster
#' from the convex hull of `location`.
#'
#' Outlier scores and geometry metrics are computed independently within each
#' cluster.
#'
#' @param ctdf A `ctdf` object.
#' @param minPts Optional integer passed to [dbscan::lof()]. If missing,
#'   the default used by [dbscan::lof()] is applied.
#' @param k Optional integer passed to [dbscan::glosh()]. If missing,
#'   the default used by [dbscan::glosh()] is applied.
#'
#' @return
#' A `ctdf` with the following appended columns:
#' \describe{
#'   \item{`outlier_lof`}{Local outlier factor score.}
#'   \item{`outlier_glosh`}{GLOSH outlier score.}
#'   \item{`shape_score`}{Cluster elongation score, computed as
#'     `1 - width / length` from the minimum rotated rectangle of the convex
#'     hull.}
#'   \item{`convex_hull_area`}{Area of the cluster convex hull.}
#' }
#' Observations with `cluster <= 0` receive `NA` for the appended metrics.
#'
#' @export
#'
#' @examples
#' data(mini_ruff)
#' x = as_ctdf(mini_ruff)
#' x = cluster_track(x)
#' z = outliers(x)
#'
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
