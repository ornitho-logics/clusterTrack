sapply(
  c(
    "data.table",
    "here",
    "dplyr",
    "sf",
    "terra",
    "elevatr",
    "rnaturalearth",
    "maptiles",
    "tidyterra",
    "ggspatial",
    "ggplot2",
    "patchwork",
    "clusterTrack",
    "clusterTrack.Vis"
  ),
  require,
  character.only = TRUE,
  quietly = TRUE
)

#region ctdf-s

# data(ruff143789)
# ruff = as_ctdf(ruff143789, time = "locationDate") |> cluster_track()
#
# data(ruff07b5)
# ruff2 = as_ctdf(ruff07b5, time = "timestamp") |> cluster_track()
#
# data(lbdo66862)
# lbdo = as_ctdf(lbdo66862, time = "locationDate") |> cluster_track()
#
# data(nola125a)
# nola = as_ctdf(nola125a, time = "timestamp") |> cluster_track()

#endregion

# Quick smoke test for the Esri relief path using the lbdo track in the
# default lon/lat projection, without terrain reprojection or hydro layers.
RUN_LBDO_RELIEF_TEST = FALSE
LBDO_RELIEF_TEST_PROJECTION = "laea" # one of: "wgs84", "laea", "aea"
LBDO_RELIEF_TEST_ZOOM = 3
LBDO_RELIEF_TEST_X_PAD = 0.15
LBDO_RELIEF_TEST_Y_PAD = 0.15
LBDO_RELIEF_TEST_LON0 = NULL
LBDO_RELIEF_TEST_LAT0 = NULL
LBDO_RELIEF_TEST_AEA_LAT1 = NULL
LBDO_RELIEF_TEST_AEA_LAT2 = NULL
LBDO_RELIEF_TEST_AEA_LAT1_PROP = 0.10
LBDO_RELIEF_TEST_AEA_LAT2_PROP = 0.70

make_relief_panel_crs = function(
  x,
  projection = "laea",
  lon0 = NULL,
  lat0 = NULL,
  aea_lat1 = NULL,
  aea_lat2 = NULL,
  aea_lat1_prop = 0.10,
  aea_lat2_prop = 0.70
) {
  geom_wgs84 = sf::st_as_sf(x) |>
    sf::st_transform(4326)
  bb = sf::st_bbox(geom_wgs84)

  lon0 = if (is.null(lon0)) {
    mean(c(bb[["xmin"]], bb[["xmax"]]))
  } else {
    lon0
  }
  lat0 = if (is.null(lat0)) {
    mean(c(bb[["ymin"]], bb[["ymax"]]))
  } else {
    lat0
  }

  lat_span = bb[["ymax"]] - bb[["ymin"]]
  lat1 = if (is.null(aea_lat1)) {
    bb[["ymin"]] + lat_span * aea_lat1_prop
  } else {
    aea_lat1
  }
  lat2 = if (is.null(aea_lat2)) {
    bb[["ymin"]] + lat_span * aea_lat2_prop
  } else {
    aea_lat2
  }

  switch(
    projection,
    wgs84 = sf::st_crs(4326),
    laea = sf::st_crs(
      sprintf(
        "+proj=laea +lat_0=%s +lon_0=%s +x_0=0 +y_0=0 +ellps=WGS84 +units=m +no_defs",
        lat0,
        lon0
      )
    ),
    aea = sf::st_crs(
      sprintf(
        "+proj=aea +lat_1=%s +lat_2=%s +lat_0=%s +lon_0=%s +x_0=0 +y_0=0 +ellps=WGS84 +units=m +no_defs",
        lat1,
        lat2,
        lat0,
        lon0
      )
    ),
    stop("Unknown relief projection: ", projection)
  )
}

make_lbdo_relief_test_crs = function(x) {
  make_relief_panel_crs(
    x,
    projection = LBDO_RELIEF_TEST_PROJECTION,
    lon0 = LBDO_RELIEF_TEST_LON0,
    lat0 = LBDO_RELIEF_TEST_LAT0,
    aea_lat1 = LBDO_RELIEF_TEST_AEA_LAT1,
    aea_lat2 = LBDO_RELIEF_TEST_AEA_LAT2,
    aea_lat1_prop = LBDO_RELIEF_TEST_AEA_LAT1_PROP,
    aea_lat2_prop = LBDO_RELIEF_TEST_AEA_LAT2_PROP
  )
}

if (
  RUN_LBDO_RELIEF_TEST &&
  requireNamespace("maptiles", quietly = TRUE) &&
  requireNamespace("tidyterra", quietly = TRUE)
) {
  lbdo_test = if (exists("lbdo", inherits = FALSE)) {
    data.table::copy(lbdo)
  } else {
    data(lbdo66862)
    as_ctdf(lbdo66862, time = "locationDate") |> cluster_track()
  }

  lbdo_points_wgs84 = sf::st_as_sf(lbdo_test) |>
    sf::st_transform(4326)
  lbdo_track_wgs84 = sf::st_as_sf(lbdo_test |> as_ctdf_track()) |>
    sf::st_transform(4326)
  lbdo_test_crs = make_lbdo_relief_test_crs(lbdo_test)

  lbdo_points_test = if (isTRUE(all.equal(lbdo_test_crs, sf::st_crs(4326)))) {
    lbdo_points_wgs84
  } else {
    sf::st_transform(lbdo_points_wgs84, lbdo_test_crs)
  }
  lbdo_track_test = if (isTRUE(all.equal(lbdo_test_crs, sf::st_crs(4326)))) {
    lbdo_track_wgs84
  } else {
    sf::st_transform(lbdo_track_wgs84, lbdo_test_crs)
  }

  lbdo_bb = sf::st_bbox(lbdo_points_test)
  lbdo_x_pad = (lbdo_bb[["xmax"]] - lbdo_bb[["xmin"]]) * LBDO_RELIEF_TEST_X_PAD
  lbdo_y_pad = (lbdo_bb[["ymax"]] - lbdo_bb[["ymin"]]) * LBDO_RELIEF_TEST_Y_PAD
  lbdo_extent = sf::st_as_sfc(
    sf::st_bbox(
      c(
        xmin = lbdo_bb[["xmin"]] - lbdo_x_pad,
        ymin = lbdo_bb[["ymin"]] - lbdo_y_pad,
        xmax = lbdo_bb[["xmax"]] + lbdo_x_pad,
        ymax = lbdo_bb[["ymax"]] + lbdo_y_pad
      ),
      crs = sf::st_crs(lbdo_points_test)
    )
  )

  lbdo_relief = tryCatch(
    maptiles::get_tiles(
      x = lbdo_extent,
      provider = "Esri.WorldShadedRelief",
      zoom = LBDO_RELIEF_TEST_ZOOM,
      crop = TRUE,
      project = !isTRUE(all.equal(lbdo_test_crs, sf::st_crs(4326)))
    ),
    error = function(e) NULL
  )

  if (!is.null(lbdo_relief)) {
    print(
      ggplot2::ggplot() +
        tidyterra::geom_spatraster_rgb(
          data = lbdo_relief,
          r = 1,
          g = 2,
          b = 3,
          interpolate = TRUE
        ) +
        ggspatial::layer_spatial(lbdo_track_test, color = "grey20", linewidth = 0.3, alpha = 0.8) +
        ggspatial::annotation_spatial(lbdo_points_test, color = "grey20", size = 1.2, alpha = 0.45) +
        ggplot2::coord_sf(
          xlim = c(lbdo_bb[["xmin"]] - lbdo_x_pad, lbdo_bb[["xmax"]] + lbdo_x_pad),
          ylim = c(lbdo_bb[["ymin"]] - lbdo_y_pad, lbdo_bb[["ymax"]] + lbdo_y_pad),
          crs = lbdo_test_crs,
          default_crs = lbdo_test_crs,
          expand = FALSE
        ) +
        ggplot2::theme_void()
    )
  }
}

#region helpers

pad_bbox = function(x, x_prop = 0.05, y_prop = x_prop) {
  bb = sf::st_bbox(x)
  x_pad = (bb[["xmax"]] - bb[["xmin"]]) * x_prop
  y_pad = (bb[["ymax"]] - bb[["ymin"]]) * y_prop

  sf::st_bbox(
    c(
      xmin = bb[["xmin"]] - x_pad,
      ymin = bb[["ymin"]] - y_pad,
      xmax = bb[["xmax"]] + x_pad,
      ymax = bb[["ymax"]] + y_pad
    ),
    crs = sf::st_crs(x)
  )
}

projected_bbox_to_wgs84 = function(
  bbox_proj,
  pad_prop = 0.02,
  densify_segments = 60
) {
  bbox_geom = if (inherits(bbox_proj, "bbox")) {
    sf::st_as_sfc(bbox_proj)
  } else if (inherits(bbox_proj, "sfc")) {
    bbox_proj
  } else {
    sf::st_as_sfc(bbox_proj)
  }

  if (!isTRUE(sf::st_is_longlat(bbox_geom))) {
    bb = sf::st_bbox(bbox_geom)
    seg_length = min(
      (bb[["xmax"]] - bb[["xmin"]]) / densify_segments,
      (bb[["ymax"]] - bb[["ymin"]]) / densify_segments
    )

    if (is.finite(seg_length) && seg_length > 0) {
      bbox_geom = sf::st_segmentize(bbox_geom, dfMaxLength = seg_length)
    }
  }

  bbox_geom = bbox_geom |>
    sf::st_transform(4326)
  coords = sf::st_coordinates(bbox_geom)

  lon = ((coords[, "X"] + 180) %% 360) - 180
  lon = pmin(pmax(lon, -179.999), 179.999)
  lat = pmin(pmax(coords[, "Y"], -89.999), 89.999)

  bbox_wgs84 = sf::st_bbox(
    c(
      xmin = min(lon, na.rm = TRUE),
      xmax = max(lon, na.rm = TRUE),
      ymin = min(lat, na.rm = TRUE),
      ymax = max(lat, na.rm = TRUE)
    ),
    crs = sf::st_crs(4326)
  )

  if (pad_prop > 0) {
    bbox_wgs84 = pad_bbox(
      sf::st_as_sfc(bbox_wgs84),
      x_prop = pad_prop,
      y_prop = pad_prop
    )
  }

  bbox_wgs84 = sf::st_bbox(
    c(
      xmin = pmax(bbox_wgs84[["xmin"]], -179.999),
      xmax = pmin(bbox_wgs84[["xmax"]], 179.999),
      ymin = pmax(bbox_wgs84[["ymin"]], -89.999),
      ymax = pmin(bbox_wgs84[["ymax"]], 89.999)
    ),
    crs = sf::st_crs(4326)
  )

  sf::st_as_sfc(bbox_wgs84)
}

