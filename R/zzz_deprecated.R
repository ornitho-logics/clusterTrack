#' Deprecated clusterTrack functions
#'
#' `as_tdbscan()` and `tdbscan()` are deprecated. Use [as_ctdf()] and
#' [cluster_track()] instead.
#'
#' @param x A `data.frame` or `data.table` containing coordinates and a time column.
#' @param coords Character vector of length 2 giving coordinate column names.
#' @param time Name of the time column.
#' @param crs Coordinate reference system passed to `sf::st_as_sf()`.
#' @param track An `sf` object ordered by time.
#' @param eps Size of the epsilon neighborhood; see [dbscan::dbscan()].
#' @param minPts Minimum number of points in an epsilon neighborhood.
#' @param borderPoints Logical; whether to include border points.
#' @param maxLag Maximum separation in row indices between connected points.
#' @param minTenure Optional minimum cluster duration, in hours.
#' @return `as_tdbscan()` returns an `sf` object with a `timestamp` column.
#'   `tdbscan()` returns `track` with an integer `clustID` column;
#'   unassigned locations have `NA` cluster IDs.
#' @note `tdbscan()` was used in Kempenaers, B., Valcu, M., Piersma, T.,
#'   Santema, P. and Vervoort, R. (2025). Large-scale sampling of potential
#'   breeding sites in male ruffs. *Proceedings of the Royal Society B:
#'   Biological Sciences*, **292**(2038), 20242225.
#' @name clusterTrack-deprecated
#' @keywords internal
#' @export
#' @examples
#' data(pesa56511)
#' x = as_tdbscan(pesa56511, time = "locationDate")
#' x = sf::st_transform(x, "+proj=eqearth")
#' z = tdbscan(track = x, eps = 6600, minPts = 8, maxLag = 6)
#' table(z$clustID)
as_tdbscan <- function(
  x,
  coords = c("longitude", "latitude"),
  time = "time",
  crs = 4326
) {
  .Deprecated("as_ctdf", package = "clusterTrack")

  o <- copy(x)

  setnames(o, time, "timestamp")
  setorder(o, timestamp)

  st_as_sf(o, coords = coords, crs = crs)
}


#' @rdname clusterTrack-deprecated
#' @export
tdbscan <- function(
  track,
  eps,
  minPts = 5,
  borderPoints = FALSE,
  maxLag = 6,
  minTenure
) {
  .Deprecated("cluster_track", package = "clusterTrack")

  stopifnot(inherits(track, 'sf'))

  x <- st_coordinates(track) |> data.table()
  setnames(x, c('x', 'y'))

  # Find the Fixed Radius Nearest Neighbors
  k <- dbscan::frNN(x, eps = eps, sort = FALSE)

  ids <- sapply(k$dist, length)
  ids <- rep(1:nrow(x), times = ids)
  z <- data.table(id = ids, ngb = unlist(k$id), dist = unlist(k$dist))

  # Define eps neighborhoods
  z[, n := .N + 1, by = id] # +1 because a pt is always in its own eps neighborhood

  z[, isCluster := n >= minPts]

  # border points search
  if (borderPoints) {
    z[!(isCluster), isCluster := z[!(isCluster), ngb] %in% z[(isCluster), id]]
  }

  z <- z[(isCluster)][, isCluster := NULL]

  z[, tc := abs(id - ngb)] # used latter for temporal contiguity

  # Identify clusters
  z[, c("i1", "i2") := list(pmin(id, ngb), pmax(id, ngb))] # id-s should be unique
  z <- unique(z, by = c('i1', 'i2'))[, ':='(i1 = NULL, i2 = NULL)]

  z[, id := as.character(id)] # so it will be  interpreted as symbolic vertex name by graph_from_edgelist
  z[, ngb := as.character(ngb)]

  g <- graph_from_edgelist(z[, .(id, ngb)] |> as.matrix(), directed = FALSE)

  # set graph attributes and subset
  g <- set_edge_attr(g, 'tc', value = z$tc)

  g <- subgraph_from_edges(g, E(g)[tc <= maxLag])

  gr <- components(g) |> groups()

  ids <- sapply(gr, length)
  ids <- rep(names(ids), times = ids) |> as.integer()
  o <- data.table(id = unlist(gr), clustID = ids)
  o[, id := as.numeric(id)]

  # add o to the original data
  x[, id := 1:.N]

  o <- merge(x, o, by = 'id', sort = FALSE, all.x = TRUE)

  # run dbscan on each cluster to check if they still hold
  o[
    !is.na(clustID),
    checkClust := dbscan::dbscan(
      cbind(x, y),
      eps = eps,
      minPts = minPts
    )$cluster !=
      0,
    by = clustID
  ]
  o[!(checkClust), clustID := NA]

  # minTenure
  if (!missing(minTenure)) {
    o[, datetime := track$timestamp]

    o[
      !is.na(clustID),
      tenure := difftime(max(datetime), min(datetime), units = 'hours'),
      by = clustID
    ]
    o[tenure < minTenure, clustID := NA]
  }

  # cleanup & re-order clust
  x[, id := NULL]
  o[, clustID := factor(clustID) |> fct_inorder() |> as.integer()]
  o[, .(id, clustID)]

  track$clustID <- o$clustID
  track
}
