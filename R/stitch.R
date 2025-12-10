.stitch <- function(ctdf, overlap_threshold = 0) {
  o = ctdf[
    .putative_cluster > 0,
    .(hull = st_union(location) |> st_convex_hull()),
    by = .putative_cluster
  ]

  if (nrow(o) > 1) {
    # prevents error on datasets with almost no .putative_clusters.
    o[, next_hull := hull[c(2:.N, NA_integer_)]]
    o[,
      overlap := .st_area_overlap_ratio(hull, next_hull),
      by = .putative_cluster
    ]

    o[, is_overlap := overlap > overlap_threshold]

    o[, stitch_id := rleid(is_overlap)]
    o[(!is_overlap), stitch_id := NA]

    o[, stitch_id := fcoalesce(stitch_id, shift(stitch_id))]

    o[,
      grp_key := fifelse(
        !is.na(stitch_id),
        paste0("s", stitch_id),
        paste0("c", .putative_cluster)
      )
    ]

    o[, .putative_cluster_stitched := .GRP, by = grp_key]

    ctdf[
      o,
      on = ".putative_cluster",
      .putative_cluster := .putative_cluster_stitched
    ]
  }
}


.stitch__ <- function(ctdf) {
  o = ctdf[
    .putative_cluster > 0
  ]

  if (!.is_sorted_and_contiguous(o$.putative_cluster)) {
    stop(
      "Something went wrong! `.putative_cluster` is not sorted and contiguous anymore."
    )
  }

  o[,
    next_puc := shift(unique(.putative_cluster), type = "lead")[
      match(.putative_cluster, unique(.putative_cluster))
    ]
  ]
  o = o[!is.na(next_puc)]

  etest_is_overlap <- function(pc) {
    ac = st_coordinates(o[.putative_cluster == pc, location])
    bc = st_coordinates(o[.putative_cluster == pc + 1, location])

    res = energy::eqdist.etest(
      rbind(ac, bc),
      sizes = c(nrow(ac), nrow(bc)),
      R = 999
    )
    res$p.value > 0.01
  }

  olap = o[, .(.putative_cluster)] |> unique()
  olap = olap[-.N]

  olap[,
    .(is_overlap = etest_is_overlap(.putative_cluster)),
    by = .putative_cluster
  ]

  o[,
    is_overlap := etest_is_overlap(location, next_loc),
    by = .putative_cluster
  ]

  o[, stitch_id := rleid(is_overlap)]
  o[(!is_overlap), stitch_id := NA]

  o[, stitch_id := fcoalesce(stitch_id, shift(stitch_id))]

  o[,
    grp_key := fifelse(
      !is.na(stitch_id),
      paste0("s", stitch_id),
      paste0("c", .putative_cluster)
    )
  ]

  o[, .putative_cluster_stitched := .GRP, by = grp_key]

  ctdf[
    o,
    on = ".putative_cluster",
    .putative_cluster := .putative_cluster_stitched
  ]
}

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

cluster_stitch <- function(ctdf, overlap_threshold = 0.1) {
  .check_ctdf(ctdf)

  repeat {
    old = ctdf$cluster

    .stitch(ctdf, overlap_threshold = overlap_threshold)

    if (identical(ctdf$cluster, old)) {
      break
    }
  }

  #
}
