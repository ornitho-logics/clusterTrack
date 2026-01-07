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
#' spatial_repair(ctdf)
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

spatial_repair <- function(ctdf, time_contiguity = TRUE) {
  .check_ctdf(ctdf)

  pb = cli::cli_progress_bar(
    total = NA,
    format = " {cli::pb_spin} {cli::pb_current} chunks processed [{cli::pb_elapsed}]",
    .envir = environment()
  )
  on.exit(cli::cli_progress_done(id = pb), add = TRUE)
  i = 0
  cli::cli_progress_update(id = pb, set = 0, force = TRUE)

  repeat {
    cli::cli_progress_update(id = pb, set = i - 1)

    n_prev = max(ctdf$.putative_cluster, na.rm = TRUE)

    .spatial_repair(ctdf, time_contiguity = time_contiguity)
    i = i + 1

    if (max(ctdf$.putative_cluster, na.rm = TRUE) == n_prev) break
  }

  ctdf[,
    .putative_cluster := .as_inorder_int(.putative_cluster)
  ]
}

#' @export
temporal_repair <- function(
  ctdf,
  trim = 0.01 # % on each tail that can be noise
) {
  x = ctdf[!is.na(.putative_cluster)]

  .trim_by_n = function(n, trim_max = trim, k = 1) {
    # keep at least k points potentially trimmed from each tail,
    # never exceed trim_max
    p = k / pmax(n, 1)
    pmin(trim_max, p)
  }

  dom = x[,
    {
      tr = .trim_by_n(.N, trim_max = trim)

      .(
        lo = quantile(timestamp, probs = tr, type = 8),
        hi = quantile(timestamp, probs = 1 - tr, type = 8),
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


#' @export
tail_repair <- function(ctdf) {
  .check_ctdf(ctdf)

  x = ctdf[!is.na(.putative_cluster)]

  o = x[,
    {
      tr =
        st_as_sf(.SD) |>
        mutate(location_prev = lag(location)) |>
        dplyr::filter(!st_is_empty(location_prev)) |>
        rowwise() |>
        mutate(
          track = rbind(
            st_coordinates(location_prev),
            st_coordinates(location)
          ) |>
            st_linestring() |>
            list() |>
            st_sfc()
        ) |>
        st_set_geometry("track")

      nc = st_crosses(tr) |> sapply(length)
      list(ncrosses = nc, .id = .id[-1])
    },
    by = .putative_cluster
  ]

  o = o[,
    {
      any_cross = ncrosses > 0

      if (!any(any_cross)) {
        list(.i = .id)
      } else {
        core_seg = cummax(any_cross) & rev(cummax(rev(any_cross)))
        i1 = which(core_seg)[1]
        i2 = tail(which(core_seg), 1)

        ids = .id
        drop = !(seq_along(ids) >= i1 & seq_along(ids) <= i2)

        list(.i = ids[drop])
      }
    },
    by = .putative_cluster
  ]

  ctdf[.id %in% x$.i, .putative_cluster := NA]

  ctdf[, .putative_cluster := .as_inorder_int(.putative_cluster)]
}
