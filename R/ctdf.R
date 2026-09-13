#' Coerce an object to clusterTrack data format
#'
#' S3 generic for converting objects into a `ctdf`.
#'
#' See [as_ctdf.data.frame()] for coordinate columns and [as_ctdf.sf()] for
#' existing POINT geometries with a source CRS.
#'
#' @param x An object to convert.
#' @param ... Passed to methods.
#'
#' @return
#' A `ctdf`: a timestamp-ordered `data.table` with an `sfc_POINT`
#' geometry column named `location`.
#'
#' @section ctdf columns:
#'
#' A `ctdf` contains the following standardized columns:
#'
#' - `timestamp`: Observation time. Rows are ordered by this column when the
#'   `ctdf` is created.
#'
#' - `location`: Point geometry in the target coordinate reference system.
#'
#' - `cluster`: Final cluster assignment. It is initialized to `NA`.
#'   [cluster_track()] copies the final `.putative_cluster` assignments here,
#'   with unassigned locations encoded as `0`. Positive integers identify
#'   clusters. [aggregate_ctdf()] may subsequently merge and renumber these
#'   clusters.
#'
#' - `lof`: Local Outlier Factor score for each location. It is initialized
#'   to `NA` and populated by [ctdf_lof()] for locations with `cluster > 0`.
#'   Unassigned locations retain `NA`.
#'
#' - `.id`: Internal row identifier assigned after ordering by
#'   `timestamp`. It does not refer to the row number in the original input.
#'
#' - `.move_seg`: Internal working column used by [slice_ctdf()] while
#'   identifying movement segments during recursive track segmentation.
#'   It is initialized to `NA` and may be overwritten during clustering.
#'   Its value should not be treated as a persistent clustering result.
#'
#' - `.seg_id`: Internal working identifier for consecutive segmentation
#'   regions created together with `.move_seg` by [slice_ctdf()]. It is
#'   initialized to `NA` and may be overwritten during recursive segmentation.
#'
#' - `.putative_cluster`: Internal working cluster label. It is initialized
#'   to `NA`, assigned by [slice_ctdf()], and subsequently modified by the
#'   spatial, local-clustering, pruning, and temporal-repair steps of
#'   [cluster_track()]. `NA` are locations not currently assigned to a
#'   putative cluster. This column represents intermediate clustering state
#'   and should not be interpreted as the final cluster assignment.
#'
#'
#' The columns `.id`, `.move_seg`, `.seg_id`, `.putative_cluster`,
#' are internal working columns and are overwritten when constructing
#' a `ctdf`. They are exposed primarily to make the state of the clustering
#' workflow inspectable and are mainly relevant when running or examining the
#' pipeline step by step. Users calling [cluster_track()] normally do not need
#' to modify these columns directly.
#'
#' @seealso [as_ctdf.data.frame()], [as_ctdf.sf()], [cluster_track()]
#' @export
as_ctdf <- function(x, ...) {
  UseMethod("as_ctdf")
}


#' @export
as_ctdf.default <- function(x, ...) {
  stop("No method for objects of class ", class(x))
}


