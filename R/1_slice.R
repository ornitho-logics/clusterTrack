# Homogeneous = no meaningful multi-modality (2 clusters but one is tiny)

.has_clusters <- function(x, minPts = 5) {
  n = nrow(x)
  if (n <= minPts) {
    return(FALSE)
  }

  xy = x[, st_coordinates(location)]

  o = hdbscan(xy, minPts = minPts)
  

  o = o |>
    tidy() |>
    setDT()
  o = o[!(noise)]
  o = o[size >= minPts]

  if (nrow(o) < 2) {
    return(FALSE)
  }

  nrow(o) > 1
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

.split_by_longest_movement <- function(ctdf, deltaT) {
  .prepare_segs(ctdf, deltaT = deltaT)

  split(ctdf[.move_seg == 0], by = ".seg_id")
}

#' Slice a CTDF into putative clusters using temporal continuity and spatial clustering
#'
#' Identifies spatially heterogeneous regions (via HDBSCAN on point coordinates) and, for those regions,
#' recursively subdivides the track into temporally continuous movement segments. Subdivision continues
#' until a region is spatially homogeneous (no evidence for multiple clusters) .
#'
#' This function updates a \code{ctdf} in-place.
#'
#' @param ctdf A \emph{CTDF} object.
#' @param nmin Integer;  smallest size of a putative cluster.
#' @param deltaT Numeric; maximum allowable time gap (in days) between segment endpoints for intersections
#'   to  consider them continuous.
#'
#' @return Invisibly returns \code{ctdf}, with \code{.putative_cluster} updated in-place.
#'
#' @details
#' Internally, candidate regions are queued. Regions that show evidence for multiple clusters are split by movement segmentation; otherwise they are retained as a single putative cluster.
#'
#' @seealso \code{\link[dbscan]{hdbscan}}
#'
#' @export
#'
#' @examples
#' data(mini_ruff)
#' ctdf = as_ctdf(mini_ruff, s_srs = 4326, t_srs = "+proj=eqearth")
#' ctdf = slice_ctdf(ctdf)
#'
#' data(pesa56511)
#' ctdf = as_ctdf(pesa56511, time = "locationDate", s_srs = 4326, t_srs = "+proj=eqearth")
#' ctdf = slice_ctdf(ctdf)

slice_ctdf <- function(ctdf, nmin = 5, deltaT) {
  .check_ctdf(ctdf)
  ctdf[, .putative_cluster := NA]

  if (missing(deltaT)) {
    deltaT = 1e+05
  }

  queue = list(ctdf)
  res = list()

  head = 1

  if (interactive()) {
    pb = cli::cli_progress_bar(
      total = NA,
      format = " {cli::pb_spin} {cli::pb_current} segments processed [{cli::pb_elapsed}]",
      .envir = environment()
    )
    on.exit(cli::cli_progress_done(id = pb), add = TRUE)
  }

  while (head <= length(queue)) {
    current = queue[[head]]
    head = head + 1

    if (interactive()) {
      cli::cli_progress_update(id = pb, set = head - 1)
    }

    if (nrow(current) <= nmin) {
      next # back to head, no need to test for clusters
    }

    if (current |> .has_clusters()) {
      new_chunks = .split_by_longest_movement(ctdf = current, deltaT = deltaT)
      if (length(new_chunks) > 0) {
        n0 = length(queue)
        n1 = length(new_chunks)
        # add empty slots at the end of queue:
        length(queue) = n0 + n1
        queue[(n0 + 1):(n0 + n1)] = new_chunks
      }
    } else {
      res[[length(res) + 1]] = current
    }
  }

  if (!length(res)) {
    warning("No valid putative clusters found!")
    set(ctdf, j = ".putative_cluster", value = NA)
    return(invisible(ctdf))
  }

  for (k in seq_along(res)) {
    res[[k]][, .putative_cluster := k]
  }

  out = rbindlist(res, use.names = TRUE)

  setorder(out, .id)

  out[, new_putative_cluster := .as_inorder_int(.putative_cluster)]

  out = out[, .(.id, new_putative_cluster)]
  setkey(out, .id)

  ctdf[out, .putative_cluster := i.new_putative_cluster]
}
