sapply(
  c(
    "data.table",
    "here",
    "dplyr",
    "sf",
    "terra",
    "elevatr",
    "rnaturalearth",
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

  if (nrow(rivers) > 0) {
    rivers = suppressWarnings(sf::st_transform(rivers, plot_crs))
  }

  if (nrow(lakes) > 0) {
    lakes = suppressWarnings(sf::st_transform(lakes, plot_crs))
  }

  list(rivers = rivers, lakes = lakes)
}

map_background = function(terrain, rivers, lakes, extent_geom = NULL) {
  p = ggplot2::ggplot() +
    ggplot2::theme(
      panel.background = ggplot2::element_rect(fill = "white", color = NA),
      plot.background = ggplot2::element_rect(fill = "white", color = NA)
    )

  if (!is.null(extent_geom)) {
    p = p +
      ggspatial::layer_spatial(extent_geom, fill = NA, color = NA)
  }

  if (!is.null(terrain)) {
    p = p +
      ggplot2::annotation_raster(
        raster = terrain$image,
        xmin = terrain$xmin,
        xmax = terrain$xmax,
        ymin = terrain$ymin,
        ymax = terrain$ymax,
        interpolate = TRUE
      )
  }

  if (nrow(lakes) > 0) {
    p = p +
      ggspatial::annotation_spatial(
        lakes,
        fill = scales::alpha("#698ecf", 0.5),
        color = NA
      )
  }

  if (nrow(rivers) > 0) {
    p = p +
      ggspatial::annotation_spatial(
        rivers,
        color = scales::alpha("#698ecf", 0.8),
        alpha = 0.7,
        linewidth = 0.16
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
  target_ratio = NULL,
  terrain_zoom = 6,
  terrain_alpha = 0.5,
  min_shade = 0.58,
  disagg_factor = 1,
  hydro_scale = 10
) {
  request_geoms_wgs84 = panel_request_geoms_wgs84(
    ctdf,
    x_pad = x_pad,
    y_pad = y_pad
  )
  plot_crs = sf::st_crs(crs)
  ctdf = data.table::copy(ctdf)
  ctdf = transform_sf_columns(ctdf, plot_crs)
  data.table::set(ctdf, j = "Cluster", value = factor(ctdf[["cluster"]]))

  map_extent = track_extent_in_crs(
    ctdf = ctdf,
    plot_crs = plot_crs,
    x_pad = x_pad,
    y_pad = y_pad,
    target_ratio = target_ratio
  )

  hydro = get_panel_hydro(
    request_geoms_wgs84 = request_geoms_wgs84,
    plot_crs = plot_crs,
    scale = hydro_scale
  )
  terrain = make_terrain_annotation(
    request_geoms_wgs84 = request_geoms_wgs84,
    bbox_proj = map_extent,
    target_crs = plot_crs,
    zoom = terrain_zoom,
    terrain_alpha = terrain_alpha,
    min_shade = min_shade,
    disagg_factor = disagg_factor
  )

  ss = summarise_ctdf(ctdf)
  ss = transform_sf_columns(ss, plot_crs)
  data.table::set(ss, j = "Cluster", value = factor(ss[["cluster"]]))
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
        terrain = terrain,
        rivers = hydro$rivers,
        lakes = hydro$lakes,
        extent_geom = sf::st_as_sfc(map_extent)
      ) +
      ggspatial::annotation_spatial(
        sf::st_as_sf(ctdf[cluster == 0]),
        alpha = 0.5,
        color = "grey30",
        size = 2
      ) +
      ggspatial::layer_spatial(
        sf::st_as_sf(ctdf[cluster == 0] |> as_ctdf_track()),
        linewidth = 0.2,
        alpha = 0.5
      ) +
      ggspatial::annotation_spatial(
        sf::st_as_sf(ss[, .(Cluster, site_poly)]),
        ggplot2::aes(fill = Cluster, color = Cluster),
        alpha = 0.3
      ) +
      ggspatial::layer_spatial(
        sf::st_as_sf(ctdf[cluster > 0]),
        ggplot2::aes(fill = Cluster),
        color = "white",
        shape = 21,
        alpha = 0.35,
        size = 2
      ) +
      scf +
      scc +
      ggspatial::annotation_scale(height = grid::unit(0.15, "cm"), location = scloc) +
      tt +
      coord_from_geom(sf::st_as_sfc(map_extent)),
    extent = map_extent
  )
}

#endregion

#region panels

ruff_crs = make_local_lcc_crs(ruff)
ruff2_crs = make_local_lcc_crs(ruff2)
lbdo_crs = make_local_lcc_crs(lbdo)
nola_crs = make_local_lcc_crs(nola)

top_specs = list(
  list(ctdf = ruff, crs = ruff_crs, x_pad = 0.06, y_pad = 0.10),
  list(ctdf = ruff2, crs = ruff2_crs, x_pad = 0.06, y_pad = 0.10),
  list(ctdf = lbdo, crs = lbdo_crs, x_pad = 0.12, y_pad = 0.10)
)

top_target_ratio = max(
  0.78,
  median(
    vapply(
      top_specs,
      function(spec) {
        bbox_ratio(
          track_extent_in_crs(
            spec$ctdf,
            sf::st_crs(spec$crs),
            x_pad = spec$x_pad,
            y_pad = spec$y_pad
          )
        )
      },
      numeric(1)
    )
  )
)

### make maps ----
gruff1_map =
  make_fig_map(
  ruff,
  crs = ruff_crs,
  scloc = "br",
  x_pad = 0.06,
  y_pad = 0.10,
  target_ratio = top_target_ratio,
  terrain_zoom = 7,
  terrain_alpha = 0.56,
  min_shade = 0.55,
  disagg_factor = 1
)

gruff2_map = make_fig_map(
  ruff2,
  crs = ruff2_crs,
  scloc = "br",
  x_pad = 0.06,
  y_pad = 0.10,
  target_ratio = top_target_ratio,
  terrain_zoom = 7,
  terrain_alpha = 0.56,
  min_shade = 0.55,
  disagg_factor = 1
)

# glbdo_map =
  make_fig_map(
  lbdo,
  crs = lbdo_crs,
  scloc = "bl",
  x_pad = 0.35,
  y_pad = 0.20,
  target_ratio = top_target_ratio,
  terrain_zoom = 4,
  terrain_alpha = 0.56,
  min_shade = 0.55,
  disagg_factor = 1
)

gnola_map = make_fig_map(
  nola,
  crs = nola_crs,
  scloc = "br",
  x_pad = 0.20,
  y_pad = 0.20,
  terrain_zoom = 9,
  terrain_alpha = 0.52,
  min_shade = 0.58,
  disagg_factor = 2
)

gruff1 = gruff1_map$plot + ggplot2::theme(plot.margin = ggplot2::margin(2, 2, 2, 2))
gruff2 = gruff2_map$plot + ggplot2::theme(plot.margin = ggplot2::margin(2, 2, 2, 2))
glbdo = glbdo_map$plot + ggplot2::theme(plot.margin = ggplot2::margin(2, 2, 2, 2))
gnola = gnola_map$plot + ggplot2::theme(plot.margin = ggplot2::margin(2, 2, 2, 2))

top_row =
  patchwork::wrap_plots(gruff1, gruff2, glbdo, ncol = 3) +
  patchwork::plot_layout(widths = c(1, 1, 1))

top_row_height = 1 / (3 * top_target_ratio)
bottom_row_height = 1 / bbox_ratio(gnola_map$extent)
row_heights = c(top_row_height, bottom_row_height)

gg =
  patchwork::wrap_plots(top_row, gnola, ncol = 1) +
  patchwork::plot_layout(heights = row_heights) +
  patchwork::plot_annotation(tag_levels = "a") &
  ggplot2::theme(
    plot.tag.position = c(0.02, 0.95)
  )

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
