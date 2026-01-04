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

.mcp <- function(x, p = 0.95) {
  d = st_distance(x, st_union(x) |> st_centroid())
  st_union(x[d <= quantile(d, p), ]) |>
    st_convex_hull()
}


.is_sorted_and_contiguous <- function(x) {
  o = unique(x)

  sorted = all(o == sort(o))
  contiguous = all(diff(o) == 1L)
  sorted && contiguous
}

.as_inorder_int <- function(x) {
  factor(x) |>
    fct_inorder() |>
    as.integer()
}
