#' Summarise a ctdf by cluster
#'
#' Returns one row per `cluster` with start and stop times, tenure in days,
#' convex-hull centroid, row count, the 95th percentile of within-cluster `lof`
#' scores, and a cluster elongation score.
#'
#' @param object A `ctdf` (inherits `data.table`).
#' @param ...  Currently ignored.
#' @return A `summary_ctdf` `data.table` .
#'
#' @details
#' `lof_q95` is the 95th percentile of lof scores within each cluster.
#' Larger values indicate that the most extreme points in
#' the cluster are more locally isolated relative to their neighbours, so this
#' can be used as a summary of within-cluster outlier-ness.
#'
#' `elongation` is a geometric cluster-shape summary derived from the convex hull
#' and its minimum rotated rectangle. Larger values indicate clusters that are
#' both relatively long in one principal dimension and elongated for their area.
#'
#' @seealso [cluster_track()], [ctdf_lof()], [ctdf_elongation()]

#' @export
#' @examples
#' data(mini_ruff)
#' ctdf = as_ctdf(mini_ruff)
#' cluster_track(ctdf)
#' summary(ctdf)
#'
#'
summary.ctdf <- function(object, ...) {
  .check_ctdf(object)

  if (is.na(object$cluster) |> all()) {
    out = object[, .(
      start = min(timestamp),
      stop = max(timestamp),
      geometry = st_union(location) |> st_convex_hull() |> st_centroid(),
      ids = paste(range(.id), collapse = "-"),
      lof_q95 = NA,
      N = .N
    )]
    out[, cluster := NA_integer_]
    setcolorder(out, c("cluster", "start", "stop", "geometry", "ids", "N"))

    return(out)
  }

  out =
    object[
      cluster > 0,
      .(
        start = min(timestamp),
        stop = max(timestamp),
        geometry = st_union(location) |> st_convex_hull() |> st_centroid(),
        lof_q95 = as.numeric(quantile(
          lof,
          probs = 0.95,
          type = 8,
          na.rm = TRUE
        )),
        ids = paste(range(.id), collapse = "-"),
        N = .N
      ),
      by = cluster
    ]

  out[, tenure := difftime(stop, start, units = "days")]

  out[, next_geom := geometry[shift(seq_len(.N), type = "lead")]]

  out[, dist_to_next := st_distance(geometry, next_geom, by_element = TRUE)]

  out[, next_geom := NULL]

  # between-cluster outlier
  el = ctdf_elongation(object)[, .(cluster, elongation)]
  out = merge(out, el, all.x = TRUE, sort = FALSE)

  class(out) = c("summary_ctdf", class(out))
  out
}
