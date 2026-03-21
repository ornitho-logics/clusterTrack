.is_intersection.geom <- function(ctdf, pc, next_pc) {
  ac = ctdf[.putative_cluster == pc, location] |>
    st_union() |>
    st_convex_hull()

  bc = ctdf[.putative_cluster == next_pc, location] |>
    st_union() |>
    st_convex_hull()

  o = st_intersects(ac, bc)

  any(lengths(o) > 0)
}

.is_intersection.knn = function(ctdf, pc, next_pc) {
  x = ctdf[.putative_cluster %chin% c(pc, next_pc)]
  n = nrow(x)
  if (n < 4) {
    return(FALSE)
  }

  xy = x[, st_coordinates(location)]
  xy = as.matrix(xy)

  y = as.integer(x$.putative_cluster == pc) + 1
  n_min = min(tabulate(y))
  if (n_min < 3) {
    return(FALSE)
  }

  k = sqrt(n) |> floor()
  k = min(k, 15, n - 1, n_min - 1)
  k = max(k, 2)

  nn = dbscan::kNN(xy, k = k)$id

  neigh = matrix(y[nn], nrow = n, ncol = k)
  self = matrix(y, nrow = n, ncol = k)
  mix = mean(neigh != self)

  p = mean(y == 1)
  mix_exp = 2 * p * (1 - p)

  o = mix >= 0.6 * mix_exp

  o
}

.is_intersection <- function(ctdf, pc, next_pc) {
  if (.is_intersection.geom(ctdf, pc, next_pc)) {
    return(TRUE)
  } else {
    return(.is_intersection.knn(ctdf, pc, next_pc))
  }
}

.spatial_repair <- function(ctdf, time_contiguity) {
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
  if (time_contiguity) {
    ctdf[,
      .putative_cluster := {
        f = nafill(.putative_cluster, type = "locf")
        b = nafill(.putative_cluster, type = "nocb")
        fifelse(f == b, f, .putative_cluster)
      }
    ]
  }
}


.find_loose_ends <- function(x) {
  seg = as_ctdf_track(x)

  n = nrow(seg)
  hits = st_intersects(seg)

  statrk = rep(FALSE, n)
  endtrk = rep(FALSE, n)

  left = 1
  right = n

  repeat {
    moved = FALSE

    if (left > right) {
      break
    }

    i = left
    ignore_start = hits[[i]]
    ignore_start = ignore_start[
      ignore_start < right &
        !(ignore_start %in% c(i - 1, i, i + 1))
    ]

    if (!length(ignore_start)) {
      statrk[i] = TRUE
      left = left + 1
      moved = TRUE
    }

    if (left > right) {
      break
    }

    i = right
    ignore_end = hits[[i]]
    ignore_end = ignore_end[
      ignore_end > left &
        !(ignore_end %in% c(i - 1, i, i + 1))
    ]

    if (!length(ignore_end)) {
      endtrk[i] = TRUE
      right = right - 1
      moved = TRUE
    }

    if (!moved) break
  }

  o = data.table(
    .id = seg$.id,
    statrk = statrk,
    endtrk = endtrk
  )

  o = rbind(
    data.table(
      .id = 1,
      statrk = o[.id == 2, statrk],
      endtrk = o[.id == 2, endtrk]
    ),
    o
  )

  o[, rmv := any(statrk, endtrk), by = .I]
  o[, .(.id, rmv)]
}

#' Repair spatially overlapping adjacent putative clusters
#'
#' Iteratively merges temporally adjacent putative clusters whose convex hulls intersect.
#' This operates on the `.putative_cluster` column created by [slice_ctdf()] and updates it in-place.
#'
#' If `time_contiguity = TRUE`, missing `.putative_cluster` values between identical
#' forward- and backward-filled labels are filled, so each cluster becomes
#' temporally contiguous (short spatial outliers inside a cluster are absorbed).
#'
#' @param ctdf A `ctdf` object. Must contain `.putative_cluster` (typically produced by [slice_ctdf()]).
#' @param time_contiguity Logical; if `TRUE`, enforce temporal contiguity within clusters by filling
#' internal gaps as described above. Default is `TRUE`.
#'
#' @return The input `ctdf`, invisibly, with `.putative_cluster` updated in-place.
#'

