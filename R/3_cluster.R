#' @export
local_cluster_ctdf <- function(
  ctdf,
  nmin = 3,
  area_z_min = 0,
  length_z_min = 0,
  trim = 0.1
) {
  x = ctdf[!is.na(.putative_cluster)]

  x = x[,
    putative_cluster_local := sf_dtscan(
      st_as_sf(.SD),
      id_col = '.id',
      min_pts = nmin,
      area_z_min = area_z_min,
      length_z_min = length_z_min
    ),
    by = .putative_cluster
  ]

  x[,
    putative_cluster := paste(
      .putative_cluster,
      putative_cluster_local,
      sep = "_"
    ) |>
      forcats::fct_inorder() |>
      as.integer()
  ]

  x[putative_cluster_local == 0, putative_cluster := NA]

  out = x[, .(.id, putative_cluster)]
  setkey(out, .id)

  ctdf[out, .putative_cluster := i.putative_cluster]

  ctdf[,
    .putative_cluster := .as_inorder_int(.putative_cluster)
  ]
}


#' @export
ctdf_temporal_merge <- function(
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
}
