#' Cluster a movement track into spatiotemporal clusters

#' `cluster_track()` identifies use sites: areas where an individual concentrates
#' its activity during distinct periods along a movement track.
#'
#' The method initially splits the track into provisional regions,
#' allowing spatial clustering to adapt to local conditions. Neighbouring regions
#' or clusters are combined when their spatial structure provides insufficient
#' evidence for keeping them separate.
#'
#' The resulting use sites describe where and when the animal concentrated its
#' activity, allowing separate visits to the same place to be distinguished.
#' Optional distance-based aggregation combines nearby, temporally adjacent sites
#' at a spatial scale chosen by the user.
#'
#' The function updates `ctdf` by reference and stores its parameters in
#' `attr(ctdf, "cluster_params")`.
#'
#' @param ctdf A `ctdf` object (see [as_ctdf()]).
#'
#' @param nmin Integer; local DTSCAN support threshold. Passed to
#'   [local_cluster_ctdf()] as `nmin`, then to [sf_dtscan()] as `min_pts`,
#'   where it defines the minimum effective Delaunay-neighbour count for a
#'   core site.
#'
#' @param z_min Numeric; pruning strictness in SD units.
#'   Smaller values produce more compact clusters and often more unassigned points.
#'   Implementation detail: the underlying thresholds use an inverse z-score convention,
#'   so the sign is flipped internally; see [sf_dtscan()]  and [local_cluster_ctdf()].
#'
#' @param trim Numeric; passed to [temporal_repair()]. Maximum fraction
#'             trimmed from each tail estimating each cluster's time domain.
#'
#' @param deltaT Optional numeric; passed to [slice_ctdf()]. Maximum allowable time gap (in days).
#'
#' @param minCluster Integer; post-clustering pruning threshold. Putative
#'   clusters with `N <= minCluster` are dropped.
#'
#' @param aggregate_dist Optional numeric; if supplied, passed to [aggregate_ctdf()] as `dist`
#'   (numeric treated as km).
#'
#' @param trace Logical; if TRUE, store intermediate .putative_cluster labels
#'   from the cluster_track() pipeline in attr(ctdf, "putative_cluster_trace").
#'
#' @return Invisibly returns `ctdf`, with `cluster` updated in-place and
#'   `attr(ctdf, "cluster_params")` set.
#'
#' @seealso
#' [as_ctdf()], [slice_ctdf()], [spatial_repair()], [local_cluster_ctdf()], [sf_dtscan()],
#' [temporal_repair()],  [aggregate_ctdf()], [putative_cluster_trace()]
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
#' data(ruff07b5)
#' ruff2 = as_ctdf(ruff07b5, time = "timestamp") |> cluster_track()
#'
#' data(lbdo66862)
#' lbdo = as_ctdf(lbdo66862, time = "locationDate") |> cluster_track()
#'
#' data(nola125a)
#' nola = as_ctdf(nola125a, time = "timestamp") |> cluster_track()
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
  aggregate_dist,
  trace = FALSE
) {
  old_options <- options(datatable.showProgress = FALSE)
  on.exit(options(old_options), add = TRUE)

  tr <- .new_putative_cluster_trace(trace)

  # slice

  .alert("Find putative cluster regions.")

  if (missing(deltaT)) {
    deltaT <- NA
  }
  slice_ctdf(ctdf, deltaT = deltaT)
  tr$capture(ctdf, "slice")

  .warning("Repairing[1]...")

  spatial_repair(ctdf, time_contiguity = FALSE)
  tr$capture(ctdf, "spatial_repair_1")

  .alert("Local clustering.")

  local_cluster_ctdf(
    ctdf,
    nmin = nmin,
    area_z_min = z_min * -1,
    length_z_min = z_min * -1
  )
  tr$capture(ctdf, "dtscan")

  .warning("Repairing[2]...")

  spatial_repair(ctdf, time_contiguity = FALSE)
  tr$capture(ctdf, "spatial_repair_2")

  # clean up
  .subset_by_minCluster(ctdf, minCluster = minCluster)
  tr$capture(ctdf, "subset_by_minCluster")

  .drop_false_cluster(ctdf, minCluster = minCluster)
  tr$capture(ctdf, "drop_false_cluster")

  temporal_repair(ctdf, trim = trim)
  tr$capture(ctdf, "temporal_repair")

  # assign to cluster
  ctdf[, cluster := .putative_cluster]
  ctdf[is.na(cluster), cluster := 0]

  # compute lof
  .warning("Compute lof scores...")
  ctdf_lof(ctdf)

  if (!missing(aggregate_dist)) {
    aggregate_ctdf(ctdf, dist = aggregate_dist)
  }

  #collect parameters
  cluster_params <- list(
    nmin = nmin,
    minCluster = minCluster,
    z_min = z_min,
    trim = trim,
    deltaT = deltaT,
    aggregate_dist = if (missing(aggregate_dist)) {
      aggregate_dist <- NA
    } else {
      aggregate_dist
    }
  )

  if (isTRUE(trace)) {
    setattr(ctdf, "putative_cluster_trace", tr$finalize())
  }

  setattr(ctdf, "cluster_params", cluster_params)

  ctdf[, let(
    .move_seg = NA_integer_,
    .seg_id = NA_integer_,
    .putative_cluster = NA_integer_
  )]

  invisible(ctdf)
}