spatial_repair <- function(ctdf, time_contiguity = TRUE) {
  .check_ctdf(ctdf)

  repeat {
    n_prev = max(ctdf$.putative_cluster, na.rm = TRUE)

    .spatial_repair(ctdf, time_contiguity = time_contiguity)

    if (max(ctdf$.putative_cluster, na.rm = TRUE) == n_prev) break
  }

  ctdf[,
    .putative_cluster := .as_inorder_int(.putative_cluster)
  ]
}


#' Repair putative clusters by trimming track tails
#'
#' Removes leading and trailing "tail" portions of each `.putative_cluster` based on self-crossings
#' of the within-cluster track. The function drops commuting legs at the both beginning and end of
#' a cluster.
#'
#' @param ctdf A `ctdf` object.
#'
#' @return The input `ctdf`, invisibly, with `.putative_cluster` updated in-place.
#'
#' @example
#'
#' data(mini_ruff)
#' x = as_ctdf(mini_ruff)
#' x = x[.id < 20][, .putative_cluster := 1]
#' tail_repair(x)
#' @export
tail_repair <- function(ctdf, nmin = 3) {
  .check_ctdf(ctdf)

  z = ctdf[!is.na(.putative_cluster)]
  z = split(z, f = z$.putative_cluster)

  o = lapply(z, .find_loose_ends) |> rbindlist()
  o = o[(rmv)]

  ctdf[.putative_cluster %in% o$rmv, .putative_cluster := NA]

  ctdf[,
    .putative_cluster := .as_inorder_int(.putative_cluster)
  ]
}


#' Repair temporally overlapping putative clusters
#'
#' Merges `.putative_cluster` labels whose (trimmed) time domains overlap.
#' For each putative cluster, a time interval `[lo, hi]` is estimated from the
#' `timestamp` distribution after trimming a small fraction from each tail to
#' reduce sensitivity to single-point temporal outliers. Any clusters with
#' overlapping intervals are merged (transitively) using connected components on
#' an overlap graph.
#'
#' @param ctdf A `ctdf` object. Must contain `timestamp` and `.putative_cluster`.
#' @param trim Numeric in `[0, 0.5)`. Maximum fraction trimmed from each tail when
#'   estimating each cluster's time domain.
#'
#' @details
#' Clusters are merged using connected components of an *interval overlap graph*:
#' an undirected graph with one vertex per `.putative_cluster`, and an edge
#' between two vertices  if their trimmed time intervals overlap.
#'
#' @return The input `ctdf`, invisibly, with `.putative_cluster` updated in-place.
#'
#' @export
temporal_repair <- function(ctdf, trim = 0.01) {
  x = ctdf[!is.na(.putative_cluster)]

  dom = x[,
    {
      .(
        lo = quantile(timestamp, probs = trim, type = 8),
        hi = quantile(timestamp, probs = 1 - trim, type = 8),
        t_key = median(timestamp)
      )
    },
    by = .putative_cluster
  ]
  dom[, width := pmax(hi - lo, 0)]

  dom2 = copy(dom)
  setnames(dom2, paste0(names(dom), '2'))

  setkey(dom, lo, hi)
  setkey(dom2, lo2, hi2)

  pairs =
    foverlaps(
      x = dom,
      y = dom2,
      by.x = c("lo", "hi"),
      by.y = c("lo2", "hi2"),
      type = "any",
      mult = "all",
      nomatch = 0
    )[.putative_cluster < .putative_cluster2]

  pairs[, ov := pmax(0, pmin(hi, hi2) - pmax(lo, lo2))]

  edges = pairs[
    ov > 0,
    .(
      from = .putative_cluster,
      to = .putative_cluster2
    )
  ]

  g = igraph::graph_from_data_frame(
    edges,
    directed = FALSE,
    vertices = data.table(name = dom$.putative_cluster)
  )

  cc = igraph::components(g)$membership

  map = data.table(
    .putative_cluster = names(cc) |> as.integer(),
    merged = cc
  )[order(.putative_cluster)]

  dom[map, on = .(.putative_cluster), new_putative_cluster := i.merged]

  setorder(dom, t_key, lo)

  dom[, new_putative_cluster := .as_inorder_int(new_putative_cluster)]
  dom[, new_putative_cluster := new_putative_cluster + min(.putative_cluster)]

  ctdf[
    dom,
    on = .(.putative_cluster),
    .putative_cluster := new_putative_cluster
  ]

  ctdf[,
    .putative_cluster := .as_inorder_int(.putative_cluster)
  ]
}
