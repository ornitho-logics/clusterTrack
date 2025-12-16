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
    ans = o > 0.001
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