bbox_to_ext = function(bb) {
  terra::ext(
    bb[["xmin"]],
    bb[["xmax"]],
    bb[["ymin"]],
    bb[["ymax"]]
  )
}

extents_overlap = function(x, y) {
  !(x[2] < y[1] || x[1] > y[2] || x[4] < y[3] || x[3] > y[4])
}

rescale01 = function(x) {
  rng = range(x, na.rm = TRUE)
  if (!all(is.finite(rng)) || diff(rng) == 0) {
    return(rep(1, length(x)))
  }

  (x - rng[1]) / diff(rng)
}

shade_hex = function(hex, shade, min_shade = 0.6, alpha = 0.5) {
  shade = min_shade + (1 - min_shade) * shade
  shade[!is.finite(shade)] = NA_real_
  out = rep("#FFFFFF00", length(hex))
  ok = !is.na(shade) & !is.na(hex)

  if (any(ok)) {
    rgb_base = grDevices::col2rgb(hex[ok]) / 255
    rgb_out = sweep(rgb_base, 2, pmin(pmax(shade[ok], 0), 1), `*`)
    out[ok] = grDevices::rgb(
      rgb_out[1, ],
      rgb_out[2, ],
      rgb_out[3, ],
      alpha = alpha
    )
  }

  out
}

make_bbox_geom = function(xmin, xmax, ymin, ymax, crs = 4326) {
  sf::st_sfc(
    sf::st_polygon(
      list(
        matrix(
          c(
            xmin, ymin,
            xmax, ymin,
            xmax, ymax,
            xmin, ymax,
            xmin, ymin
          ),
          ncol = 2,
          byrow = TRUE
        )
      )
    ),
    crs = crs
  )
}

panel_request_geoms_wgs84 = function(
  ctdf,
  x_pad = 0.05,
  y_pad = 0.08,
  min_lon_pad = 2,
  min_lat_pad = 1
) {
  geom_wgs84 = sf::st_as_sf(ctdf) |>
    sf::st_transform(4326)
  coords = sf::st_coordinates(geom_wgs84)

  lon = ((coords[, "X"] + 180) %% 360) - 180
  lat = pmin(pmax(coords[, "Y"], -89.999), 89.999)
  lon_shift = ifelse(lon < 0, lon + 360, lon)

  lon_range_std = range(lon, na.rm = TRUE)
  lon_range_shift = range(lon_shift, na.rm = TRUE)
  use_shift = diff(lon_range_shift) + 1e-9 < diff(lon_range_std)

  lat_range = range(lat, na.rm = TRUE)
  lat_pad = max(diff(lat_range) * y_pad, min_lat_pad)
  ymin = pmax(lat_range[1] - lat_pad, -89.999)
  ymax = pmin(lat_range[2] + lat_pad, 89.999)

  if (use_shift) {
    lon_pad = max(diff(lon_range_shift) * x_pad, min_lon_pad)
    xmin = pmax(lon_range_shift[1] - lon_pad, 0)
    xmax = pmin(lon_range_shift[2] + lon_pad, 360)

    if (xmin < 180 && xmax > 180) {
      east_geom = make_bbox_geom(xmin, 179.999, ymin, ymax)
      west_geom = make_bbox_geom(-179.999, xmax - 360, ymin, ymax)
      return(c(east_geom, west_geom))
    }

    if (xmax <= 180) {
      return(make_bbox_geom(xmin, xmax, ymin, ymax))
    }

    return(make_bbox_geom(xmin - 360, xmax - 360, ymin, ymax))
  }

  lon_pad = max(diff(lon_range_std) * x_pad, min_lon_pad)
  xmin = pmax(lon_range_std[1] - lon_pad, -179.999)
  xmax = pmin(lon_range_std[2] + lon_pad, 179.999)

  make_bbox_geom(xmin, xmax, ymin, ymax)
}

make_terrain_annotation = function(
  request_geoms_wgs84,
  bbox_proj,
  target_crs,
  zoom = 6,
  terrain_alpha = 0.5,
  min_shade = 0.58,
  disagg_factor = 1
) {
  dem_parts = lapply(
    seq_along(request_geoms_wgs84),
    function(i) {
      geom_i = request_geoms_wgs84[i]
      geom_i_ext = terra::ext(sf::st_bbox(geom_i))

      dem_raw = tryCatch(
        elevatr::get_elev_raster(
          locations = sf::st_sf(geometry = geom_i),
          z = zoom,
          clip = "locations"
        ),
        error = function(e) NULL
      )

      if (is.null(dem_raw)) {
        return(NULL)
      }

      dem_i = terra::rast(dem_raw)

      if (!nzchar(terra::crs(dem_i))) {
        terra::crs(dem_i) = sf::st_crs(4326)$wkt
      }

      if (extents_overlap(terra::ext(dem_i), geom_i_ext)) {
        dem_i = terra::crop(dem_i, geom_i_ext)
      }

      dem_i
    }
  )
  dem_parts = Filter(Negate(is.null), dem_parts)

  if (length(dem_parts) == 0) {
    return(NULL)
  }

  dem = if (length(dem_parts) == 1) {
    dem_parts[[1]]
  } else {
    Reduce(terra::merge, dem_parts)
  }

  dem = terra::project(dem, sf::st_crs(target_crs)$wkt, method = "bilinear")

  bbox_proj_ext = bbox_to_ext(bbox_proj)
  if (extents_overlap(terra::ext(dem), bbox_proj_ext)) {
    dem = terra::crop(dem, bbox_proj_ext)
  }

  if (disagg_factor > 1) {
    dem = terra::disagg(dem, fact = disagg_factor, method = "bilinear")
  }

  dem[dem < 0] = NA

  slope = terra::terrain(dem, "slope", unit = "radians")
  aspect = terra::terrain(dem, "aspect", unit = "radians")

  hillshade = terra::rast(
    lapply(
      c(270, 15, 60, 330),
      function(direction) {
        terra::shade(
          slope,
          aspect,
          angle = 45,
          direction = direction,
          normalize = TRUE
        )
      }
    )
  ) |>
    sum()

  alt_vals = as.vector(terra::values(dem))
  hill_vals = as.vector(terra::values(hillshade))

  palette_hex = grDevices::colorRampPalette(
    c(
      "#e7e0d3",
      "#d7cebc",
      "#c6baa7",
      "#b4b7aa",
      "#a3ac98",
      "#b7ad99",
      "#d6cfc2"
    )
  )(256)
  palette_id = floor(rescale01(alt_vals) * 255) + 1
  palette_id[!is.finite(alt_vals)] = 1

  terrain_hex = shade_hex(
    palette_hex[palette_id],
    rescale01(hill_vals),
    min_shade = min_shade,
    alpha = terrain_alpha
  )
  terrain_hex[!is.finite(alt_vals)] = "#FFFFFF00"

  terrain_matrix = matrix(
    terrain_hex,
    nrow = terra::nrow(dem),
    ncol = terra::ncol(dem),
    byrow = TRUE
  )

  list(
    image = as.raster(terrain_matrix),
    xmin = terra::xmin(dem),
    xmax = terra::xmax(dem),
    ymin = terra::ymin(dem),
    ymax = terra::ymax(dem)
  )
}

coord_from_geom = function(x, x_prop = 0, y_prop = x_prop) {
  bb = sf::st_bbox(x)
  x_pad = (bb[["xmax"]] - bb[["xmin"]]) * x_prop
  y_pad = (bb[["ymax"]] - bb[["ymin"]]) * y_prop
  geom_crs = sf::st_crs(x)

  ggplot2::coord_sf(
    xlim = c(bb[["xmin"]] - x_pad, bb[["xmax"]] + x_pad),
    ylim = c(bb[["ymin"]] - y_pad, bb[["ymax"]] + y_pad),
    crs = geom_crs,
    default_crs = geom_crs,
    expand = FALSE
  )
}

coord_from_bbox = function(bb) {
  bb_crs = sf::st_crs(bb)

  ggplot2::coord_sf(
    xlim = c(bb[["xmin"]], bb[["xmax"]]),
    ylim = c(bb[["ymin"]], bb[["ymax"]]),
    crs = bb_crs,
    default_crs = bb_crs,
    expand = FALSE
  )
}

transform_sf_columns = function(x, target_crs) {
  geom_cols = names(x)[vapply(x, inherits, logical(1), what = "sfc")]

  for (geom_col in geom_cols) {
    geom = x[[geom_col]]

    if (is.na(sf::st_crs(geom))) {
      x[[geom_col]] = suppressWarnings(sf::st_set_crs(geom, target_crs))
    } else if (!isTRUE(all.equal(sf::st_crs(geom), target_crs))) {
      x[[geom_col]] = suppressWarnings(sf::st_transform(geom, target_crs))
    }
  }

  x
}

bbox_ratio = function(bb) {
  unname((bb[["xmax"]] - bb[["xmin"]]) / (bb[["ymax"]] - bb[["ymin"]]))
}

set_bbox_aspect = function(bb, target_ratio = 1) {
  xmid = (bb[["xmin"]] + bb[["xmax"]]) / 2
  ymid = (bb[["ymin"]] + bb[["ymax"]]) / 2

  width = bb[["xmax"]] - bb[["xmin"]]
  height = bb[["ymax"]] - bb[["ymin"]]
  current_ratio = width / height

  if (current_ratio < target_ratio) {
    new_width = height * target_ratio
    half_width = new_width / 2
    half_height = height / 2
  } else {
    new_height = width / target_ratio
    half_width = width / 2
    half_height = new_height / 2
  }

  sf::st_bbox(
    c(
      xmin = xmid - half_width,
      xmax = xmid + half_width,
      ymin = ymid - half_height,
      ymax = ymid + half_height
    ),
    crs = sf::st_crs(bb)
  )
}

