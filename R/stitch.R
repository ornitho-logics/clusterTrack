#' Stitch clusters by spatial overlap across segments
#'
#' Iteratively merge spatial clusters in a CTDF based on the area overlap of
#' their convex hulls. Clusters whose hulls overlap above a specified ratio
#' are combined into a single cluster ID.
#'
#' @param ctdf A CTDF object. Must contain an updated `cluster` column.
#' @param overlap_threshold Numeric between 0 and 1; minimum area‐overlap ratio
#'                          required to merge adjacent clusters.
#'                          Clusters with overlap > threshold are combined.
#'#' @return The input CTDF, with an updated (in-place) cluster` column.
#'
#' @export
#' @examples
#' data(mini_ruff)
#' ctdf = as_ctdf(mini_ruff, s_srs = 4326, t_srs = "+proj=eqearth")
#' slice_ctdf(ctdf)
#' cluster_stitch(ctdf)
#' cluster_segments(ctdf)

#' data(pesa56511)
#' ctdf  = as_ctdf(pesa56511, time = "locationDate", s_srs = 4326, t_srs = "+proj=eqearth")
#' slice_ctdf(ctdf)
#' cluster_stitch(ctdf)
#' cluster_segments(ctdf)
#'
#' data(ruff143789)
#' ctdf = as_ctdf(ruff143789, time = "locationDate")
#' slice_ctdf(ctdf)
#' cluster_stitch(ctdf)

#' data(lbdo66862)
#' ctdf = as_ctdf(lbdo66862, time = "locationDate", s_srs = 4326, t_srs = "+proj=eqearth")
#' slice_ctdf(ctdf)
#' cluster_stitch(ctdf)
#' cluster_segments(ctdf)

cluster_stitch <- function(ctdf) {
  .check_ctdf(ctdf)

  if (
    !.is_sorted_and_contiguous(ctdf[.putative_cluster > 0, .putative_cluster])
  ) {
    stop(
      "Something went wrong! `.putative_cluster` is not sorted and contiguous anymore."
    )
  }

  olap_test <- function(pc, next_pc) {
    ac = st_coordinates(ctdf[.putative_cluster == pc, location])
    bc = st_coordinates(ctdf[.putative_cluster == next_pc, location])

    res = energy::eqdist.etest(
      rbind(ac, bc),
      sizes = c(nrow(ac), nrow(bc)),
      R = 999
    )

    if (inherits(res, "htest")) {
      o = res$p.value
    } else {
      o = 1
    }
    ans = o > 0.01
    ans
  }

  olap = ctdf[!is.na(.putative_cluster), .(pc = .putative_cluster)] |> unique()
  olap[, next_pc := shift(pc, type = "lead")]

  olap[, is_overlap := olap_test(pc, next_pc), by = .I]

  olap[,
    new_putative_cluster := cumsum(
      !shift(is_overlap, type = "lag", fill = FALSE)
    )
  ]

  setnames(olap, 'pc', '.putative_cluster')

  ctdf[
    olap,
    on = ".putative_cluster",
    .putative_cluster := i.new_putative_cluster
  ]
}


# outlier test for 1 and N

.lof_pvalue <- function(X, z) {
  k = ceiling(sqrt(nrow(X) + 1))

  X = as.matrix(X)
  stopifnot(ncol(X) == 2L)

  z = as.matrix(z)
  stopifnot(nrow(z) == 1L, ncol(z) == 2L)

  if (!is.null(colnames(X)) && !is.null(colnames(z))) {
    z = z[, colnames(X), drop = FALSE]
  }

  Xz = rbind(X, z)

  n = nrow(Xz)

  lof_all = dbscan::lof(Xz, minPts = k)
  lof_z = lof_all[n]
  lof_X = lof_all[-n]

  p.value = (sum(lof_X >= lof_z) + 1) / (length(lof_X) + 1)
  p.value
}

remove_outliers <- function(ctdf) {
  xy = ctdf[
    !is.na(.putative_cluster),
    .(st_coordinates(location), .id, .putative_cluster)
  ]

  fun <- function(xy) {
    # first
    pval = .lof_pvalue(xy[-1, .(X, Y)], xy[1, .(X, Y)])
    fi = xy[1, .(.id, is_cluster = pval > 0.05)]

    # last
    pval = .lof_pvalue(xy[-.N, .(X, Y)], xy[.N, .(X, Y)])
    la = xy[1, .(.id, is_cluster = pval > 0.05)]

    rbind(fi, la)
  }

  o = xy[, fun(.SD), by = .putative_cluster]
  o = o[!(is_cluster)]

  ctdf[.id %in% o$.id, .putative_cluster := NA]
}
