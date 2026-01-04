###
.temporal_merge = function(
  cluster,
  time,
  trim = 0.05, # ~5% on each tail can be noise
  contain_min = 0.60 # least 60% of the shorter interval overlaps.
) {
  cl0 = as.integer(cluster)

  tn = as.numeric(time)

  ok = cl0 > 0
  if (!any(ok)) {
    return(cl0)
  }

  X = data.table(i = which(ok), cl = cl0[ok], t = tn[ok])

  dom = X[,
    {
      lo = quantile(
        t,
        probs = trim,
        type = 8,
        names = FALSE,
        na.rm = TRUE
      ) |>
        as.numeric()

      hi = quantile(
        t,
        probs = 1 - trim,
        type = 8,
        names = FALSE,
        na.rm = TRUE
      ) |>
        as.numeric()

      list(
        lo = lo,
        hi = hi,
        width = pmax(hi - lo, 0),
        t_key = median(t, na.rm = TRUE)
      )
    },
    by = cl
  ][order(cl)]

  if (nrow(dom) == 1) {
    out = cl0
    out[out > 0] = 1
    return(out)
  }

  a = dom[, .(cl, lo, hi, width, t_key)]
  b = copy(a)
  setnames(
    b,
    c("cl", "lo", "hi", "width", "t_key"),
    c("cl2", "lo2", "hi2", "width2", "t_key2")
  )

  setkey(a, lo, hi)
  setkey(b, lo2, hi2)

  pairs = data.table::foverlaps(
    x = a,
    y = b,
    by.x = c("lo", "hi"),
    by.y = c("lo2", "hi2"),
    type = "any",
    mult = "all",
    nomatch = 0L
  )[cl < cl2]

  if (nrow(pairs) == 0L) {
    map = dom[, .(cl, merged = .I)]
  } else {
    pairs[, let(
      ov = pmax(0, pmin(hi, hi2) - pmax(lo, lo2)),
      denom = pmin(width, width2)
    )]

    pairs[, let(
      contain = fifelse(denom > 0, ov / denom, 0)
    )]

    edges = pairs[
      contain >= contain_min,
      .(from = as.character(cl), to = as.character(cl2))
    ]

    if (nrow(edges) == 0) {
      map = dom[, .(cl, merged = .I)]
    } else {
      g = igraph::graph_from_data_frame(
        edges,
        directed = FALSE,
        vertices = data.table(name = as.character(dom$cl))
      )
      cc = igraph::components(g)$membership
      map = data.table(
        cl = as.integer(names(cc)),
        merged = as.integer(cc)
      )[order(cl)]
    }
  }

  dom2 = dom[map, on = .(cl)]
  merged_dom = dom2[,
    .(
      lo = min(lo),
      hi = max(hi),
      t_key = stats::median(t_key, na.rm = TRUE)
    ),
    by = merged
  ][order(t_key, lo)]
  merged_dom[, relabeled := seq_len(.N)]

  map2 = dom2[merged_dom, on = .(merged), .(cl, relabeled)]
  setkey(map2, cl)

  out = cl0
  out[X$i] = map2$relabeled[match(X$cl, map2$cl)]
  out
}


#' @export
local_cluster_ctdf <- function(
  ctdf,
  nmin = 3,
  area_z_min = 0,
  length_z_min = 0,
  trim = 0.05,
  contain_min = 0.60
) {
  x = ctdf[!is.na(.putative_cluster)]

  x = x[,
    putative_cluster_local := sf_dtscan(
      st_as_sf(.SD),
      id_col = '.id',
      min_pts = nmin,
      area_z_min = area_z_min,
      length_z_min = length_z_min
    ) |>
      .temporal_merge(timestamp),
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
}