make_local_lcc_crs = function(x) {
  geom_wgs84 = sf::st_as_sf(x) |>
    sf::st_transform(4326)
  bb = sf::st_bbox(geom_wgs84)

  lon0 = mean(c(bb[["xmin"]], bb[["xmax"]]))
  lat0 = mean(c(bb[["ymin"]], bb[["ymax"]]))
  lat_span = bb[["ymax"]] - bb[["ymin"]]

  if (lat_span < 4) {
    lat1 = lat0 - 1
    lat2 = lat0 + 1
  } else {
    lat1 = bb[["ymin"]] + lat_span * 0.2
    lat2 = bb[["ymax"]] - lat_span * 0.2
  }

  lat1 = pmax(lat1, -89)
  lat2 = pmin(lat2, 89)

  sprintf(
    "+proj=lcc +lat_1=%s +lat_2=%s +lat_0=%s +lon_0=%s +x_0=0 +y_0=0 +ellps=WGS84 +units=m +no_defs",
    lat1,
    lat2,
    lat0,
    lon0
  )
}

make_local_aea_crs = function(
  x,
  lat1_prop = 0.10,
  lat2_prop = 0.70
) {
  geom_wgs84 = sf::st_as_sf(x) |>
    sf::st_transform(4326)
  bb = sf::st_bbox(geom_wgs84)

  lon0 = mean(c(bb[["xmin"]], bb[["xmax"]]))
  lat0 = mean(c(bb[["ymin"]], bb[["ymax"]]))
  lat_span = bb[["ymax"]] - bb[["ymin"]]

  lat1 = bb[["ymin"]] + lat_span * lat1_prop
  lat2 = bb[["ymin"]] + lat_span * lat2_prop

  if (!is.finite(lat_span) || lat_span <= 0 || abs(lat2 - lat1) < 1) {
    lat1 = lat0 - 5
    lat2 = lat0 + 5
  }

  lat1 = pmax(lat1, -89)
  lat2 = pmin(lat2, 89)

  sprintf(
    "+proj=aea +lat_1=%s +lat_2=%s +lat_0=%s +lon_0=%s +x_0=0 +y_0=0 +ellps=WGS84 +units=m +no_defs",
    lat1,
    lat2,
    lat0,
    lon0
  )
}

make_local_laea_crs = function(x) {
  geom_wgs84 = sf::st_as_sf(x) |>
    sf::st_transform(4326)
  bb = sf::st_bbox(geom_wgs84)

  lon0 = mean(c(bb[["xmin"]], bb[["xmax"]]))
  lat0 = mean(c(bb[["ymin"]], bb[["ymax"]]))

  sprintf(
    "+proj=laea +lat_0=%s +lon_0=%s +x_0=0 +y_0=0 +ellps=WGS84 +units=m +no_defs",
    lat0,
    lon0
  )
}

track_extent_in_crs = function(
  ctdf,
  plot_crs,
  x_pad = 0.05,
  y_pad = 0.08,
  target_ratio = NULL
) {
  ctdf_proj = data.table::copy(ctdf)
  ctdf_proj = transform_sf_columns(ctdf_proj, plot_crs)
  extent = pad_bbox(sf::st_as_sf(ctdf_proj), x_prop = x_pad, y_prop = y_pad)

  if (!is.null(target_ratio)) {
    extent = set_bbox_aspect(extent, target_ratio = target_ratio)
  }

  extent
}

panel_extent_from_points = function(
  points_sf,
  x_pad = 0.05,
  y_pad = 0.08,
  target_ratio = NULL,
  xmin_pad = x_pad,
  xmax_pad = x_pad,
  ymin_pad = y_pad,
  ymax_pad = y_pad
) {
  bb = sf::st_bbox(points_sf)
  x_span = bb[["xmax"]] - bb[["xmin"]]
  y_span = bb[["ymax"]] - bb[["ymin"]]

  extent = sf::st_bbox(
    c(
      xmin = bb[["xmin"]] - x_span * xmin_pad,
      ymin = bb[["ymin"]] - y_span * ymin_pad,
      xmax = bb[["xmax"]] + x_span * xmax_pad,
      ymax = bb[["ymax"]] + y_span * ymax_pad
    ),
    crs = sf::st_crs(points_sf)
  )

  if (!is.null(target_ratio)) {
    extent = set_bbox_aspect(extent, target_ratio = target_ratio)
  }

  extent
}

extent_geom_to_wgs84 = function(extent_bb, densify_segments = 120) {
  extent_geom = sf::st_as_sfc(extent_bb)

  if (!isTRUE(sf::st_is_longlat(extent_geom))) {
    bb = sf::st_bbox(extent_geom)
    seg_length = min(
      (bb[["xmax"]] - bb[["xmin"]]) / densify_segments,
      (bb[["ymax"]] - bb[["ymin"]]) / densify_segments
    )

    if (is.finite(seg_length) && seg_length > 0) {
      extent_geom = sf::st_segmentize(extent_geom, dfMaxLength = seg_length)
    }
  }

  suppressWarnings(
    extent_geom |>
      sf::st_transform(4326) |>
      sf::st_make_valid()
  )
}

panel_ratio_in_crs = function(ctdf, plot_crs, x_pad, y_pad) {
  ctdf_proj = data.table::copy(ctdf)
  ctdf_proj = transform_sf_columns(ctdf_proj, plot_crs)

  bbox_ratio(
    panel_extent_from_points(
      points_sf = sf::st_as_sf(ctdf_proj),
      x_pad = x_pad,
      y_pad = y_pad
    )
  )
}

prepare_relief_panel = function(
  ctdf,
  plot_crs,
  x_pad = 0.08,
  y_pad = 0.12,
  xmin_pad = x_pad,
  xmax_pad = x_pad,
  ymin_pad = y_pad,
  ymax_pad = y_pad,
  request_x_pad = x_pad,
  request_y_pad = y_pad,
  request_xmin_pad = request_x_pad,
  request_xmax_pad = request_x_pad,
  request_ymin_pad = request_y_pad,
  request_ymax_pad = request_y_pad,
  target_ratio = NULL,
  zoom = 4,
  fetch_relief = TRUE
) {
  ctdf = data.table::copy(ctdf)
  use_wgs84 = isTRUE(all.equal(plot_crs, sf::st_crs(4326)))

  points_wgs84 = sf::st_as_sf(ctdf) |>
    sf::st_transform(4326)
  points_plot = if (use_wgs84) {
    points_wgs84
  } else {
    suppressWarnings(sf::st_transform(points_wgs84, plot_crs))
  }

  track0_plot = NULL
  if (any(ctdf[["cluster"]] == 0, na.rm = TRUE)) {
    track0_wgs84 = sf::st_as_sf(ctdf[cluster == 0] |> as_ctdf_track()) |>
      sf::st_transform(4326)
    track0_plot = if (use_wgs84) {
      track0_wgs84
    } else {
      suppressWarnings(sf::st_transform(track0_wgs84, plot_crs))
    }
  }

  request_extent = panel_extent_from_points(
    points_sf = points_plot,
    x_pad = request_x_pad,
    y_pad = request_y_pad,
    target_ratio = NULL,
    xmin_pad = request_xmin_pad,
    xmax_pad = request_xmax_pad,
    ymin_pad = request_ymin_pad,
    ymax_pad = request_ymax_pad
  )
  map_extent = panel_extent_from_points(
    points_sf = points_plot,
    x_pad = x_pad,
    y_pad = y_pad,
    target_ratio = target_ratio,
    xmin_pad = xmin_pad,
    xmax_pad = xmax_pad,
    ymin_pad = ymin_pad,
    ymax_pad = ymax_pad
  )

  list(
    points_plot = points_plot,
    track0_plot = track0_plot,
    request_extent = request_extent,
    request_geoms_wgs84 = extent_geom_to_wgs84(request_extent),
    map_extent = map_extent,
    relief = if (fetch_relief) {
      get_relief_basemap(
        extent_geom = sf::st_as_sfc(request_extent),
        plot_crs = plot_crs,
        zoom = zoom
      )
    } else {
      NULL
    }
  )
}

physical_layer = local({
  cache = new.env(parent = emptyenv())

  function(type, scale = 10) {
    key = paste(type, scale, sep = "_")

    if (!exists(key, envir = cache, inherits = FALSE)) {
      layer = rnaturalearth::ne_download(
        scale = scale,
        type = type,
        category = "physical",
        returnclass = "sf"
      )

      geom_types = unique(as.character(sf::st_geometry_type(layer, by_geometry = TRUE)))
      if (any(geom_types %in% c("POLYGON", "MULTIPOLYGON"))) {
        layer = suppressWarnings(sf::st_make_valid(layer))
      }

      assign(key, layer, envir = cache)
    }

    get(key, envir = cache, inherits = FALSE)
  }
})

clip_layer_to_extent = function(x, extent_wgs84) {
  geom_types = unique(as.character(sf::st_geometry_type(x, by_geometry = TRUE)))
  s2_old = sf::sf_use_s2(FALSE)
  on.exit(sf::sf_use_s2(s2_old), add = TRUE)

  clipped_parts = lapply(
    seq_along(extent_wgs84),
    function(i) {
      piece = extent_wgs84[i]
      clipped = suppressWarnings(sf::st_crop(x, sf::st_bbox(piece)))

      if (nrow(clipped) == 0) {
        return(NULL)
      }

      clipped = suppressWarnings(sf::st_intersection(clipped, piece))

      if (nrow(clipped) == 0) {
        return(NULL)
      }

      if (any(geom_types %in% c("POLYGON", "MULTIPOLYGON"))) {
        clipped = suppressWarnings(sf::st_make_valid(clipped))
      }

      clipped
    }
  )
  clipped_parts = Filter(Negate(is.null), clipped_parts)

  if (length(clipped_parts) == 0) {
    return(x[0, ])
  }

  clipped = do.call(rbind, clipped_parts)

  clipped
}

get_panel_hydro = function(request_geoms_wgs84, plot_crs, scale = 10) {
  rivers = physical_layer("rivers_lake_centerlines", scale = scale) |>
    clip_layer_to_extent(request_geoms_wgs84)
  lakes = physical_layer("lakes", scale = scale) |>
    clip_layer_to_extent(request_geoms_wgs84)
  coast = physical_layer("coastline", scale = scale) |>
    clip_layer_to_extent(request_geoms_wgs84)

  if (nrow(rivers) > 0) {
    rivers = suppressWarnings(sf::st_transform(rivers, plot_crs))
  }

  if (nrow(lakes) > 0) {
    lakes = suppressWarnings(sf::st_transform(lakes, plot_crs))
  }

  if (nrow(coast) > 0) {
    coast = suppressWarnings(sf::st_transform(coast, plot_crs))
  }

  list(rivers = rivers, lakes = lakes, coast = coast)
}

