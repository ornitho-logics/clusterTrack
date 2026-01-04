.zscore_inverse = function(v) {
  m = mean(v)
  s = stats::sd(v)
  if (!is.finite(s) || s == 0) {
    return(rep.int(Inf, length(v)))
  }
  (m - v) / s
}


.unique_xy = function(
  x,
  id_col = NULL
) {
  xy = sf::st_coordinates(x)

  has_id = !is.null(id_col) && (id_col %chin% names(x))
  idv = if (has_id) x[[id_col]] else NULL

  dt = data.table(
    rid = seq_len(nrow(x)),
    x = as.numeric(xy[, 1]),
    y = as.numeric(xy[, 2])
  )
  if (has_id) {
    dt[, id := idv]
  }

  setkey(dt, x, y)
  dt[, site_id := .GRP, by = .(x, y)]

  unique_sites = dt[, .(x = x[1], y = y[1], mult = .N), by = site_id][order(
    site_id
  )]

  site_id_by_row =
    if (has_id) {
      setkey(dt, id)
      dt[x, on = setNames(id_col, "id"), site_id]
    } else {
      setorder(dt, rid)
      dt[, site_id]
    }

  list(unique_sites = unique_sites, site_id_by_row = site_id_by_row)
}

.delaunay_tri = function(unique_sites) {
  pts = as.matrix(unique_sites[, .(x, y)])
  pts[, 1] = pts[, 1] - mean(pts[, 1])
  pts[, 2] = pts[, 2] - mean(pts[, 2])

  tri = suppressWarnings(geometry::delaunayn(pts))
  used = unique(as.vector(tri))
  if (length(used) < nrow(pts)) {
    tri = suppressWarnings(geometry::delaunayn(pts, options = "Qt Qc Qz Qbb"))
    used = unique(as.vector(tri))
  }
  if (length(used) < nrow(pts)) {
    tri = suppressWarnings(geometry::delaunayn(
      pts,
      options = "Qt Qc Qz Qbb QJ"
    ))
  }

  tri
}


.prune_delaunay_edges = function(
  tri,
  unique_sites,
  area_z_min = 0,
  length_z_min = 0
) {
  i1 = tri[, 1]
  i2 = tri[, 2]
  i3 = tri[, 3]
  x = unique_sites$x
  y = unique_sites$y

  ax = x[i1]
  ay = y[i1]
  bx = x[i2]
  by = y[i2]
  cx = x[i3]
  cy = y[i3]

  tri_area = abs(ax * (by - cy) + bx * (cy - ay) + cx * (ay - by)) / 2

  tri_keep = .zscore_inverse(tri_area |> log()) >= area_z_min

  e12a = pmin.int(i1, i2)
  e12b = pmax.int(i1, i2)
  e23a = pmin.int(i2, i3)
  e23b = pmax.int(i2, i3)
  e31a = pmin.int(i3, i1)
  e31b = pmax.int(i3, i1)

  tri_edges = rbindlist(list(
    data.table(a = e12a, b = e12b, t = seq_len(nrow(tri))),
    data.table(a = e23a, b = e23b, t = seq_len(nrow(tri))),
    data.table(a = e31a, b = e31b, t = seq_len(nrow(tri)))
  ))

  tri_edges[, len := sqrt((x[a] - x[b])^2 + (y[a] - y[b])^2)]

  edge_incident_to_kept_triangle = tri_edges[,
    .(tri_any_keep = any(tri_keep[t])),
    by = .(a, b)
  ]

  unique_edges = unique(tri_edges[, .(a, b, len)])
  unique_edges[, len_z := .zscore_inverse(len |> log())]

  unique_edges[edge_incident_to_kept_triangle, on = .(a, b)][
    tri_any_keep == TRUE & len_z >= length_z_min,
    .(a, b)
  ]
}

.build_adjacency_list = function(kept_edges, n_sites) {
  adj = vector("list", n_sites)
  if (nrow(kept_edges) == 0) {
    return(adj)
  }

  directed = rbindlist(list(
    kept_edges[, .(from = a, to = b)],
    kept_edges[, .(from = b, to = a)]
  ))
  setorder(directed, from)

  grouped = directed[, .(to = list(as.integer(to))), by = from]
  adj[grouped$from] = grouped$to
  adj
}

