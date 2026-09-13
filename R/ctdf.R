#' Reserved ctdf column names
#' @keywords internal
reserved_ctdf_nams <- c(
  "cluster",
  "lof",
  ".id",
  ".move_seg",
  ".seg_id",
  ".putative_cluster"
)

.check_ctdf <- function(x) {
  if (!inherits(x, "ctdf")) {
    stop("Not a 'ctdf' object!", call. = FALSE)
  }

  nams <- c(".id", ".putative_cluster", "cluster", "location", "timestamp")
  nams_ok <- nams %in% names(x)

  if (!all(nams_ok)) {
    stop("Some build in columns are missing", call. = FALSE)
  }

  if (!inherits(x$timestamp, "POSIXt")) {
    stop("'timestamp' must inherit from 'POSIXt'.", call. = FALSE)
  }

  if (anyNA(x$timestamp)) {
    stop("'timestamp' contains missing values.", call. = FALSE)
  }

  if (is.unsorted(x$timestamp)) {
    stop(
      "It seems this ctdf is not sorted anymore along timestamp!",
      call. = FALSE
    )
  }

  dups <- which(duplicated(data.table(
    st_coordinates(x$location),
    timestamp = x$timestamp
  )))
  if (length(dups) > 0) {
    suffix <- if (length(dups) > 1) "s" else ""
    warning(
      glue::glue(
        "Found {length(dups)} duplicated point{suffix} (location, timestamp) ",
        "at ctdf row{suffix}: {glue::glue_collapse(dups, ', ')}. ",
        "Input may contain multiple individuals."
      ),
      call. = FALSE
    )
  }

  max_gap_h <- getOption("clusterTrack.max_gap", 24)
  if (
    !is.numeric(max_gap_h) ||
      length(max_gap_h) != 1 ||
      is.na(max_gap_h) ||
      max_gap_h <= 0
  ) {
    max_gap_h <- Inf
  }

  gaps_h <- as.numeric(diff(x$timestamp), units = "hours")
  long_gaps_h <- gaps_h[gaps_h > max_gap_h]

  if (length(long_gaps_h)) {
    warning(
      glue::glue(
        "Found {length(long_gaps_h)} temporal gaps greater than ",
        "{format(max_gap_h, trim = TRUE)} h ",
        "(smallest: {format(round(min(long_gaps_h), 2), trim = TRUE)} h; ",
        "largest: {format(round(max(long_gaps_h), 2), trim = TRUE)} h). ",
        "Split the file manually at these gaps before running the clustering."
      ),
      call. = FALSE
    )
  }
}

#' Coerce an object to clusterTrack data format
#'
#' S3 generic for converting objects into a `ctdf`.
#'
#' See [as_ctdf.data.frame()] for coordinate columns and [as_ctdf.sf()] for
#' existing POINT geometries with a source CRS.
#'
#' @param x An object to convert.
#' @param ... Passed to methods.
#' @return A `ctdf`.
#'
#' @seealso [as_ctdf.data.frame()], [as_ctdf.sf()]
#' @export
as_ctdf <- function(x, ...) {
  UseMethod("as_ctdf")
}

#' @export
as_ctdf.default <- function(x, ...) {
  stop("No method for objects of class ", class(x))
}


#' @export
plot.ctdf <- function(
  x,
  y = NULL,
  ...,
  pch = 16,
  track_col = "#8f8989",
  point_col = "#696767",
  polygon_alpha = 0.35,
  polygon_palette = "viridis",
  cluster_labels = TRUE,
  cluster_label_col = "#f80505",
  cluster_label_cex = 0.9,
  cluster_label_font = 2
) {
  .check_ctdf(x)

  dots <- list(...)

  drop_args <- function(z, nams) {
    nm <- names(z)
    if (is.null(nm)) {
      return(z)
    }

    z[!nzchar(nm) | !(nm %in% nams)]
  }

  common_args <- drop_args(
    dots,
    c("x", "y", "add", "col", "border", "pch")
  )

  xs <- sf::st_as_sf(x)
  tr <- as_ctdf_track(x)

  if (nrow(tr) > 0) {
    do.call(
      plot,
      c(
        list(
          x = sf::st_geometry(tr),
          col = track_col
        ),
        common_args
      )
    )

    add_points <- TRUE
  } else {
    add_points <- FALSE
  }

  do.call(
    plot,
    c(
      list(
        x = sf::st_geometry(xs),
        pch = pch,
        col = point_col,
        add = add_points
      ),
      common_args
    )
  )

  cl <- x[
    !is.na(cluster) &
      cluster != 0
  ]

  if (nrow(cl) > 0) {
    clusters <- sort(unique(cl$cluster))

    hulls <- lapply(
      clusters,
      function(z) {
        g <- sf::st_geometry(sf::st_as_sf(cl[cluster == z]))
        sf::st_convex_hull(sf::st_union(g))[[1]]
      }
    )

    polys <- sf::st_sf(
      cluster = clusters,
      location = sf::st_sfc(hulls, crs = sf::st_crs(xs))
    )

    is_poly <- sf::st_geometry_type(polys) %in% c("POLYGON", "MULTIPOLYGON")
    polys <- polys[is_poly, ]

    if (nrow(polys) > 0) {
      poly_border <- hcl.colors(
        nrow(polys),
        palette = polygon_palette
      )

      poly_col <- hcl.colors(
        nrow(polys),
        palette = polygon_palette,
        alpha = polygon_alpha
      )

      do.call(
        plot,
        c(
          list(
            x = sf::st_geometry(polys),
            col = poly_col,
            border = poly_border,
            add = TRUE
          ),
          common_args
        )
      )

      if (isTRUE(cluster_labels)) {
        label_xy <- polys |>
          sf::st_geometry() |>
          sf::st_centroid() |>
          sf::st_coordinates()

        text(
          x = label_xy[, "X"],
          y = label_xy[, "Y"],
          labels = polys$cluster,
          col = cluster_label_col,
          cex = cluster_label_cex,
          font = cluster_label_font
        )
      }
    }
  }

  invisible(x)
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


.finalize_ctdf <- function(o, t_srs) {
  reserved <- intersect(names(o), reserved_ctdf_nams)

  if (length(reserved) > 0) {
    warning(
      glue::glue(
        "as_ctdf(): input contains reserved columns: ",
        "{glue::glue_collapse(reserved, ', ')}. These will be overwritten."
      ),
      call. = FALSE
    )
  }

  o <- st_transform(o, crs = t_srs)
  st_geometry(o) <- "location"

  setDT(o)
  setorder(o, timestamp)
  o[, let(
    .id = .I,
    .seg_id = NA_integer_,
    .move_seg = NA_integer_,
    .putative_cluster = NA_integer_,
    cluster = NA_integer_,
    lof = NA_real_
  )]

  setkey(o, .id)
  setcolorder(o, reserved_ctdf_nams, after = ncol(o))

  class(o) <- c("ctdf", class(o))
  .check_ctdf(o)
  o
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
