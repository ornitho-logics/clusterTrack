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


#' Cluster a movement track into spatiotemporal clusters
#'
#' `cluster_track` that assigns a `cluster` id to each location in a `ctdf` by running a
#' multi-step pipeline:
#' 1) identify temporally continuous putative regions via [slice_ctdf()].
#' 2) merge adjacent putative regions with intersecting convex hulls via [spatial_repair()].
#' 3) locally split each putative region using DTSCAN via [local_cluster_ctdf()] and [sf_dtscan()].
#' 4) enforce non-overlap in time by merging any putative regions with
#' overlapping time domains via [temporal_repair()].
#' 5) drop small clusters and run additional spatial and track-shape repairs via [spatial_repair()]
#'    and [tail_repair()].
#' 5) optionally merge adjacent clusters within `aggregate_dist` via [aggregate_ctdf()].
#'
#' The function updates `ctdf` by reference and stores its parameters in
#' `attr(ctdf, "cluster_params")`.
#'
#' @param ctdf A `ctdf` object (see [as_ctdf()]).
#' @param deltaT Numeric; passed to [slice_ctdf()]. Maximum allowable time gap (in days)
#'   used when splitting candidate regions into movement segments.
#' @param nmin Integer; passed to [slice_ctdf()] (`nmin`) and [local_cluster_ctdf()] (`nmin`).
#' @param minCluster Integer; minimum number of points required to keep a putative cluster
#'   (clusters with `N <= minCluster` are dropped before final repairs).
#' @param area_z_min Numeric; pruning threshold forwarded to [local_cluster_ctdf()] and
#'   ultimately [sf_dtscan()] as `area_z_min` (sign is flipped internally).
#' @param length_z_min Numeric; pruning threshold forwarded to [local_cluster_ctdf()] and
#'   ultimately [sf_dtscan()] as `length_z_min` (sign is flipped internally).
#' @param trim Numeric; passed to [temporal_repair()]. Maximum fraction trimmed from each
#'   tail when estimating each cluster's time domain.
#' @param aggregate_dist Optional numeric; if supplied, passed to [aggregate_ctdf()] as `dist`
#'   (numeric treated as km).
#'
#' @return Invisibly returns `ctdf`, with `cluster` updated in-place and
#'   `attr(ctdf, "cluster_params")` set.
#'
#' @seealso
#' [as_ctdf()], [slice_ctdf()], [spatial_repair()], [local_cluster_ctdf()], [sf_dtscan()],
#' [temporal_repair()], [tail_repair()], [aggregate_ctdf()]
#'

#' @export
#' @examples
#' data(mini_ruff)
#' ctdf = as_ctdf(mini_ruff) |> cluster_track()
#'
#' if (requireNamespace("clusterTrack.Vis" )) {
#'   clusterTrack.Vis::map(ctdf)
#' }

#' \dontrun{
#' data(pesa56511)
#' pesa = as_ctdf(pesa56511, time = "locationDate") |> cluster_track()
#'
#' if (requireNamespace("clusterTrack.Vis" )) {
#'   clusterTrack.Vis::map(pesa)
#' }
#'
#' data(ruff143789)
#' ruff = as_ctdf(ruff143789, time = "locationDate") |> cluster_track()
#'
#' if (requireNamespace("clusterTrack.Vis" )) {
#'   clusterTrack.Vis::map(ruff)
#' }
#'
#' data(lbdo66862)
#' lbdo = as_ctdf(lbdo66862, time = "locationDate") |> cluster_track()
#'
#' if (requireNamespace("clusterTrack.Vis" )) {
#'   clusterTrack.Vis::map(lbdo)
#' }
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
  if (interactive()) {
    cli_alert("Finding putative cluster regions.")
  }
  slice_ctdf(ctdf, deltaT = deltaT, nmin = nmin)

  if (interactive()) {
    cli_alert("Preparing for local clustering.")
  }
  spatial_repair(ctdf, time_contiguity = TRUE)

  if (interactive()) {
    cli_alert("Running local clustering.")
  }

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
