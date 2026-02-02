#' @import data.table
#'
#' @importFrom  grDevices topo.colors
#' @importFrom  stats median quantile setNames start
#' @importFrom  utils tail timestamp
#'
#' @importFrom utils globalVariables
#' @importFrom stats sd
#'
#' @importFrom sf st_as_sf st_centroid st_convex_hull st_coordinates st_crosses st_crs
#' @importFrom sf st_distance st_geometry st_geometry st_geometry<- st_intersects st_is_empty st_is_within_distance
#' @importFrom sf st_length st_linestring st_set_crs st_set_geometry  st_sfc st_transform st_union
#'
#' @importFrom igraph graph_from_edgelist graph_from_data_frame set_edge_attr
#' @importFrom igraph  subgraph_from_edges E components groups
#'
#' @importFrom dbscan hdbscan frNN  kNN kNNdist tidy hullplot
#' @importFrom dplyr mutate ungroup rowwise lag select slice filter
#'
#' @importFrom forcats fct_inorder
#' @importFrom units set_units
#' @importFrom cli cli_alert cli_alert_warning cli_progress_bar cli_progress_update cli_progress_done pb_current pb_elapsed pb_spin
#' @importFrom geometry delaunayn

utils::globalVariables(c('isCluster', 'datetime', 'tenure'))
NULL


utils::globalVariables(c(
  "isCluster",
  "datetime",
  "tenure",
  ".",
  ".id",
  ".move_seg",
  ".putative_cluster",
  ".putative_cluster2",
  ".seg_id",
  "N",
  "X",
  "Y",
  "a",
  "b",
  "any_cross",
  "checkClust",
  "clustID",
  "cluster",
  "dist_to_next",
  "from",
  "geometry",
  "good_seg_id",
  "good_seg_len",
  "hi",
  "hi2",
  "lo",
  "lo2",
  "i.merged",
  "i.move_seg",
  "i.new_cluster",
  "i.new_putative_cluster",
  "i.putative_cluster",
  "i.seg_id",
  "id",
  "is_overlap",
  "lead_i",
  "len",
  "len_z",
  "location",
  "location_prev",
  "move_seg",
  "n",
  "n_crosses",
  "ncrosses",
  "new_cluster",
  "new_putative_cluster",
  "next_cluster",
  "next_cluster_is_nb",
  "next_geom",
  "next_pc",
  "ngb",
  "noise",
  "ov",
  "pc",
  "putative_cluster",
  "putative_cluster_local",
  "rid",
  "seg_id",
  "site_id",
  "size",
  "t_key",
  "tc",
  "to",
  "track",
  "tri_any_keep",
  "width",
  "x",
  "y"
))
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



.hdbscan2dt <- function(h){

    scores = data.table(
      cluster = names(h$cluster_scores) |> as.numeric(),
      score = as.numeric(h$cluster_scores)
    )

    x = data.table(
      cluster = h$cluster,
      membership_prob =  h$membership_prob,
      outlier_scores = h$outlier_scores
    )
   
    



}


.save_hdbscan_plot <- function(ii, h, xy, dir) {

  a = stringr::str_pad(min(ii),
    pad = "0",
    width = stringr::str_count(max(ii))
  )

  b = max(ii)

  nam = paste(a, b, sep = "-")
  path = paste0(dir, "/", nam,'.png')

  png(filename = path,
      width = 800,            
      height = 600,           
      res = 72)

  hullplot(xy, h$cluster, main =  nam, cex = 0.6)
  
  dev.off()

}
