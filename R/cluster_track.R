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
#' @param nmin Integer; passed to [local_cluster_ctdf()] (`nmin`).
#'   (clusters with `N <= minCluster` are dropped before final repairs).
#' @param z_min Numeric; pruning strictness in SD units.
#'   Smaller values produce more compact clusters and often more unassigned points.
#'   Implementation detail: the underlying thresholds use an inverse z-score convention, 
#'   so the sign is flipped internally; see [sf_dtscan()]  and [local_cluster_ctdf()].
#' @param trim Numeric; passed to [temporal_repair()]. Maximum fraction trimmed from each
#' @param deltaT Optional numeric; passed to [slice_ctdf()]. Maximum allowable time gap (in days)
#' @param minCluster Integer; minimum number of points required to keep a putative cluster
#'   used when splitting candidate regions into movement segments.
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
#' x = as_ctdf(mini_ruff) |> cluster_track()
#'
#' \dontrun{
#' data(pesa56511)
#' pesa = as_ctdf(pesa56511, time = "locationDate") |> cluster_track()
#'
#' data(ruff143789)
#' ruff = as_ctdf(ruff143789, time = "locationDate") |> cluster_track()
#'
#' data(lbdo66862)
#' lbdo = as_ctdf(lbdo66862, time = "locationDate") |> cluster_track()
#'
#'
#' }

cluster_track <- function(
  ctdf,
  nmin = 3,
  z_min = 1,
  trim = 0.05,
  minCluster = 3,
  deltaT,
  aggregate_dist
) {
  options(datatable.showProgress = FALSE)

  # slice

  cli_alert("Find putative cluster regions.")

  if (missing(deltaT)) {
    deltaT = 1e+05
  }
  slice_ctdf(ctdf, deltaT = deltaT)

  cli_alert_warning("Spatial repair.")

  spatial_repair(ctdf, time_contiguity = TRUE)

  cli_alert("Local clustering.")

  local_cluster_ctdf(
    ctdf,
    nmin = nmin,
    area_z_min = z_min * -1,
    length_z_min = z_min * -1
  )

  cli_alert_warning("Temporal repair.")
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
    nmin = nmin,
    minCluster = minCluster,
    z_min = z_min,
    trim = trim,
    deltaT = if (deltaT == 1e+05) {
      deltaT = NA
    } else {
      deltaT
    },
    aggregate_dist = if (missing(aggregate_dist)) {
      aggregate_dist = NA
    } else {
      aggregate_dist
    }
  )

  setattr(ctdf, "cluster_params", cluster_params)
}
