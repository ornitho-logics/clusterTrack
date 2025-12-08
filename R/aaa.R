#' @import foreach
#' @import sf data.table
#' @importFrom glue glue_data
#'
#' @importFrom igraph graph_from_edgelist set_edge_attr subgraph_from_edges E groups
#' @importFrom igraph graph_from_adj_list as_undirected components
#'
#' @importFrom dbscan     hdbscan
#' @importFrom spdep      poly2nb
#' @importFrom forcats    fct_inorder
#' @importFrom units      set_units
#' @importFrom dplyr      mutate ungroup rowwise lag filter select rename
#' @importFrom cli        cli_progress_bar cli_progress_update cli_progress_done cli_progress_output

utils::globalVariables(c('isCluster', 'datetime', 'tenure'))
NULL


# undocumented functions of general interest

.st_area_overlap_ratio <- function(i, j) {
  getA = function(x) {
    if (!inherits(x, "sfc") || length(x) == 0L || all(st_is_empty(x))) {
      return(NA_real_)
    }

    tryCatch(
      st_area(x) |> as.numeric(),
      error = function(e) NA_real_
    )
  }

  ai = getA(i)
  aj = getA(j)

  if (anyNA(c(ai, aj))) {
    return(0)
  }

  inter = tryCatch(
    st_intersection(i, j),
    error = function(e) st_sfc()
  )

  if (length(inter) == 0L || all(st_is_empty(inter))) {
    return(0)
  }

  aij = getA(inter)
  if (is.na(aij)) {
    return(0)
  }

  as.numeric(aij / pmin(ai, aj))
}


.mcp <- function(x, p = 0.95) {
  d = st_distance(x, st_union(x) |> st_centroid())
  st_union(x[d <= quantile(d, p), ]) |>
    st_convex_hull()
}
