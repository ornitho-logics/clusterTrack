#' Repair temporally adjacent clusters
#'
#' Merge spatial clusters.
#'
#' @param ctdf A CTDF object. Must contain an updated `cluster` column.
#' @return The input CTDF, with an updated (in-place) cluster` column.
#'
#' @export
#' @examples
#' data(mini_ruff)
#' ctdf = as_ctdf(mini_ruff)
#' slice_ctdf(ctdf)
#' cluster_repair(ctdf)
#'

.is_intersection <- function(ctdf, pc, next_pc) {
  ac = ctdf[.putative_cluster == pc, location] |>
    st_union() |>
    st_convex_hull()
  bc = ctdf[.putative_cluster == next_pc, location] |>
    st_union() |>
    st_convex_hull()

  o = st_intersects(ac, bc)
  any(lengths(o) > 0)
}


.cluster_repair <- function(ctdf) {
  olap = ctdf[!is.na(.putative_cluster), .(pc = .putative_cluster)] |> unique()
  olap[, next_pc := shift(pc, type = "lead")]

  olap[, is_overlap := .is_intersection(ctdf, pc, next_pc), by = .I]

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

  # insure temporal contiguity
  ctdf[,
    .putative_cluster := {
      f = nafill(.putative_cluster, type = "locf")
      b = nafill(.putative_cluster, type = "nocb")
      fifelse(f == b, f, .putative_cluster)
    }
  ]
}


cluster_repair <- function(ctdf) {
  .check_ctdf(ctdf)

  repeat {
    n_prev = max(ctdf$.putative_cluster, na.rm = TRUE)
    .cluster_repair(ctdf)
    if (max(ctdf$.putative_cluster, na.rm = TRUE) == n_prev) break
  }

  ctdf[,
    .putative_cluster := .as_inorder_int(.putative_cluster)
  ]
}