mask_relief_to_land = function(relief, request_geoms_wgs84, plot_crs, scale = 10) {
  if (is.null(relief)) {
    return(NULL)
  }

  land = physical_layer("land", scale = scale) |>
    clip_layer_to_extent(request_geoms_wgs84)

  if (nrow(land) == 0) {
    return(relief)
  }

  land = suppressWarnings(sf::st_transform(land, plot_crs))

  if (nrow(land) == 0) {
    return(relief)
  }

  terra::mask(
    relief,
    terra::vect(land)
  )
}

get_relief_basemap = function(extent_geom, plot_crs, zoom = 4) {
  if (!requireNamespace("maptiles", quietly = TRUE)) {
    return(NULL)
  }

  tryCatch(
    maptiles::get_tiles(
      x = extent_geom,
      provider = "Esri.WorldShadedRelief",
      zoom = zoom,
      crop = TRUE,
      project = !isTRUE(all.equal(plot_crs, sf::st_crs(4326)))
    ),
    error = function(e) NULL
  )
}

map_background = function(
  relief = NULL,
  lakes = NULL,
  rivers = NULL,
  coast = NULL,
  show_lakes = TRUE,
  show_rivers = TRUE,
  show_coast = TRUE,
  lake_fill = "#d9e6f6",
  lake_alpha = 0.88,
  river_color = "#698ecf",
  river_alpha = 0.82,
  river_linewidth = 0.16,
  coast_color = "grey70",
  coast_alpha = 0.6
) {
  p = ggplot2::ggplot() +
    ggplot2::theme(
      panel.background = ggplot2::element_rect(fill = "white", color = NA),
      plot.background = ggplot2::element_rect(fill = "white", color = NA)
    )

  if (!is.null(relief)) {
    p = p +
      tidyterra::geom_spatraster_rgb(
        data = relief,
        r = 1,
        g = 2,
        b = 3,
        interpolate = TRUE
      )
  }

  if (show_lakes && !is.null(lakes) && nrow(lakes) > 0) {
    p = p +
      ggspatial::annotation_spatial(
        lakes,
        fill = scales::alpha(lake_fill, lake_alpha),
        color = NA
      )
  }

  if (show_rivers && !is.null(rivers) && nrow(rivers) > 0) {
    p = p +
      ggspatial::annotation_spatial(
        rivers,
        color = scales::alpha(river_color, river_alpha),
        linewidth = river_linewidth
      )
  }

  if (show_coast && !is.null(coast) && nrow(coast) > 0) {
    p = p +
      ggspatial::annotation_spatial(
        coast,
        color = scales::alpha(coast_color, coast_alpha),
        linewidth = 0.22
      )
  }

  p
}

make_fig_map = function(
  ctdf,
  crs,
  scloc = "br",
  x_pad = 0.08,
  y_pad = 0.12,
  xmin_pad = x_pad,
  xmax_pad = x_pad,
  ymin_pad = y_pad,
  ymax_pad = y_pad,
  request_x_pad = x_pad,
  request_y_pad = y_pad,
  request_xmin_pad = request_x_pad,
  request_xmax_pad = request_x_pad,
  request_ymin_pad = request_y_pad,
  request_ymax_pad = request_y_pad,
  target_ratio = NULL,
  terrain_zoom = 6,
  terrain_alpha = 0.5,
  min_shade = 0.58,
  disagg_factor = 1,
  hydro_scale = 10,
  basemap_override = NULL,
  show_lakes = TRUE,
  show_rivers = TRUE,
  show_coast = TRUE,
  lake_fill = "#d9e6f6",
  lake_alpha = 0.88,
  river_color = "#698ecf",
  river_alpha = 0.82,
  river_linewidth = 0.16,
  coast_color = "grey70",
  coast_alpha = 0.6,
  noncluster_point_alpha = 0.5,
  noncluster_point_color = "grey30",
  noncluster_point_shape = 21,
  noncluster_point_fill = "grey30",
  noncluster_point_size = 1,
  cluster_point_alpha = 0.35,
  cluster_point_color = "white",
  cluster_point_shape = 21,
  cluster_point_fill = NULL,
  cluster_point_size = 2,
  track_line_linewidth = 0.2,
  track_line_color = "grey30",
  track_line_alpha = 0.5,
  scalebar_height = grid::unit(0.12, "cm"),
  scalebar_text_cex = 0.56,
  scalebar_tick_height = 0.48,
  scalebar_line_width = 0.8,
  scalebar_width_hint = 0.25,
  scalebar_distance_km = NULL
) {
  plot_crs = sf::st_crs(crs)
  panel_base = prepare_relief_panel(
    ctdf = ctdf,
    plot_crs = plot_crs,
    x_pad = x_pad,
    y_pad = y_pad,
    xmin_pad = xmin_pad,
    xmax_pad = xmax_pad,
    ymin_pad = ymin_pad,
    ymax_pad = ymax_pad,
    request_x_pad = request_x_pad,
    request_y_pad = request_y_pad,
    request_xmin_pad = request_xmin_pad,
    request_xmax_pad = request_xmax_pad,
    request_ymin_pad = request_ymin_pad,
    request_ymax_pad = request_ymax_pad,
    target_ratio = target_ratio,
    zoom = terrain_zoom,
    fetch_relief = is.null(basemap_override)
  )

  if (is.null(basemap_override)) {
    hydro = get_panel_hydro(
      request_geoms_wgs84 = panel_base$request_geoms_wgs84,
      plot_crs = plot_crs,
      scale = hydro_scale
    )
    panel_base$relief = mask_relief_to_land(
      relief = panel_base$relief,
      request_geoms_wgs84 = panel_base$request_geoms_wgs84,
      plot_crs = plot_crs,
      scale = hydro_scale
    )
  } else {
    if (!isTRUE(all.equal(basemap_override$crs, plot_crs))) {
      stop("basemap_override CRS must match the panel CRS.")
    }

    hydro = basemap_override$hydro
    panel_base$relief = basemap_override$relief
  }

  if (!is.null(scalebar_distance_km)) {
    map_width = panel_base$map_extent[["xmax"]] - panel_base$map_extent[["xmin"]]

    if (is.finite(map_width) && isTRUE(map_width > 0)) {
      scalebar_width_hint = min(
        0.95,
        max(0.02, (scalebar_distance_km * 1000) / map_width)
      )
    }
  }

  ctdf = data.table::copy(ctdf)
  ctdf = transform_sf_columns(ctdf, plot_crs)
  data.table::set(ctdf, j = "Cluster", value = factor(ctdf[["cluster"]]))
  ss = summarise_ctdf(ctdf)
  ss = transform_sf_columns(ss, plot_crs)
  data.table::set(ss, j = "Cluster", value = factor(ss[["cluster"]]))
  cluster_centers_sf = sf::st_sf(
    cluster = ss$cluster,
    Cluster = ss$Cluster,
    geometry = ss$site_poly_center
  )

  track0_layer = if (is.null(panel_base$track0_plot)) {
    NULL
  } else {
    ggspatial::layer_spatial(
      panel_base$track0_plot,
      color = track_line_color,
      linewidth = track_line_linewidth,
      alpha = track_line_alpha
    )
  }

  noncluster_point_layer = ggspatial::annotation_spatial(
    sf::st_as_sf(ctdf[cluster == 0]),
    alpha = noncluster_point_alpha,
    color = noncluster_point_color,
    fill = noncluster_point_fill,
    shape = noncluster_point_shape,
    size = noncluster_point_size
  )

  cluster_point_layer = if (is.null(cluster_point_fill)) {
    ggspatial::layer_spatial(
      cluster_centers_sf[cluster_centers_sf$cluster > 0, ],
      ggplot2::aes(fill = Cluster),
      color = cluster_point_color,
      shape = cluster_point_shape,
      alpha = cluster_point_alpha,
      size = cluster_point_size
    )
  } else {
    ggspatial::layer_spatial(
      cluster_centers_sf[cluster_centers_sf$cluster > 0, ],
      fill = cluster_point_fill,
      color = cluster_point_color,
      shape = cluster_point_shape,
      alpha = cluster_point_alpha,
      size = cluster_point_size
    )
  }
  ss = cbind(
    ss,
    sf::st_as_sf(ss$site_poly_center) |>
      sf::st_transform(crs = plot_crs) |>
      sf::st_coordinates()
  )

  tt = ggplot2::theme_bw() +
    ggplot2::theme(
      legend.position = "none",
      panel.background = ggplot2::element_rect(fill = "white", color = NA),
      plot.background = ggplot2::element_rect(fill = "white", color = NA),
      panel.grid.major = ggplot2::element_blank(),
      panel.grid.minor = ggplot2::element_blank(),
      axis.ticks = ggplot2::element_blank(),
      axis.text = ggplot2::element_blank(),
      axis.title = ggplot2::element_blank(),
      plot.margin = ggplot2::margin(2.5, 2.5, 2.5, 2.5)
    )

  scf = viridis::scale_fill_viridis(
    discrete = TRUE,
    option = "turbo",
    begin = 0.1,
    end = 0.95
  )
  scc = viridis::scale_color_viridis(
    discrete = TRUE,
    option = "turbo",
    begin = 0.1,
    end = 0.95
  )

  list(
    plot =
      map_background(
        relief = panel_base$relief,
        lakes = hydro$lakes,
        rivers = hydro$rivers,
        coast = hydro$coast,
        show_lakes = show_lakes,
        show_rivers = show_rivers,
        show_coast = show_coast,
        lake_fill = lake_fill,
        lake_alpha = lake_alpha,
        river_color = river_color,
        river_alpha = river_alpha,
        river_linewidth = river_linewidth,
        coast_color = coast_color,
        coast_alpha = coast_alpha
      ) +
      noncluster_point_layer +
      track0_layer +
      ggspatial::annotation_spatial(
        sf::st_as_sf(ss[, .(Cluster, site_poly)]),
        ggplot2::aes(fill = Cluster, color = Cluster),
        alpha = 0.3
      ) +
      cluster_point_layer +
      scf +
      scc +
      ggspatial::annotation_scale(
        location = scloc,
        width_hint = scalebar_width_hint,
        line_width = scalebar_line_width,
        height = scalebar_height,
        text_cex = scalebar_text_cex,
        tick_height = scalebar_tick_height
      ) +
      tt +
      coord_from_bbox(panel_base$map_extent),
    extent = panel_base$map_extent,
    basemap = list(
      crs = plot_crs,
      relief = panel_base$relief,
      hydro = hydro
    )
  )
}

