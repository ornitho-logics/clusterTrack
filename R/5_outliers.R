#' Compute cluster-wise local outlier factor scores with `dbscan::lof()`
#'
#' Uses [dbscan::lof()] to compute Local Outlier Factor (LOF) scores
#' separately within each positive `cluster` of a `ctdf`, and writes the
#' result into the `lof` column. Rows with `cluster == 0` are assigned `NA`.
#'
#' @param ctdf A `ctdf` object containing `cluster`, `.id`, and `location`.
#' @param minPts Optional integer passed to [dbscan::lof()]. If `NULL`,
#'   [dbscan::lof()] is called with its defaults.
#'
#' The function updates `ctdf` by reference by creating or replacing the `lof`
#' column.
#'
#' @seealso [dbscan::lof()], [cluster_track()]
#'
#' @export
#'
#' @examples
#' data(mini_ruff)
#' x = as_ctdf(mini_ruff)
#' cluster_track(x)
#' x = ctdf_lof(x)
#' head(x[, .(.id, cluster, lof)])

ctdf_lof <- function(ctdf, minPts = NULL) {
  o = ctdf[
    cluster > 0,
    {
      xy = sf::st_coordinates(location)

      .(
        .id = .id,
        lof = if (is.null(minPts)) {
          dbscan::lof(x = xy)
        } else {
          dbscan::lof(x = xy, minPts = minPts)
        }
      )
    },
    by = cluster
  ]

  ctdf[, lof := NA_real_]
  ctdf[
    o,
    on = .(.id),
    lof := i.lof
  ]

  ctdf
}


#' Summarise geometric elongation of clusters
#'
#' Computes shape descriptors for each `cluster` in a `ctdf`, based on
#' the convex hull of its locations and the minimum rotated rectangle enclosing
#' that hull.
#'
#' @param ctdf A `ctdf` object containing `cluster` and `location`.
#'
#' @details
#' For each cluster, the function computes:
#' \describe{
#'   \item{`axis_length`}{Maximum edge length of the minimum rotated rectangle.}
#'   \item{`convex_hull_area`}{Area of the cluster convex hull.}
#'   \item{`z_axis_length`}{Scaled log axis length.}
#'   \item{`z_log_shape_ratio`}{Scaled log ratio `axis_length^2 / convex_hull_area`.}
#'   \item{`elongation`}{Combined score
#'     `pmax(z_axis_length, 0) * pmax(z_log_shape_ratio, 0)`.}
#' }
#'
#' Larger values indicate clusters that are both relatively large in one
#' principal dimension and relatively elongated for their area.
#'
#' @return A `data.table` with one row per `cluster`.
#'
#' @seealso [summary.ctdf()], [cluster_track()]
#'
#' @export
#'
#' @examples
#' data(mini_ruff)
#' x = as_ctdf(mini_ruff)
#' cluster_track(x)
#' ctdf_elongation(x)

ctdf_elongation <- function(ctdf) {
  scores = ctdf[
    cluster > 0,
    {
      coh = sf::st_union(location) |>
        sf::st_convex_hull()

      rect = sf::st_minimum_rotated_rectangle(coh)
      xy = sf::st_coordinates(rect)

      edges = sqrt(diff(xy[, "X"])^2 + diff(xy[, "Y"])^2)

      .(
        axis_length = max(edges),
        convex_hull_area = sf::st_area(coh)
      )
    },
    by = cluster
  ]

  scores[,
    z_axis_length := scale(log(axis_length))
  ]
  scores[,
    z_log_shape_ratio := scale(log(axis_length^2 / convex_hull_area))
  ]
  scores[,
    elongation := pmax(z_axis_length, 0) * pmax(z_log_shape_ratio, 0)
  ]

  scores
}
