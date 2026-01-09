#' @export
print.clusterTrack <- function(x, ...) {
  cat("<clusters:", uniqueN(x$cluster) - 1, ">\n\n")

  NextMethod("print", topn = 3, nrows = 10, print.keys = FALSE, ...)
}

#' @export
plot.clusterTrack <- function(x) {
  pal = topo.colors(n = uniqueN(x$cluster))
  cols = pal[match(x$cluster, sort(unique(x$cluster)))]

  plot(st_geometry(x$location), col = cols)
}


.subset_by_minCluster <- function(ctdf, minCluster) {
  ctdf[
    .putative_cluster %in%
      ctdf[, .N, .putative_cluster][N <= minCluster]$.putative_cluster,
    .putative_cluster := NA
  ]
  ctdf[,
    .putative_cluster := .as_inorder_int(.putative_cluster)
  ]
}


#' Cluster movement tracks
#'
#' Performs spatiotemporal clustering on a ctdf by segmenting movement, identifying stops, and applying DBSCAN-like clustering.
#'
#'
#' This is a high-level wrapper function that applies a pipeline of segmentation, clustering, and repairing steps on a movement track stored in a `ctdf` object.
#'
#'
#' @param ctdf   A `ctdf` data frame (see [as_ctdf()]) representing a single movement track .
#' @param deltaT Numeric; maximum allowable gap (in days) between segment endpoints to consider them non-intersecting.
#'               Default to 1 day. Passed to [slice()]) .
#' @param nmin   Integer. Segments or tessellations with fewer than nmin points yield no clusters.
#'               Default to 3. Passed to [cluster_segments()].
#' @param threshold Numeric. the multiplier of the standard deviation
#'                  on log‐areas used in pruning. Passed to [cluster_segments()].
#' @param time_contiguity Logical; if `TRUE`, missing cluster IDs (usually spatial outliers) are  filled
#'                        within each cluster to enforce temporal continuity.
#'                        Default to `FALSE`.
#'                        Passed to [cluster_segments()].
#' @param overlap_threshold Numeric between 0 and 1; minimum area‐overlap ratio
#'                          required to merge adjacent clusters. Default to 0.1.
#'                          Clusters with overlap > threshold are combined.
#'                          Passed to [spatial_repair()]
#' @param aggregate_dist distance in km. default NULL.
#' @return NULL.
#' The function modifies `ctdf` by reference, adding or updating the column \code{cluster},
#' which assigns a cluster ID to each row (point).
#' Clustering parameters are stored as an attribute: `attr(ctdf, "cluster_params")`.
#'

#' @export
#' @examples
#' data(mini_ruff)
#' ctdf = as_ctdf(mini_ruff) |> cluster_track()
#' map(ctdf)
#'
#' \dontrun{
#' data(pesa56511)
#' ctdf = as_ctdf(pesa56511, time = "locationDate") |> cluster_track()
#' map(ctdf)
#'
#' ctdf = as_ctdf(pesa56511, time = "locationDate")
#' cluster_track(ctdf, aggregate_dist = 20)
#' map(ctdf)
#'
#' data(ruff143789)
#' ctdf = as_ctdf(ruff143789, time = "locationDate") |> cluster_track()
#' map(ctdf)
#'
#' data(lbdo66862)
#' ctdf = as_ctdf(lbdo66862, time = "locationDate") |> cluster_track()
#' map(ctdf)
#'
#'
#'
#' }

cluster_track <- function(
  ctdf,
  deltaT = 30,
  nmin = 3,
  minCluster = 3,
  area_z_min = 1,
  length_z_min = 1,
  trim = 0.05,
  aggregate_dist
) {
  options(datatable.showProgress = FALSE)

  # slice
  cli_alert("Finding putative cluster regions.")
  slice_ctdf(ctdf, deltaT = deltaT, nmin = nmin)

  cli_alert("Preparing for local clustering.")
  spatial_repair(ctdf, time_contiguity = TRUE)

  cli_alert("Running local clustering.")

  local_cluster_ctdf(
    ctdf,
    nmin = nmin,
    area_z_min = area_z_min * -1,
    length_z_min = length_z_min * -1
  )

  temporal_repair(ctdf, trim = trim)

  .subset_by_minCluster(ctdf, minCluster = minCluster)

  spatial_repair(ctdf, time_contiguity = FALSE)

  tail_repair(ctdf)

  # assign to cluster
  ctdf[, cluster := .putative_cluster]
  ctdf[is.na(cluster), cluster := 0]

  if (!missing(aggregate_dist)) {
    aggregate_ctdf(ctdf, dist = aggregate_dist)
  }

  #collect parameters
  cluster_params = list(
    deltaT = deltaT,
    nmin = nmin,
    minCluster = minCluster,
    area_z_min = area_z_min,
    length_z_min = length_z_min,
    trim = trim,
    aggregate_dist = if (missing(aggregate_dist)) {
      aggregate_dist = NA
    } else {
      aggregate_dist
    }
  )

  setattr(ctdf, "cluster_params", cluster_params)
}