# Circular timeline helpers mirror the Figure 2 gtime logic but wrap each
# year into its own ring so one full rotation always represents one year.
build_gtime_timeline_df = function(ctdf) {
  timeline_df = data.table::copy(ctdf)[
    cluster > 0,
    .(
      start = min(timestamp),
      stop = max(timestamp)
    ),
    by = cluster
  ][order(cluster)]

  data.table::set(
    timeline_df,
    j = "Cluster",
    value = factor(
      timeline_df[["cluster"]],
      levels = sort(unique(timeline_df[["cluster"]]))
    )
  )

  timeline_df[]
}

split_timeline_span_by_year = function(
  start,
  stop,
  cluster,
  tz = "UTC",
  min_arc_fraction = 1 / (366 * 24)
) {
  if (is.na(start) || is.na(stop) || stop < start) {
    return(data.table::data.table())
  }

  start_year = as.integer(format(start, "%Y"))
  stop_year = as.integer(format(stop, "%Y"))

  data.table::rbindlist(
    lapply(seq.int(start_year, stop_year), function(year) {
      year_start = as.POSIXct(
        sprintf("%04d-01-01 00:00:00", year),
        tz = tz
      )
      next_year_start = as.POSIXct(
        sprintf("%04d-01-01 00:00:00", year + 1),
        tz = tz
      )

      segment_start = max(start, year_start)
      segment_stop = min(stop, next_year_start)

      if (segment_stop < segment_start) {
        return(NULL)
      }

      year_seconds = as.numeric(
        difftime(next_year_start, year_start, units = "secs")
      )
      theta_start = as.numeric(
        difftime(segment_start, year_start, units = "secs")
      ) / year_seconds
      theta_stop = as.numeric(
        difftime(segment_stop, year_start, units = "secs")
      ) / year_seconds

      if (!isTRUE(segment_stop > segment_start)) {
        theta_stop = min(1, theta_start + min_arc_fraction)
      }

      data.table::data.table(
        cluster = cluster,
        year = year,
        segment_start = segment_start,
        segment_stop = segment_stop,
        theta_start = theta_start,
        theta_stop = theta_stop
      )
    }),
    use.names = TRUE,
    fill = TRUE
  )
}

build_circular_gtime_df = function(ctdf) {
  timeline_df = build_gtime_timeline_df(ctdf)

  if (!nrow(timeline_df)) {
    return(data.table::data.table())
  }

  tz = attr(timeline_df[["start"]], "tzone")
  if (is.null(tz) || identical(tz, "")) {
    tz = "UTC"
  }

  circular_df = data.table::rbindlist(
    lapply(seq_len(nrow(timeline_df)), function(i) {
      split_timeline_span_by_year(
        start = timeline_df$start[i],
        stop = timeline_df$stop[i],
        cluster = timeline_df$cluster[i],
        tz = tz
      )
    }),
    use.names = TRUE,
    fill = TRUE
  )

  if (!nrow(circular_df)) {
    return(circular_df)
  }

  data.table::set(
    circular_df,
    j = "Cluster",
    value = factor(
      circular_df[["cluster"]],
      levels = levels(timeline_df[["Cluster"]])
    )
  )

  year_levels = sort(unique(circular_df[["year"]]))
  data.table::set(
    circular_df,
    j = "year_id",
    value = match(circular_df[["year"]], year_levels)
  )
  data.table::set(circular_df, j = "ymin", value = circular_df[["year_id"]] - 0.42)
  data.table::set(circular_df, j = "ymax", value = circular_df[["year_id"]] + 0.42)

  circular_df[]
}

build_circular_month_guides = function(reference_year = 2001) {
  year_start = as.POSIXct(
    sprintf("%04d-01-01 00:00:00", reference_year),
    tz = "UTC"
  )
  next_year_start = as.POSIXct(
    sprintf("%04d-01-01 00:00:00", reference_year + 1),
    tz = "UTC"
  )
  year_seconds = as.numeric(
    difftime(next_year_start, year_start, units = "secs")
  )
  month_starts = as.POSIXct(
    sprintf("%04d-%02d-01 00:00:00", reference_year, 1:12),
    tz = "UTC"
  )
  next_month_starts = c(month_starts[-1], next_year_start)

  data.table::data.table(
    month = month.abb,
    theta_start = as.numeric(
      difftime(month_starts, year_start, units = "secs")
    ) / year_seconds,
    theta_label = (
      as.numeric(difftime(month_starts, year_start, units = "secs")) +
        as.numeric(difftime(next_month_starts, year_start, units = "secs"))
    ) / (2 * year_seconds)
  )
}

make_circular_gtime = function(ctdf, title = NULL) {
  circular_df = build_circular_gtime_df(ctdf)

  if (!nrow(circular_df)) {
    return(ggplot2::ggplot() + ggplot2::theme_void())
  }

  month_guides = build_circular_month_guides()
  year_df = unique(circular_df[, .(year, year_id)])[order(year)]
  max_year_id = max(year_df$year_id)

  scf = viridis::scale_fill_viridis(
    discrete = TRUE,
    option = "turbo",
    begin = 0.1,
    end = 0.95
  )
  scc = viridis::scale_color_viridis(
    discrete = TRUE,
    option = "turbo",
    begin = 0.1,
    end = 0.95
  )

  ggplot2::ggplot(circular_df) +
    ggplot2::geom_hline(
      data = year_df,
      ggplot2::aes(yintercept = year_id),
      inherit.aes = FALSE,
      color = scales::alpha("grey55", 0.28),
      linewidth = 0.3
    ) +
    ggplot2::geom_vline(
      data = month_guides,
      ggplot2::aes(xintercept = theta_start),
      inherit.aes = FALSE,
      color = scales::alpha("grey45", 0.35),
      linewidth = 0.25
    ) +
    ggplot2::geom_rect(
      ggplot2::aes(
        xmin = theta_start,
        xmax = theta_stop,
        ymin = ymin,
        ymax = ymax,
        fill = Cluster,
        color = Cluster
      ),
      linewidth = 0.3,
      alpha = 0.38
    ) +
    ggplot2::geom_text(
      data = year_df,
      ggplot2::aes(x = 0.015, y = year_id, label = year),
      inherit.aes = FALSE,
      hjust = 0,
      color = "grey20",
      size = 3
    ) +
    scf +
    scc +
    ggplot2::coord_polar(theta = "x", start = -pi / 2) +
    ggplot2::scale_x_continuous(
      limits = c(0, 1),
      breaks = month_guides$theta_label,
      labels = month_guides$month,
      expand = c(0, 0)
    ) +
    ggplot2::scale_y_continuous(
      limits = c(0.35, max_year_id + 0.8),
      breaks = NULL,
      expand = ggplot2::expansion(mult = c(0, 0))
    ) +
    ggplot2::labs(
      title = title,
      subtitle = "1 rotation = 1 year"
    ) +
    ggplot2::theme_bw() +
    ggplot2::theme(
      legend.position = "none",
      panel.background = ggplot2::element_rect(fill = "white", color = NA),
      plot.background = ggplot2::element_rect(fill = "white", color = NA),
      panel.grid = ggplot2::element_blank(),
      axis.ticks = ggplot2::element_blank(),
      axis.title = ggplot2::element_blank(),
      axis.text.y = ggplot2::element_blank(),
      axis.text.x = ggplot2::element_text(color = "grey20", size = 8),
      plot.title = ggplot2::element_text(
        hjust = 0.5,
        color = "grey15",
        size = 10,
        face = "bold"
      ),
      plot.subtitle = ggplot2::element_text(
        hjust = 0.5,
        color = "grey30",
        size = 8
      ),
      plot.margin = ggplot2::margin(8, 8, 8, 8)
    )
}

# Spiral helpers keep time continuous across year boundaries, so occupancy
# spans that cross from December into January stay joined on the plot.
sample_gtime_segment_timestamps = function(
  start,
  stop,
  samples_per_year = 720,
  min_duration_secs = 3600
) {
  tz = attr(start, "tzone")
  if (is.null(tz) || identical(tz, "")) {
    tz = "UTC"
  }

  if (is.na(start) || is.na(stop)) {
    return(as.POSIXct(character(), tz = tz))
  }

  if (!isTRUE(stop > start)) {
    stop = start + min_duration_secs
  }

  duration_years = as.numeric(
    difftime(stop, start, units = "secs")
  ) / (365.25 * 24 * 3600)
  n_points = max(2, ceiling(duration_years * samples_per_year) + 1)

  as.POSIXct(
    seq(from = as.numeric(start), to = as.numeric(stop), length.out = n_points),
    origin = "1970-01-01",
    tz = tz
  )
}

timestamps_to_spiral_coords = function(
  timestamps,
  year_levels,
  inner_radius = 1.15,
  ring_spacing = 0.92,
  start_angle = pi / 2
) {
  if (!length(timestamps)) {
    return(data.table::data.table())
  }

  tz = attr(timestamps, "tzone")
  if (is.null(tz) || identical(tz, "")) {
    tz = "UTC"
  }

  years = as.integer(format(timestamps, "%Y"))
  year_id = match(years, year_levels)
  year_start = as.POSIXct(
    sprintf("%04d-01-01 00:00:00", years),
    tz = tz
  )
  next_year_start = as.POSIXct(
    sprintf("%04d-01-01 00:00:00", years + 1),
    tz = tz
  )
  year_fraction = as.numeric(
    difftime(timestamps, year_start, units = "secs")
  ) / as.numeric(
    difftime(next_year_start, year_start, units = "secs")
  )

  spiral_fraction = (year_id - 1) + year_fraction
  angle = start_angle - 2 * pi * year_fraction
  radius = inner_radius + spiral_fraction * ring_spacing

  data.table::data.table(
    timestamp = timestamps,
    year = years,
    year_id = year_id,
    year_fraction = year_fraction,
    spiral_fraction = spiral_fraction,
    angle = angle,
    radius = radius,
    x = radius * cos(angle),
    y = radius * sin(angle)
  )
}