#' Coerce an object to clusterTrack data format
#'
#' Converts an object with spatial coordinates and a timestamp column
#' to the `data.table` format with an `sf` geometry column used by clusterTrack.
#'
#' @param x       A `data.frame` object.
#' @param coords  Character vector of length 2 specifying the coordinate column names.
#'                Defaults to `c("longitude", "latitude")`.
#' @param time    Name of the POSIXt time column. Will be renamed to `"timestamp"` internally.
#' @param s_srs   Source spatial reference. Default is EPSG:4326
#' @param t_srs   Target spatial reference passed to [sf::st_transform()]. Default is "+proj=eqearth".
#' @param ...     Currently unused
#'
#' @return An object of class `ctdf` (inherits from `data.table` and `data.frame`),
#' with an `sfc_POINT` geometry column named `location`.
#'
#' @details
#' Rows are sorted by timestamp, geometry is transformed to `t_srs`, and
#' clusterTrack columns are initialized. Existing reserved columns are overwritten
#' with a warning.
#'
#' The converted object is checked for duplicate locations with the same timestamp
#' and temporal gaps exceeding `getOption("clusterTrack.max_gap", 24)` hours.
#' Duplicate warnings identify row positions in the returned, timestamp-sorted `ctdf`.
#'
#' @seealso [as_ctdf()], [as_ctdf.sf()]
#'
#' @inheritSection as_ctdf ctdf columns
#'
#' @examples
#' data(mini_ruff)
#' x = as_ctdf(mini_ruff)
#' plot(x)
#'
#' @export
as_ctdf.data.frame <- function(
  x,
  coords = c("longitude", "latitude"),
  time = "time",
  s_srs = 4326,
  t_srs = "+proj=eqearth",
  ...
) {
  o <- as.data.table(x)
  setnames(o, c(coords, time), c("X", "Y", "timestamp"))
  o <- st_as_sf(o, coords = c("X", "Y"), crs = s_srs)

  .finalize_ctdf(o, t_srs)
}


#' Coerce an sf object to clusterTrack data format
#'
#' Converts an `sf` object with POINT geometries and a timestamp column to a `ctdf`.
#' The source CRS is taken from `x`; a missing CRS is an error.
#'
#' @param x An `sf` object with POINT geometries and a source CRS.
#' @inheritParams as_ctdf.data.frame
#' @inherit as_ctdf.data.frame return details
#' @inheritSection as_ctdf ctdf columns
#'
#' @seealso [as_ctdf()], [as_ctdf.data.frame()]
#' @examples
#' data(mini_ruff)
#' points <- sf::st_as_sf(
#'   mini_ruff,
#'   coords = c("longitude", "latitude"),
#'   crs = 4326
#' )
#' x <- as_ctdf(points)
#'
#' @export
as_ctdf.sf <- function(
  x,
  time = "time",
  t_srs = "+proj=eqearth",
  ...
) {
  if (!all(sf::st_geometry_type(x) == "POINT")) {
    stop("`x` must contain only POINT geometries.", call. = FALSE)
  }

  if (!time %in% names(x)) {
    stop(glue::glue("Time column `{time}` not found."), call. = FALSE)
  }

  if (is.na(st_crs(x))) {
    stop("`x` must have a source CRS.", call. = FALSE)
  }

  o <- copy(x)
  setnames(o, time, "timestamp")

  .finalize_ctdf(o, t_srs)
}

#' Convert a `ctdf` track to movement step segments as LINESTRINGs
#'
#' Takes a `ctdf` object and returns an `sf` object with LINESTRING geometries representing
#' the movement steps between consecutive locations. Each segment connects two points,
#' starting at the previous location and ending at the current one - i.e., each segment
#' ends at the position of the current row.
#'
#' @param ctdf A `ctdf` object (with ordered rows and a `"location"` geometry column).
#'
#' @return An `sf` object with LINESTRING geometry for each step.
#'
#' @details The number of rows is nrow(ctdf) - i, where i = 1 and corresponds to the starting index in ctdf.
#'
#'
#' @examples
#' data(mini_ruff)
#' ctdf = as_ctdf(mini_ruff)
#' s = as_ctdf_track(ctdf)
#' plot(s['.id'])
#'
#' @export
as_ctdf_track <- function(ctdf) {
  o <- ctdf |>
    st_as_sf() |>
    mutate(
      location_prev = lag(location),
      start = lag(timestamp),
      stop = timestamp
    )
  this_crs <- st_crs(o)

  o <- o |>
    dplyr::filter(!st_is_empty(location_prev))

  o <-
    o |>
    rowwise() |>
    mutate(
      track = rbind(st_coordinates(location_prev), st_coordinates(location)) |>
        st_linestring() |>
        list()
    ) |>
    ungroup() |>
    st_set_geometry("track") |>
    select(.id, .putative_cluster, start, stop, track) |>
    st_set_crs(this_crs)
}