.cluster_on_pruned_graph = function(adj, site_multiplicity, min_pts) {
  deg = lengths(adj)
  eff = deg + (as.integer(site_multiplicity) - 1)

  site_cluster = integer(length(adj))
  cluster_id = 0

  for (v in which(eff >= min_pts)) {
    if (site_cluster[[v]] != 0) {
      next
    }
    cluster_id = cluster_id + 1

    stack = v
    while (length(stack)) {
      p = stack[[length(stack)]]
      stack = stack[-length(stack)]

      if (site_cluster[[p]] != 0) {
        next
      }
      site_cluster[[p]] = cluster_id

      if (eff[[p]] >= min_pts) {
        nb = adj[[p]]
        if (length(nb)) stack = c(stack, nb[site_cluster[nb] == 0])
      }
    }
  }

  site_cluster
}


#'  DTSCAN: Delaunay Triangulation-Based Spatial Clustering.
#'
#' Runs a DTSCAN-style clustering pipeline using a Delaunay triangulation of point coordinates,
#' global pruning based on z-scored triangle areas and edge lengths, and MinPts graph expansion.
#' Returns only the cluster labels vector aligned to the input rows.
#'
#' @param x An `sf` object with POINT geometry.
#' @param min_pts Minimum neighbour count for a point to be treated as a core point.
#' Neighbours are the sites directly connected by kept Delaunay edges after pruning.
#' If multiple input points share exactly the same coordinates, they are collapsed to one site and
#' their multiplicity contributes to this count.
#' @param area_z_min Threshold (in SD units) on the inverse z-score of triangle areas used for pruning.
#' Larger thresholds keep only progressively smaller-than-average triangles and prune more edges. Default to 0.
#' @param length_z_min Threshold (in SD units) on the inverse z-score of Delaunay edge lengths used for pruning. Larger thresholds keep only progressively shorter-than-average edges and prune more connections.

#' @param id_col Optional character scalar naming a unique identifier column in `x` used to align output.
#'   If `NULL` or missing from `x`, output is aligned by current row order.

#' @return An integer vector of cluster labels of length `nrow(x)`.
#'   `0` indicates noise/unassigned; positive integers are cluster ids.
#'
#' @details
#' Identical coordinates are collapsed before triangulation; their multiplicity contributes
#' to MinPts via `effective_degree = degree + (mult - 1)`.
#' #' Cluster labels are produced by starting a new cluster at each unassigned core site
#' (a site meeting the MinPts rule) and iteratively visiting all sites reachable through
#' pruned Delaunay edges from that seed; the cluster id is assigned to every visited site.

#'
#' @references
#' Kim, J., & Cho, J. (2019). Delaunay triangulation-based spatial clustering technique for enhanced adjacent boundary detection and segmentation of LiDAR 3D point clouds. Sensors, 19(18), 3926.
#' doi:10.3390/s19183926

#' @export
#' @examples
#' data(mini_ruff)
#' x = as_ctdf(mini_ruff)[.id %in% 90:177]
#' x[,
#'   cluster := sf_dtscan(
#'     st_as_sf(x),
#'     id_col = ".id",
#'     min_pts = 5,
#'     area_z_min = 0,
#'     length_z_min = 0
#'   )
#' ]

sf_dtscan = function(
  x,
  min_pts = 5,
  area_z_min = 0,
  length_z_min = 0,
  id_col = NULL
) {
  sites = .unique_xy(x, id_col = id_col)
  unique_sites = sites$unique_sites
  site_id_by_row = sites$site_id_by_row

  tri = .delaunay_tri(unique_sites)

  kept_edges = .prune_delaunay_edges(
    tri,
    unique_sites,
    area_z_min = area_z_min,
    length_z_min = length_z_min
  )
  adj = .build_adjacency_list(kept_edges, n_sites = nrow(unique_sites))

  site_cluster = .cluster_on_pruned_graph(
    adj,
    site_multiplicity = unique_sites$mult,
    min_pts = as.integer(min_pts)
  )

  site_cluster[site_id_by_row]
}