build_spiral_gtime_df = function(
  ctdf,
  inner_radius = 1.15,
  ring_spacing = 0.92,
  samples_per_year = 720
) {
  timeline_df = build_gtime_timeline_df(ctdf)

  if (!nrow(timeline_df)) {
    return(data.table::data.table())
  }

  year_levels = seq.int(
    min(as.integer(format(timeline_df$start, "%Y"))),
    max(as.integer(format(timeline_df$stop, "%Y")))
  )

  spiral_df = data.table::rbindlist(
    lapply(seq_len(nrow(timeline_df)), function(i) {
      timestamps = sample_gtime_segment_timestamps(
        start = timeline_df$start[i],
        stop = timeline_df$stop[i],
        samples_per_year = samples_per_year
      )

      coords = timestamps_to_spiral_coords(
        timestamps = timestamps,
        year_levels = year_levels,
        inner_radius = inner_radius,
        ring_spacing = ring_spacing
      )

      coords[, `:=`(
        cluster = timeline_df$cluster[i],
        Cluster = timeline_df$Cluster[i],
        segment_id = i
      )]

      coords[]
    }),
    use.names = TRUE,
    fill = TRUE
  )

  spiral_df[]
}

build_spiral_connector_df = function(
  ctdf,
  inner_radius = 1.15,
  ring_spacing = 0.92,
  samples_per_year = 720
) {
  timeline_df = build_gtime_timeline_df(ctdf)

  if (nrow(timeline_df) < 2) {
    return(data.table::data.table())
  }

  timeline_df = data.table::copy(timeline_df)[order(start, stop, cluster)]
  year_levels = seq.int(
    min(as.integer(format(timeline_df$start, "%Y"))),
    max(as.integer(format(timeline_df$stop, "%Y")))
  )

  connector_df = data.table::rbindlist(
    lapply(seq_len(nrow(timeline_df) - 1), function(i) {
      connector_start = timeline_df$stop[i]
      connector_stop = timeline_df$start[i + 1]

      # Skip overlaps; only draw the gap that connects one colored segment to
      # the next chronological segment, matching the Figure 2 timeline logic.
      if (
        is.na(connector_start) ||
        is.na(connector_stop) ||
        !isTRUE(connector_stop > connector_start)
      ) {
        return(NULL)
      }

      coords = timestamps_to_spiral_coords(
        timestamps = sample_gtime_segment_timestamps(
          start = connector_start,
          stop = connector_stop,
          samples_per_year = samples_per_year
        ),
        year_levels = year_levels,
        inner_radius = inner_radius,
        ring_spacing = ring_spacing
      )

      coords[, connector_id := i]
      coords[]
    }),
    use.names = TRUE,
    fill = TRUE
  )

  connector_df[]
}

build_spiral_reference_path = function(
  n_years,
  inner_radius = 1.15,
  ring_spacing = 0.92,
  points_per_year = 720,
  start_angle = pi / 2
) {
  spiral_fraction = seq(
    0,
    n_years,
    length.out = n_years * points_per_year + 1
  )
  year_fraction = spiral_fraction %% 1
  angle = start_angle - 2 * pi * year_fraction
  radius = inner_radius + spiral_fraction * ring_spacing

  data.table::data.table(
    spiral_fraction = spiral_fraction,
    x = radius * cos(angle),
    y = radius * sin(angle)
  )
}

build_spiral_month_spokes = function(
  year_levels,
  inner_radius = 1.15,
  ring_spacing = 0.92,
  start_angle = pi / 2
) {
  month_guides = build_circular_month_guides()
  outer_radius = inner_radius + length(year_levels) * ring_spacing

  month_guides[, angle_start := start_angle - 2 * pi * theta_start]
  month_guides[, angle_label := start_angle - 2 * pi * theta_label]
  month_guides[, `:=`(
    x = inner_radius * cos(angle_start),
    y = inner_radius * sin(angle_start),
    xend = outer_radius * cos(angle_start),
    yend = outer_radius * sin(angle_start),
    xlab = (outer_radius + 0.42) * cos(angle_label),
    ylab = (outer_radius + 0.42) * sin(angle_label)
  )]

  month_guides[]
}

estimate_spiral_calendar_line_length = function(segment_width, ring_spacing) {
  # Approximate a line length in spiral data units from the rendered stroke width.
  estimated_band_width = ring_spacing * (0.085 + 0.042 * segment_width)
  max(ring_spacing * 0.12, estimated_band_width * 1.2)
}

build_spiral_calendar_lines = function(
  year_levels,
  inner_radius = 1.15,
  ring_spacing = 0.92,
  start_angle = pi / 2,
  months = c(1, 3, 5, 7, 9, 11),
  line_length = 0.25
) {
  months = sort(unique(as.integer(months)))
  months = months[is.finite(months) & months >= 1 & months <= 12]

  if (!length(year_levels) || !length(months) || !isTRUE(line_length > 0)) {
    return(data.table::data.table())
  }

  data.table::rbindlist(
    lapply(seq_along(year_levels), function(year_id) {
      year = year_levels[year_id]
      year_start = as.POSIXct(
        sprintf("%04d-01-01 00:00:00", year),
        tz = "UTC"
      )
      next_year_start = as.POSIXct(
        sprintf("%04d-01-01 00:00:00", year + 1),
        tz = "UTC"
      )
      month_starts = as.POSIXct(
        sprintf("%04d-%02d-01 00:00:00", year, months),
        tz = "UTC"
      )
      year_fraction = as.numeric(
        difftime(month_starts, year_start, units = "secs")
      ) / as.numeric(
        difftime(next_year_start, year_start, units = "secs")
      )
      angle = start_angle - 2 * pi * year_fraction
      radius = inner_radius + ((year_id - 1) + year_fraction) * ring_spacing

      data.table::data.table(
        year = year,
        month = months,
        x = (radius - line_length / 2) * cos(angle),
        y = (radius - line_length / 2) * sin(angle),
        xend = (radius + line_length / 2) * cos(angle),
        yend = (radius + line_length / 2) * sin(angle)
      )
    }),
    use.names = TRUE,
    fill = TRUE
  )
}

build_spiral_year_labels = function(
  year_levels,
  inner_radius = 1.15,
  ring_spacing = 0.92,
  start_angle = pi / 2
) {
  radius = inner_radius + ((seq_along(year_levels) - 1) * ring_spacing) - 0.12

  data.table::data.table(
    year = year_levels,
    x = radius * cos(start_angle),
    y = radius * sin(start_angle)
  )
}

build_spiral_background_circle = function(radius, n = 360) {
  theta = seq(0, 2 * pi, length.out = n + 1)

  data.table::data.table(
    x = radius * cos(theta),
    y = radius * sin(theta)
  )
}

make_spiral_gtime = function(
  ctdf,
  title = NULL,
  inner_radius = 1.15,
  ring_spacing = 0.92,
  samples_per_year = 720,
  segment_width = 4.6,
  segment_linewidth = NULL,
  bare = FALSE,
  calendar_line_months = c(1, 3, 5, 7, 9, 11),
  calendar_line_color = scales::alpha("white", 0.74),
  calendar_line_linewidth = 0.45,
  calendar_line_length = NULL
) {
  if (!is.null(segment_linewidth)) {
    segment_width = segment_linewidth
  }

  spiral_df = build_spiral_gtime_df(
    ctdf = ctdf,
    inner_radius = inner_radius,
    ring_spacing = ring_spacing,
    samples_per_year = samples_per_year
  )

  if (!nrow(spiral_df)) {
    return(ggplot2::ggplot() + ggplot2::theme_void())
  }

  connector_df = build_spiral_connector_df(
    ctdf = ctdf,
    inner_radius = inner_radius,
    ring_spacing = ring_spacing,
    samples_per_year = samples_per_year
  )
  year_levels = sort(unique(spiral_df$year))
  guide_path = build_spiral_reference_path(
    n_years = length(year_levels),
    inner_radius = inner_radius,
    ring_spacing = ring_spacing
  )
  month_guides = build_spiral_month_spokes(
    year_levels = year_levels,
    inner_radius = inner_radius,
    ring_spacing = ring_spacing
  )
  year_labels = build_spiral_year_labels(
    year_levels = year_levels,
    inner_radius = inner_radius,
    ring_spacing = ring_spacing
  )
  if (is.null(calendar_line_length)) {
    calendar_line_length = estimate_spiral_calendar_line_length(
      segment_width = segment_width,
      ring_spacing = ring_spacing
    )
  }
  calendar_lines = build_spiral_calendar_lines(
    year_levels = year_levels,
    inner_radius = inner_radius,
    ring_spacing = ring_spacing,
    months = calendar_line_months,
    line_length = calendar_line_length
  )

  scc = viridis::scale_color_viridis(
    discrete = TRUE,
    option = "turbo",
    begin = 0.1,
    end = 0.95
  )

  background_fill = NA

  x_values = c(
    spiral_df$x,
    connector_df$x,
    guide_path$x,
    month_guides$x,
    month_guides$xend,
    calendar_lines$x,
    calendar_lines$xend
  )
  y_values = c(
    spiral_df$y,
    connector_df$y,
    guide_path$y,
    month_guides$y,
    month_guides$yend,
    calendar_lines$y,
    calendar_lines$yend
  )

  if (!bare) {
    x_values = c(x_values, month_guides$xlab, year_labels$x)
    y_values = c(y_values, month_guides$ylab, year_labels$y)
  }

  plot_padding = max(
    0.14,
    calendar_line_length * 0.7,
    ring_spacing * 0.12
  )
  if (!bare) {
    plot_padding = plot_padding + 0.12
  }
  background_radii = c(
    sqrt(spiral_df$x ^ 2 + spiral_df$y ^ 2),
    sqrt(connector_df$x ^ 2 + connector_df$y ^ 2),
    sqrt(guide_path$x ^ 2 + guide_path$y ^ 2),
    sqrt(month_guides$xend ^ 2 + month_guides$yend ^ 2),
    sqrt(calendar_lines$x ^ 2 + calendar_lines$y ^ 2),
    sqrt(calendar_lines$xend ^ 2 + calendar_lines$yend ^ 2)
  )
  background_circle = build_spiral_background_circle(
    radius = max(background_radii, na.rm = TRUE) + max(0.05, plot_padding * 0.22)
  )

  p = ggplot2::ggplot()

  if (!bare) {
    p = p +
      ggplot2::geom_path(
      data = guide_path,
      ggplot2::aes(x = x, y = y),
      inherit.aes = FALSE,
      color = scales::alpha("grey55", 0.32),
      linewidth = 0.35,
      lineend = "round"
      ) +
      ggplot2::geom_segment(
        data = month_guides,
        ggplot2::aes(x = x, y = y, xend = xend, yend = yend),
        inherit.aes = FALSE,
        color = scales::alpha("grey45", 0.34),
        linewidth = 0.25
      )
  }

  p = p +
    ggplot2::geom_polygon(
      data = background_circle,
      ggplot2::aes(x = x, y = y),
      inherit.aes = FALSE,
      fill = "white",
      color = NA
    ) +
    ggplot2::geom_path(
      data = connector_df,
      ggplot2::aes(x = x, y = y, group = connector_id),
      inherit.aes = FALSE,
      color = scales::alpha("black", 0.72),
      linewidth = 0.5,
      lineend = "round",
      linejoin = "round"
    ) +
    ggplot2::geom_path(
      data = spiral_df,
      ggplot2::aes(x = x, y = y, group = segment_id),
      inherit.aes = FALSE,
      color = "white",
      linewidth = segment_width + 1.1,
      lineend = "butt",
      linejoin = "mitre",
      alpha = 0.92
    ) +
    ggplot2::geom_path(
      data = spiral_df,
      ggplot2::aes(x = x, y = y, color = Cluster, group = segment_id),
      inherit.aes = FALSE,
      linewidth = segment_width,
      lineend = "butt",
      linejoin = "mitre",
      alpha = 0.88
    ) +
    ggplot2::geom_segment(
      data = calendar_lines,
      ggplot2::aes(x = x, y = y, xend = xend, yend = yend),
      inherit.aes = FALSE,
      color = calendar_line_color,
      linewidth = calendar_line_linewidth,
      lineend = "butt",
      alpha = 0.95
    ) +
    scc +
    ggplot2::coord_equal(
      xlim = range(x_values, na.rm = TRUE) + c(-plot_padding, plot_padding),
      ylim = range(y_values, na.rm = TRUE) + c(-plot_padding, plot_padding),
      clip = "off"
    ) +
    ggplot2::theme_void() +
    ggplot2::theme(
      legend.position = "none",
      panel.background = ggplot2::element_rect(fill = background_fill, color = NA),
      plot.background = ggplot2::element_rect(fill = background_fill, color = NA),
      plot.title = ggplot2::element_text(
        hjust = 0.5,
        color = "grey15",
        size = 10,
        face = "bold"
      ),
      plot.subtitle = ggplot2::element_text(
        hjust = 0.5,
        color = "grey30",
        size = 8
      ),
      plot.margin = ggplot2::margin(0, 0, 0, 0)
    )

  if (!bare) {
    p = p +
      ggplot2::geom_text(
        data = month_guides,
        ggplot2::aes(x = xlab, y = ylab, label = month),
        inherit.aes = FALSE,
        color = "grey20",
        size = 3
      ) +
      ggplot2::geom_text(
        data = year_labels,
        ggplot2::aes(x = x, y = y, label = year),
        inherit.aes = FALSE,
        color = "grey20",
        size = 3
      ) +
      ggplot2::labs(
        title = title,
        subtitle = "1 rotation = 1 year"
      )
  }

  p
}

