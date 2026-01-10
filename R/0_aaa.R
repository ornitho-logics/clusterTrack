#' @import data.table
#'
#' @importFrom utils globalVariables
#' @importFrom stats sd
#'
#'
#' @importFrom sf st_as_sf st_centroid st_convex_hull st_coordinates st_crosses st_crs
#' @importFrom sf st_distance st_geometry st_geometry st_geometry<- st_intersects st_is_empty st_is_within_distance
#' @importFrom sf st_length st_linestring st_set_crs st_set_geometry  st_sfc st_transform st_union
#'
#' @importFrom igraph graph_from_edgelist graph_from_data_frame set_edge_attr
#' @importFrom igraph  subgraph_from_edges E components groups
#'
#' @importFrom dbscan hdbscan frNN dbscan
#' @importFrom dplyr mutate ungroup rowwise lag select slice filter
#'
#' @importFrom forcats fct_inorder
#' @importFrom units set_units
#' @importFrom cli cli_alert cli_progress_bar cli_progress_update cli_progress_done pb_current pb_elapsed pb_spin
#' @importFrom geometry delaunayn

utils::globalVariables(c('isCluster', 'datetime', 'tenure'))
NULL


# general undocumented functions

.is_sorted_and_contiguous <- function(x) {
  o = unique(x)

  sorted = all(o == sort(o))
  contiguous = all(diff(o) == 1)
  sorted && contiguous
}

.as_inorder_int <- function(x) {
  factor(x) |>
    fct_inorder() |>
    as.integer()
}
