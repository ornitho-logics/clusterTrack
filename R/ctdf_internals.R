ctdf_result_cols <- c(
  ".id",
  "cluster",
  "lof"
)

ctdf_internal_cols <- c(
  ".move_seg",
  ".seg_id",
  ".putative_cluster"
)


#' Reserved ctdf column names
#' @keywords internal
reserved_ctdf_nams <- c(
  ctdf_result_cols,
  ctdf_internal_cols
)


.check_ctdf <- function(x) {
  if (!inherits(x, "ctdf")) {
    stop("Not a 'ctdf' object!", call. = FALSE)
  }

  nams <- c(
    "timestamp",
    "location",
    reserved_ctdf_nams
  )

  nams_ok <- nams %in% names(x)

  if (!all(nams_ok)) {
    stop(
      glue::glue(
        "Missing required ctdf column(s): ",
        "{glue::glue_collapse(nams[!nams_ok], ', ')}."
      ),
      call. = FALSE
    )
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


#' @export
#' @noRd
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


#' @export
#' @noRd
print.ctdf <- function(x, ...) {
  clustered <- !all(is.na(x$cluster))

  if (clustered) {
    n_clusters <- uniqueN(x[cluster > 0, cluster])
    n_unassigned <- sum(x$cluster == 0L, na.rm = TRUE)

    cat(
      "<ctdf: ",
      nrow(x),
      " locations, ",
      n_clusters,
      " cluster",
      if (n_clusters == 1L) "" else "s",
      ", ",
      n_unassigned,
      " unassigned>\n\n",
      sep = ""
    )
  } else {
    cat(
      "<ctdf: ",
      nrow(x),
      " location",
      if (nrow(x) == 1L) "" else "s",
      ">\n\n",
      sep = ""
    )
  }

  cols <- setdiff(names(x), ctdf_internal_cols)

  if (!clustered) {
    cols <- setdiff(cols, setdiff(ctdf_result_cols, ".id"))
  }

  dt_print <- getFromNamespace("print.data.table", "data.table")

  dt_print(
    x[, ..cols],
    topn = 3,
    nrows = 10,
    print.keys = FALSE,
    ...
  )

  invisible(x)
}