# Add an inset using panel-relative center coordinates where x/y in [0, 1]
# denote the inset center within the target panel.
add_centered_inset = function(
  base_plot,
  inset_plot,
  x = 0.5,
  y = 0.5,
  size = 0.3,
  width = size,
  height = size,
  align_to = "panel"
) {
  width = max(min(width, 1), 0)
  height = max(min(height, 1), 0)

  left = max(0, x - width / 2)
  right = min(1, x + width / 2)
  bottom = max(0, y - height / 2)
  top = min(1, y + height / 2)

  base_plot +
    patchwork::inset_element(
      inset_plot,
      left = left,
      bottom = bottom,
      right = right,
      top = top,
      align_to = align_to,
      clip = FALSE
    )
}

# Translating sf objects with `+ c(dx, dy)` drops the CRS, so restore it
# immediately for any derived inset geometry.
shift_sf = function(x, dx = 0, dy = 0) {
  geom_crs = sf::st_crs(x)
  sf::st_geometry(x) = sf::st_geometry(x) + c(dx, dy)
  sf::st_geometry(x) = sf::st_set_crs(sf::st_geometry(x), geom_crs)
  x
}

make_globe_overlay = function(n = 420, color_hex, alpha_fun) {
  xs = seq(-1, 1, length.out = n)
  ys = seq(1, -1, length.out = n)
  grid = expand.grid(x = xs, y = ys)
  radius = sqrt(grid$x ^ 2 + grid$y ^ 2)
  alpha = alpha_fun(grid$x, grid$y, radius)
  alpha[!is.finite(alpha)] = 0
  alpha[radius > 1] = 0

  rgb_base = grDevices::col2rgb(color_hex) / 255
  rgba = grDevices::rgb(
    rgb_base[1],
    rgb_base[2],
    rgb_base[3],
    alpha = pmin(pmax(alpha, 0), 1)
  )
  rgba[radius > 1] = "#FFFFFF00"

  grDevices::as.raster(matrix(rgba, nrow = n, ncol = n, byrow = TRUE))
}

sf_polygons_to_df = function(x, keep_cols = character()) {
  if (!nrow(x)) {
    return(data.table::data.table())
  }

  geom_crs = sf::st_crs(x)

  data.table::rbindlist(
    lapply(seq_len(nrow(x)), function(i) {
      geom = sf::st_geometry(x)[[i]]

      if (isTRUE(sf::st_is_empty(geom))) {
        return(NULL)
      }

      poly_parts = suppressWarnings(
        sf::st_cast(sf::st_sfc(geom, crs = geom_crs), "POLYGON")
      )

      if (!length(poly_parts)) {
        return(NULL)
      }

      data.table::rbindlist(
        lapply(seq_along(poly_parts), function(j) {
          coords = sf::st_coordinates(poly_parts[j])
          level_cols = setdiff(colnames(coords), c("X", "Y"))
          ring_id = if (length(level_cols)) {
            coords[, level_cols[length(level_cols)]]
          } else {
            rep(1, nrow(coords))
          }

          out = data.table::data.table(
            x = coords[, "X"],
            y = coords[, "Y"],
            group = paste(i, j, ring_id, sep = "_")
          )

          for (col in keep_cols) {
            out[[col]] = x[[col]][i]
          }

          out[]
        }),
        use.names = TRUE,
        fill = TRUE
      )
    }),
    use.names = TRUE,
    fill = TRUE
  )
}

make_globe_inset = function(focus_bbox) {
  world = rnaturalearth::ne_countries(scale = "medium", returnclass = "sf")
  focus_bbox_wgs84 = sf::st_as_sfc(focus_bbox) |>
    sf::st_transform(4326)
  focus_center = sf::st_bbox(focus_bbox_wgs84)
  focus_lonlat = c(
    mean(c(focus_center[["xmin"]], focus_center[["xmax"]])),
    mean(c(focus_center[["ymin"]], focus_center[["ymax"]]))
  )
  globe_crs = sprintf(
    "+proj=ortho +lon_0=%s +lat_0=%s +x_0=0 +y_0=0",
    focus_lonlat[1],
    focus_lonlat[2]
  )

  earth_radius = 6378137
  globe_circle = sf::st_sfc(sf::st_point(c(0, 0)), crs = globe_crs) |>
    sf::st_buffer(earth_radius)

  world_ortho = suppressWarnings(sf::st_transform(world, globe_crs))
  world_ortho = world_ortho[!sf::st_is_empty(world_ortho), ]

  focus_point = sf::st_sfc(sf::st_point(focus_lonlat), crs = 4326) |>
    sf::st_transform(globe_crs)

  shadow_specs = data.frame(
    expand = c(0.055, 0.035, 0.015),
    alpha = c(0.03, 0.05, 0.08)
  )
  shadow_layers = lapply(seq_len(nrow(shadow_specs)), function(i) {
    shadow = sf::st_sf(
      alpha = shadow_specs$alpha[i],
      geometry = sf::st_buffer(globe_circle, earth_radius * shadow_specs$expand[i])
    )
    shift_sf(
      shadow,
      dx = earth_radius * 0.08,
      dy = -earth_radius * 0.11
    )
  })
  shadow_sf = do.call(rbind, shadow_layers)
  sf::st_crs(shadow_sf) = globe_crs
  shadow_df = sf_polygons_to_df(shadow_sf, keep_cols = "alpha")
  globe_circle_df = sf_polygons_to_df(sf::st_sf(geometry = globe_circle))
  world_df = sf_polygons_to_df(world_ortho)
  focus_point_df = data.frame(
    x = sf::st_coordinates(focus_point)[1, "X"],
    y = sf::st_coordinates(focus_point)[1, "Y"]
  )

  globe_shade = make_globe_overlay(
    color_hex = "#87939d",
    alpha_fun = function(x, y, radius) {
      rim = pmax(0, (radius - 0.58) / 0.42)
      0.12 * exp(-(((x - 0.44) / 0.78) ^ 2 + ((y + 0.32) / 0.6) ^ 2)) +
        0.14 * rim ^ 1.8
    }
  )
  globe_highlight = make_globe_overlay(
    color_hex = "#ffffff",
    alpha_fun = function(x, y, radius) {
      0.38 * exp(-(((x + 0.22) / 1.05) ^ 2 + ((y - 0.28) / 0.95) ^ 2))
    }
  )

  ggplot2::ggplot() +
    ggplot2::geom_polygon(
      data = shadow_df,
      ggplot2::aes(x = x, y = y, group = group, alpha = alpha),
      fill = "#535c65",
      color = NA,
      show.legend = FALSE
    ) +
    ggplot2::scale_alpha_identity() +
    ggplot2::geom_polygon(
      data = globe_circle_df,
      ggplot2::aes(x = x, y = y, group = group),
      fill = "#dce7ef",
      color = NA,
      linewidth = 0,
      inherit.aes = FALSE
    ) +
    ggplot2::geom_polygon(
      data = world_df,
      ggplot2::aes(x = x, y = y, group = group),
      fill = "#b6bac0",
      color = NA,
      inherit.aes = FALSE
    ) +
    ggplot2::annotation_raster(
      raster = globe_shade,
      xmin = -earth_radius,
      xmax = earth_radius,
      ymin = -earth_radius,
      ymax = earth_radius,
      interpolate = TRUE
    ) +
    ggplot2::annotation_raster(
      raster = globe_highlight,
      xmin = -earth_radius,
      xmax = earth_radius,
      ymin = -earth_radius,
      ymax = earth_radius,
      interpolate = TRUE
    ) +
    ggplot2::geom_point(
      data = focus_point_df,
      ggplot2::aes(x = x, y = y),
      shape = 21,
      size = 1.5,
      stroke = 0.45,
      fill = "#a53a35",
      color = "white",
      alpha = 0.95
    ) +
    ggplot2::geom_path(
      data = globe_circle_df,
      ggplot2::aes(x = x, y = y, group = group),
      color = "#b8c2ca",
      linewidth = 0,
      inherit.aes = FALSE
    ) +
    ggplot2::coord_equal(
      xlim = c(-earth_radius * 1.12, earth_radius * 1.15),
      ylim = c(-earth_radius * 1.18, earth_radius * 1.12),
      expand = FALSE,
      clip = "off"
    ) +
    ggplot2::theme_void() +
    ggplot2::theme(
      panel.background = ggplot2::element_rect(fill = NA, color = NA),
      plot.background = ggplot2::element_rect(fill = NA, color = NA)
    )
}

