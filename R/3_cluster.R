#' Local clustering using DTSCAN
#'
#' Within each existing `.putative_cluster` region (typically produced by [slice_ctdf()]),
#' run [sf_dtscan()] on the points in that region to split it into one or more local spatial
#' subclusters. The resulting labels are combined with the parent `.putative_cluster` id and
#' written back to `.putative_cluster` in-place.
#'
#'
#' @param ctdf A `ctdf` object.
#' @param nmin Integer; passed as `min_pts` to [sf_dtscan()] when clustering within each
#'   `.putative_cluster` region.
#' @param area_z_min Numeric; passed to [sf_dtscan()] as `area_z_min`.
#' @param length_z_min Numeric; passed to [sf_dtscan()] as `length_z_min`.
#'
#' @return The input `ctdf`, invisibly, with `.putative_cluster` updated in-place.
#'
#' @seealso [sf_dtscan()]
#'
#' @export
#'
local_cluster_ctdf <- function(
  ctdf,
  nmin = 3,
  area_z_min = 0,
  length_z_min = 0
) {
  x = ctdf[!is.na(.putative_cluster)]
  x[, n := .N, by = .putative_cluster]
  x = x[n > nmin]

  x = x[,
    putative_cluster_local := {
      sf_dtscan(
        st_as_sf(.SD),
        id_col = '.id',
        min_pts = nmin,
        area_z_min = area_z_min,
        length_z_min = length_z_min
      )
    },
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
