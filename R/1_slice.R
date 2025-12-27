.has_clusters <- function(
  ctdf,
  minPts = 3
) {
  n = nrow(ctdf)
  if (n <= minPts) {
    return(FALSE)
  }

  o = hdbscan(ctdf[, st_coordinates(location)], minPts = minPts)

  ncl = length(o$cluster_scores)

  ncl > 1
}


.prepare_segs <- function(ctdf, deltaT) {
  ctdf[, let(.move_seg = NA, .seg_id = NA)]

  segs =
    ctdf |>
    as_ctdf_track() |>
    mutate(len = st_length(track) |> set_units("km") |> as.numeric())

  crosses = st_crosses(segs)

  setDT(segs)

  pruned_crosses = lapply(seq_along(crosses), function(i) {
    j = crosses[[i]]

    dfs = difftime(segs$start[j], segs$stop[i], units = "days") |> abs()
    j[dfs <= deltaT] # keep only valid intersections within DT
  })

  segs[, n_crosses := lengths(pruned_crosses)]

  segs[,
    n_crosses := pmin(n_crosses, shift(n_crosses, type = "lag"), na.rm = TRUE)
  ]

  segs[, any_cross := n_crosses > 0]

  segs[, good_seg_id := rleid(any_cross)]

  segs[(any_cross), good_seg_id := NA]

  segs[!is.na(good_seg_id), good_seg_len := sum(len), by = good_seg_id]

  is_good_seg <- function(x) {
    if (all(is.na(x)) || length(x) == 0) {
      return(logical(length = length(x)))
    }

    o = max(x, na.rm = TRUE) == x

    o[is.na(o)] <- FALSE
    o
  }

  segs[, move_seg := is_good_seg(good_seg_len)]

  segs[, seg_id := rleid(move_seg)]

  setkey(segs, .id)

  ctdf[segs, .move_seg := i.move_seg]
  ctdf[segs, .seg_id := i.seg_id]
}


.split_by_maxlen <- function(ctdf, deltaT) {
  .prepare_segs(ctdf, deltaT = deltaT)

  split(ctdf[.move_seg == 0], by = ".seg_id")
}


#' Segment and filter a CTDF by temporal continuity and spatial clustering
#'
#' Recursively splits a CTDF into putative cluster regions. The split stops when a region is homogenous
#'  (established via HDBSCAN).
#'
#' @param ctdf A CTDF object.
#' @param deltaT Numeric; maximum allowable gap (in days) between segment
#'   endpoints to consider them continuous.
#' @return The input CTDF, updated (in-place) with an integer
#'   \code{.putative_cluster} column indicating bout membership.
#'
#' @export
#' @examples
#' data(mini_ruff)
#' ctdf = as_ctdf(mini_ruff, s_srs = 4326, t_srs = "+proj=eqearth")
#' ctdf = slice_ctdf(ctdf)
#'
#' data(pesa56511)
#' ctdf = as_ctdf(pesa56511, time = "locationDate", s_srs = 4326, t_srs = "+proj=eqearth")
#' slice_ctdf(ctdf )

slice_ctdf <- function(ctdf, deltaT = 30, nmin = 5) {
  .check_ctdf(ctdf)

  ctdf[, .putative_cluster := NA]

  # Initialize
  result = list()
  queue = .split_by_maxlen(ctdf = ctdf, deltaT = deltaT)

  i = 1

  while (i <= length(queue)) {
    current = queue[[i]]

    if (current |> .has_clusters()) {
      new_chunks = .split_by_maxlen(ctdf = current, deltaT = deltaT)
      queue = c(queue, new_chunks)
    } else {
      if (nrow(current) > 1) {
        result = c(result, list(current))
      }
    }

    i = i + 1
  }

  # assign segment id
  for (i in seq_along(result)) {
    result[[i]][, .putative_cluster := i]
  }

  if (length(result) == 0) {
    warning("No valid putative clusters found!")
    set(ctdf, j = ".putative_cluster", value = NA)
    return(invisible(ctdf))
  }

  out = rbindlist(result)

  setorder(out, .id)
  out[,
    putative_cluster := .as_inorder_int(.putative_cluster)
  ]
  out = out[, .(.id, putative_cluster)]
  setkey(out, .id)

  ctdf[out, .putative_cluster := i.putative_cluster]
}