#endregion

#region panels

make_fig3_panel_crs = function(x) {
  make_relief_panel_crs(
    x,
    projection = LBDO_RELIEF_TEST_PROJECTION,
    lon0 = LBDO_RELIEF_TEST_LON0,
    lat0 = LBDO_RELIEF_TEST_LAT0,
    aea_lat1 = LBDO_RELIEF_TEST_AEA_LAT1,
    aea_lat2 = LBDO_RELIEF_TEST_AEA_LAT2,
    aea_lat1_prop = LBDO_RELIEF_TEST_AEA_LAT1_PROP,
    aea_lat2_prop = LBDO_RELIEF_TEST_AEA_LAT2_PROP
  )
}

ruff2_crs = make_fig3_panel_crs(ruff2)
ruff_crs = ruff2_crs
lbdo_crs = make_fig3_panel_crs(lbdo)
nola_crs = make_fig3_panel_crs(nola)

top_specs = list(
  list(ctdf = ruff, crs = ruff_crs, x_pad = 0.06, y_pad = 0.10),
  list(ctdf = ruff2, crs = ruff2_crs, x_pad = 0.06, y_pad = 0.10),
  list(
    ctdf = lbdo,
    crs = lbdo_crs,
    x_pad = 0.10,
    y_pad = 0.10
  )
)

top_target_ratio = max(
  0.78,
  median(
    vapply(
      top_specs,
      function(spec) {
        panel_ratio_in_crs(
          ctdf = spec$ctdf,
          plot_crs = sf::st_crs(spec$crs),
          x_pad = spec$x_pad,
          y_pad = spec$y_pad
        )
      },
      numeric(1)
    )
  )
)

### make maps ----
gruff2_map = make_fig_map(
  ruff2,
  crs = ruff2_crs,
  scloc = "br",
  x_pad = 0.06,
  y_pad = 0.10,
  target_ratio = top_target_ratio,
  terrain_zoom = 4,
  terrain_alpha = 0.56,
  min_shade = 0.55,
  disagg_factor = 1,
  lake_fill = "#5d84c7",
  lake_alpha = 0.2,
  river_color = "#5d84c7",
  river_alpha = 0.2,
  coast_color = "grey80",
  noncluster_point_alpha = 0.5,
  noncluster_point_color = "grey40",
  noncluster_point_shape = 16
)

gruff1_map = make_fig_map(
  ruff,
  crs = ruff_crs,
  scloc = "br",
  x_pad = 0.06,
  y_pad = 0.10,
  request_ymax_pad = 0.18,
  target_ratio = top_target_ratio,
  terrain_zoom = 4,
  terrain_alpha = 0.56,
  min_shade = 0.55,
  disagg_factor = 1,
  request_x_pad = 0.12,
  request_y_pad = 0.1,
  basemap_override = gruff2_map$basemap,
  lake_fill = "#5d84c7",
  lake_alpha = 0.2,
  river_color = "#5d84c7",
  river_alpha = 0.2,
  coast_color = "grey80",
  noncluster_point_alpha = 0.5,
  noncluster_point_color = "grey40",
  noncluster_point_shape = 19
)

glbdo_map =
  make_fig_map(
  lbdo,
  crs = lbdo_crs,
  scloc = "bl",
  ymax_pad = 0.03,
  ymin_pad = 0.1,
  xmax_pad = 0.1,
  xmin_pad = 0.19,
  # y_pad = 0.1,
  request_xmin_pad = 0.22,
  request_xmax_pad = 0.22,
  request_ymin_pad = 0.22,
  request_ymax_pad = 0.034,
  target_ratio = top_target_ratio,
  terrain_zoom = 4,
  terrain_alpha = 0.56,
  min_shade = 0.55,
  disagg_factor = 1,
  lake_fill = "#5d84c7",
  lake_alpha = 0.2,
  river_color = "#5d84c7",
  river_alpha = 0.2,
  coast_color = "grey80",
  noncluster_point_alpha = 0.5,
  noncluster_point_color = "grey40",
  noncluster_point_shape = 19
)

gnola_map =
  make_fig_map(
  nola,
  crs = nola_crs,
  scloc = "tl",
  x_pad = 0.20,
  y_pad = 0.20,
  scalebar_distance_km = 50,
  terrain_zoom = 10,
  terrain_alpha = 0.52,
  min_shade = 0.58,
  disagg_factor = 2,
  show_lakes = FALSE,
  show_rivers = FALSE,
  noncluster_point_alpha = 0.5,
  noncluster_point_color = "grey40",
  noncluster_point_shape = 19
)

gruff1 = gruff1_map$plot + ggplot2::theme(plot.margin = ggplot2::margin(2, 2, 2, 2))
gruff2 = gruff2_map$plot + ggplot2::theme(plot.margin = ggplot2::margin(2, 2, 2, 2))
glbdo = glbdo_map$plot + ggplot2::theme(plot.margin = ggplot2::margin(2, 2, 2, 2))
gnola = gnola_map$plot + ggplot2::theme(plot.margin = ggplot2::margin(2, 2, 2, 2))
nola_globe_inset = make_globe_inset(gnola_map$extent)

# Panel-relative inset centers and sizes for the spiral overlays. `x = 0.5`
# and `y = 0.5` place the spiral in the middle of the map panel.
spiral_inset_specs = list(
  ruff1 = list(x = 0.20, y = 0.8, size = 0.4, segment_width = 2),
  ruff2 = list(x = 0.20, y = 0.8, size = 0.4, segment_width = 2),
  lbdo = list(x = 0.20, y = 0.35, size = 0.4, segment_width = 2)
)

# Keep the circular timelines separate for now so they can be reviewed before
# being introduced into the figure3 patchwork layout.
gruff1_gtime_circular = make_circular_gtime(ruff, title = "ruff1")
gruff2_gtime_circular = make_circular_gtime(ruff2, title = "ruff2")
glbdo_gtime_circular = make_circular_gtime(lbdo, title = "lbdo")

gtime_circular = list(
  ruff1 = gruff1_gtime_circular,
  ruff2 = gruff2_gtime_circular,
  lbdo = glbdo_gtime_circular
)

gruff1_gtime_spiral = make_spiral_gtime(
  ruff,
  title = "ruff1",
  bare = TRUE,
  calendar_line_color = "black",
  calendar_line_linewidth = 0.2,
  calendar_line_length = 0.5,
  segment_width = spiral_inset_specs$ruff1$segment_width,
)
gruff2_gtime_spiral = make_spiral_gtime(
  ruff2,
  title = "ruff2",
  bare = TRUE,
  calendar_line_color = "black",
  calendar_line_linewidth = 0.2,
  calendar_line_length = 0.5,
  segment_width = spiral_inset_specs$ruff2$segment_width
)
glbdo_gtime_spiral = make_spiral_gtime(
  lbdo,
  title = "lbdo",
  bare = TRUE,
  calendar_line_color = "black",
  calendar_line_linewidth = 0.2,
  calendar_line_length = 0.5,
  segment_width = spiral_inset_specs$lbdo$segment_width,
)

gtime_spiral = list(
  ruff1 = gruff1_gtime_spiral,
  ruff2 = gruff2_gtime_spiral,
  lbdo = glbdo_gtime_spiral
)

gruff1 = add_centered_inset(
  gruff1,
  gruff1_gtime_spiral,
  x = spiral_inset_specs$ruff1$x,
  y = spiral_inset_specs$ruff1$y,
  size = spiral_inset_specs$ruff1$size
)
gruff2 = add_centered_inset(
  gruff2,
  gruff2_gtime_spiral,
  x = spiral_inset_specs$ruff2$x,
  y = spiral_inset_specs$ruff2$y,
  size = spiral_inset_specs$ruff2$size
)
glbdo = add_centered_inset(
  glbdo,
  glbdo_gtime_spiral,
  x = spiral_inset_specs$lbdo$x,
  y = spiral_inset_specs$lbdo$y,
  size = spiral_inset_specs$lbdo$size
)
gnola = gnola +
  patchwork::inset_element(
    nola_globe_inset,
    left = 0.8,
    bottom = 0.3,
    right = 1.1,
    top = 0.985,
    align_to = "panel",
    clip = FALSE
  )

top_row_height = 1 / (3 * top_target_ratio + 0.06)
bottom_row_height = 1 / bbox_ratio(gnola_map$extent)
row_heights = c(top_row_height, bottom_row_height)
figure3_gap_width = 0.0 / top_target_ratio

figure3_layout = "
A#B#G
NNNNN
"

gg =
  patchwork::wrap_plots(
    A = gruff1,
    B = gruff2,
    G = glbdo,
    N = gnola,
    design = figure3_layout
  ) +
  patchwork::plot_layout(
    widths = c(1, -0.11, 1, -0.11, 1),
    heights = row_heights
  )# +
  # patchwork::plot_annotation(tag_levels = "a") &
  # ggplot2::theme(
  #   plot.tag.position = c(0.02, 0.95)
  # )

output_dir = if (dir.exists(here::here("MANUSCRIPT"))) {
  here::here("MANUSCRIPT")
} else {
  here::here("figs")
}

dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

outfile = file.path(output_dir, "figure3_b.png")
fig_width = 7
fig_height = fig_width * sum(row_heights)

ggplot2::ggsave(
  filename = outfile,
  plot = gg,
  device = ragg::agg_png,
  width = fig_width,
  height = fig_height,
  units = "in",
  dpi = 600
)

#endregion
