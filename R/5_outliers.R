#' Compute cluster-wise local outlier factor scores with `dbscan::lof()`
#'
#' Uses [dbscan::lof()] to compute Local Outlier Factor (LOF) scores
#' separately within each `cluster` of a `ctdf`, and writes the
#' result into the `lof` column.
#'
#' @param ctdf A `ctdf` object .
#' @param minPts Optional integer passed to [dbscan::lof()]. If `NULL`,
#'   [dbscan::lof()] is called with its defaults.
#'
#' The function updates `ctdf` by reference by updating the `lof` column.
#'
#' @seealso [dbscan::lof()], [cluster_track()].
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
#' @param ctdf A `ctdf` object.
#'
#' @details
#' For each cluster, the function computes:
#' \describe{
#'   \item{`convex_hull_area`}{Area of the cluster convex hull.}
#'   \item{`log_axis_length`}{Log of the maximum edge length of the minimum rotated rectangle.}
#'   \item{`log_shape_ratio`}{Log ratio `axis_length^2 / convex_hull_area`.}
#'   \item{`elongation`}{Product of the standardised values of
#'   `axis_length` and `log_shape_ratio`. Clusters below average on either
#'   component receive a score of `0` so only above-average values on both components
#' increase the score.}
#' }
#'
#' Larger values indicate clusters that are both relatively large in one
#' principal dimension and relatively elongated for their area.
#'
#' @return A `data.table` with one row per `cluster`.
#'
#' @references
#' Chorley, R. J., Malm, D. E. G., & Pogorzelski, H. A. (1957).
#' A new standard for estimating drainage basin shape.
#' \emph{American Journal of Science}, 255, 138--141.
#'
#' @seealso [summary.ctdf()], [cluster_track()], [sf::st_minimum_rotated_rectangle()]
#'
#' @export
#'
#' @examples
#' data(mini_ruff)
#' x = as_ctdf(mini_ruff)
#' cluster_track(x)
#' o = ctdf_elongation(x)
#' head(o)

ctdf_elongation <- function(ctdf) {
  empty = data.table(
    cluster = NA_integer_,
    convex_hull_area = NA_real_,
    axis_length = NA_real_,
    log_shape_ratio = NA_real_,
    elongation = NA_real_
  )

  if (!nrow(ctdf)) {
    return(empty)
  }

  x = ctdf[cluster > 0]

  if (nrow(x) < 3) {
    return(empty)
  }

  scores = x[,
    {
      coh = sf::st_union(location) |>
        sf::st_convex_hull()

      rect = sf::st_minimum_rotated_rectangle(coh)
      xy = sf::st_coordinates(rect)

      if (nrow(xy) < 3) {
        return(empty[-1, ])
      }

      edges = sqrt(diff(xy[, "X"])^2 + diff(xy[, "Y"])^2)

      .(
        axis_length = max(edges),
        convex_hull_area = sf::st_area(coh)
      )
    },
    by = cluster
  ]

  scores[,
    log_axis_length := log(axis_length)
  ]
  scores[,
    log_shape_ratio := log(axis_length^2 / convex_hull_area)
  ]
  scores[,
    elongation := pmax(scale(log_axis_length), 0) *
      pmax(scale(log_shape_ratio), 0)
  ]

  scores
}
