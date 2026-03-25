# PACKAGES, SETTINGS
sapply(
  c(
    "data.table",
    "here",
    "dplyr",
    "sf",
    "terra",
    "rnaturalearth",
    "maptiles",
    "tidyterra",
    "ggspatial",
    "ggplot2",
    "ggmap",
    "patchwork",
    "clusterTrack",
    "clusterTrack.Vis"
  ),
  require,
  character.only = TRUE,
  quietly = TRUE
)

# Quick smoke test for the Esri hillshade path. Set to TRUE to render a small,
# low-resolution Mt Taranaki map before building the main figure.
RUN_HILLSHADE_TEST = TRUE

if (RUN_HILLSHADE_TEST && requireNamespace("maptiles", quietly = TRUE)) {
  taranaki_pt = sf::st_sfc(sf::st_point(c(174.063, -39.297)), crs = 4326)
  taranaki_lcc = sf::st_transform(
    sf::st_buffer(sf::st_transform(taranaki_pt, 2193), 30000),
    2193
  )
  taranaki_hillshade = maptiles::get_tiles(
    x = taranaki_lcc,
    provider = "Esri.WorldShadedRelief",
    zoom = 6,
    crop = TRUE,
    project = TRUE
  )

  print(
    ggplot() +
      tidyterra::geom_spatraster_rgb(
        data = taranaki_hillshade,
        r = 1,
        g = 2,
        b = 3,
        alpha = 0.35,
        interpolate = TRUE
      ) +
      geom_sf(data = sf::st_as_sf(taranaki_lcc), fill = NA, color = "black", linewidth = 0.2) +
      coord_sf(crs = sf::st_crs(taranaki_lcc)) +
      theme_void()
  )
}

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

#region MAPPING FUNCTION

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
  pad_prop = 0,
  densify_segments = 60
) {
  bbox_geom = if (inherits(bbox_proj, "bbox")) {
    sf::st_as_sfc(bbox_proj)
  } else if (inherits(bbox_proj, "sfc")) {
    bbox_proj
  } else {
    sf::st_as_sfc(bbox_proj)
  }

  # Densify the projected panel outline before transforming it to lon/lat.
  # For the local LCC panels, using only the four corners can undershoot the
  # true geographic footprint of the panel and leave triangular DEM gaps.
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
    bbox_wgs84 = pad_bbox(sf::st_as_sfc(bbox_wgs84), x_prop = pad_prop, y_prop = pad_prop)
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

map_background = function(
  hillshade = NULL,
  land,
  coast,
  lakes,
  rivers,
  extent_geom = NULL,
  satellite = NULL,
  ocean_fill = "white"
) {
  p = ggplot() +
    theme(
      panel.background = element_rect(fill = ocean_fill, color = NA),
      plot.background = element_rect(fill = ocean_fill, color = NA)
    )

  if (!is.null(extent_geom)) {
    p = p +
      layer_spatial(extent_geom, fill = NA, color = NA)
  }

  if (!is.null(hillshade)) {
    p = p +
      tidyterra::geom_spatraster_rgb(
        data = hillshade,
        r = 1,
        g = 2,
        b = 3,
        alpha = 0.8,
        interpolate = TRUE
      )
  }

  if (is.null(hillshade) && nrow(land) > 0) {
    p = p +
      annotation_spatial(
        land,
        fill = "grey70",
        color = NA
      )
  }

  if (!is.null(satellite)) {
    satellite_tiles = if (all(c("image", "xmin", "xmax", "ymin", "ymax") %in% names(satellite))) {
      list(satellite)
    } else {
      satellite
    }

    for (sat_tile in satellite_tiles) {
      p = p +
        annotation_raster(
          raster = sat_tile$image,
          xmin = sat_tile$xmin,
          xmax = sat_tile$xmax,
          ymin = sat_tile$ymin,
          ymax = sat_tile$ymax,
          interpolate = TRUE
        )
    }
  }

  if (nrow(lakes) > 0) {
    p = p +
      annotation_spatial(
        lakes,
        fill = scales::alpha("#698ecf", 0.4),
        color = NA
      )
  }

  if (nrow(coast) > 0) {
    p = p +
      annotation_spatial(
        coast,
        color = "grey80",
        linewidth = 0.25
      )
  }

  if (nrow(rivers) > 0) {
    p = p +
      annotation_spatial(
        rivers,
        color = scales::alpha("#698ecf", 0.4),
        alpha = 0.4,
        linewidth = 0.25
      )
  }

  p
}

get_hillshade_basemap = function(
  extent_geom,
  zoom = 4,
  provider = "Esri.WorldShadedRelief",
  land_mask = NULL
) {
  if (!requireNamespace("maptiles", quietly = TRUE)) {
    return(NULL)
  }

  hillshade = tryCatch(
    maptiles::get_tiles(
      x = extent_geom,
      provider = provider,
      zoom = zoom,
      crop = TRUE,
      project = TRUE
    ),
    error = function(e) NULL
  )

  if (is.null(hillshade)) {
    return(NULL)
  }

  if (terra::nlyr(hillshade) == 1) {
    hillshade = c(hillshade, hillshade, hillshade)
  }

  if (!is.null(land_mask) && nrow(land_mask) > 0) {
    hillshade = terra::mask(
      hillshade,
      terra::vect(sf::st_make_valid(land_mask))
    )
  }

  hillshade
}

make_satellite_annotation = function(
  bbox_wgs84,
  plot_crs,
  zoom = 10,
  alpha = 0.28,
  cover_extent = NULL
) {
  if (!requireNamespace("ggmap", quietly = TRUE)) {
    return(NULL)
  }

  has_registered_key = "has_google_key" %in% getNamespaceExports("ggmap") &&
    isTRUE(ggmap::has_google_key())
  api_key = Sys.getenv("GOOGLE_MAPS_API_KEY")
  if (!nzchar(api_key) &&
      exists("api_secret", envir = .GlobalEnv, inherits = FALSE)) {
    api_key = get("api_secret", envir = .GlobalEnv, inherits = FALSE)
  }
  if (!nzchar(api_key) && !has_registered_key) {
    return(NULL)
  }

  if (nzchar(api_key) && "register_google" %in% getNamespaceExports("ggmap")) {
    try(ggmap::register_google(key = api_key, write = FALSE), silent = TRUE)
  }

  bb = sf::st_bbox(bbox_wgs84)
  location = c(
    mean(c(bb[["xmin"]], bb[["xmax"]])),
    mean(c(bb[["ymin"]], bb[["ymax"]]))
  )

  fetch_sat = function(center, zoom_level) {
    tryCatch(
      if (nzchar(api_key)) {
        ggmap::get_map(
          location = center,
          zoom = zoom_level,
          maptype = "satellite",
          source = "google",
          api_key = api_key
        )
      } else {
        ggmap::get_map(
          location = center,
          zoom = zoom_level,
          maptype = "satellite",
          source = "google"
        )
      },
      error = function(e) NULL
    )
  }

  sat_to_annotation = function(sat) {
    sat_attrs = attributes(sat)
    sat_transparent = matrix(
      grDevices::adjustcolor(sat, alpha.f = alpha),
      nrow = nrow(sat)
    )
    attributes(sat_transparent) = sat_attrs

    sat_bb = attr(sat, "bb")
    sat_corners = sf::st_as_sf(
      data.frame(
        lon = c(sat_bb$ll.lon, sat_bb$ur.lon, sat_bb$ur.lon, sat_bb$ll.lon),
        lat = c(sat_bb$ll.lat, sat_bb$ll.lat, sat_bb$ur.lat, sat_bb$ur.lat)
      ),
      coords = c("lon", "lat"),
      crs = 4326
    ) |>
      sf::st_transform(plot_crs)
    sat_bbox = sf::st_bbox(sat_corners)

    list(
      image = as.raster(sat_transparent),
      xmin = sat_bbox[["xmin"]],
      xmax = sat_bbox[["xmax"]],
      ymin = sat_bbox[["ymin"]],
      ymax = sat_bbox[["ymax"]]
    )
  }

  build_centers = function(min_val, max_val, span, overlap = 0.92) {
    if (!is.finite(span) || span <= 0 || (max_val - min_val) <= span) {
      return((min_val + max_val) / 2)
    }

    start = min_val + span / 2
    end = max_val - span / 2
    step = span * overlap

    centers = seq(start, end, by = step)
    centers = sort(unique(c(start, centers, end)))
    centers
  }

  sample_sat = fetch_sat(location, zoom)
  if (is.null(sample_sat)) {
    return(NULL)
  }

  sample_bb = attr(sample_sat, "bb")
  tile_width = sample_bb$ur.lon - sample_bb$ll.lon
  tile_height = sample_bb$ur.lat - sample_bb$ll.lat

  lon_centers = build_centers(bb[["xmin"]], bb[["xmax"]], tile_width)
  lat_centers = build_centers(bb[["ymin"]], bb[["ymax"]], tile_height)

  annotations = list()
  tile_index = 1L

  for (lat_center in rev(lat_centers)) {
    for (lon_center in lon_centers) {
      sat = if (isTRUE(all.equal(c(lon_center, lat_center), location))) {
        sample_sat
      } else {
        fetch_sat(c(lon_center, lat_center), zoom)
      }

      if (is.null(sat)) {
        next
      }

      annotations[[tile_index]] = sat_to_annotation(sat)
      tile_index = tile_index + 1L
    }
  }

  if (length(annotations) == 0) {
    return(NULL)
  }

  if (length(annotations) == 1) {
    annotations[[1]]
  } else {
    annotations
  }
}

coord_from_geom = function(x, x_prop = 0, y_prop = x_prop) {
  bb = st_bbox(x)
  x_pad = (bb[["xmax"]] - bb[["xmin"]]) * x_prop
  y_pad = (bb[["ymax"]] - bb[["ymin"]]) * y_prop
  geom_crs = st_crs(x)

  coord_sf(
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

    if (is.na(st_crs(geom))) {
      x[[geom_col]] = suppressWarnings(st_set_crs(geom, target_crs))
    } else if (!isTRUE(all.equal(st_crs(geom), target_crs))) {
      x[[geom_col]] = suppressWarnings(st_transform(geom, target_crs))
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

  st_bbox(
    c(
      xmin = xmid - half_width,
      xmax = xmid + half_width,
      ymin = ymid - half_height,
      ymax = ymid + half_height
    ),
    crs = st_crs(bb)
  )
}

make_local_lcc_crs = function(x) {
  geom_wgs84 = st_as_sf(x) |>
    st_transform(4326)
  bb = st_bbox(geom_wgs84)

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

  sprintf(
    "+proj=lcc +lat_1=%s +lat_2=%s +lat_0=%s +lon_0=%s +x_0=0 +y_0=0 +ellps=WGS84 +units=m +no_defs",
    lat1,
    lat2,
    lat0,
    lon0
  )
}

resolve_plot_crs = function(
  ctdf,
  projection = NULL,
  crs = NULL
) {
  if (is.function(projection)) {
    return(sf::st_crs(projection(ctdf)))
  }

  if (!is.null(projection)) {
    return(sf::st_crs(projection))
  }

  if (!is.null(crs)) {
    return(sf::st_crs(crs))
  }

  sf::st_crs(make_local_lcc_crs(ctdf))
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
  extent = pad_bbox(st_as_sf(ctdf_proj), x_prop = x_pad, y_prop = y_pad)

  if (!is.null(target_ratio)) {
    extent = set_bbox_aspect(extent, target_ratio = target_ratio)
  }

  extent
}

transform_basemap_layer = function(x, plot_crs) {
  suppressWarnings(sf::st_transform(x, plot_crs))
}

clip_basemap_layer = function(x, clip_extent) {
  geom_types = unique(as.character(sf::st_geometry_type(x, by_geometry = TRUE)))

  if (any(geom_types %in% c("POLYGON", "MULTIPOLYGON"))) {
    x = suppressWarnings(sf::st_make_valid(x))
  }

  x = suppressWarnings(sf::st_crop(x, sf::st_bbox(clip_extent)))

  if (any(geom_types %in% c("POLYGON", "MULTIPOLYGON"))) {
    x = suppressWarnings(sf::st_make_valid(x))
  }

  x
}

make_fig_map <- function(
  ctdf,
  crs = NULL,
  projection = NULL,
  reg = "Europe & Central Asia",
  scloc = "br",
  x_pad = 0.08,
  y_pad = 0.12,
  target_ratio = NULL,
  show_land_fill = TRUE,
  show_coast = TRUE,
  show_lakes = TRUE,
  show_rivers = TRUE,
  use_hillshade = TRUE,
  hillshade_zoom = 4,
  ocean_fill = "white",
  use_satellite = FALSE,
  satellite_zoom = 10,
  satellite_alpha = 0.28
) {
  plot_crs = resolve_plot_crs(
    ctdf = ctdf,
    projection = projection,
    crs = crs
  )
  ctdf = data.table::copy(ctdf)
  ctdf = transform_sf_columns(ctdf, plot_crs)
  ctdf[, Cluster := factor(cluster)]

  map_extent = track_extent_in_crs(
    ctdf = ctdf,
    plot_crs = plot_crs,
    x_pad = x_pad,
    y_pad = y_pad,
    target_ratio = target_ratio
  )
  map_extent_wgs84 = projected_bbox_to_wgs84(map_extent)

  # Keep the basemap path intentionally simple and projection-safe:
  # transform the global vector layers into the panel CRS and let coord_sf()
  # handle the clipping. This avoids the repeated topology failures from
  # cropping/intersecting Natural Earth layers in lon/lat.
  rivers = transform_basemap_layer(rivers_world, plot_crs) |> clip_basemap_layer(map_extent)
  land = transform_basemap_layer(land_world, plot_crs) |> clip_basemap_layer(map_extent)
  coast = transform_basemap_layer(coast_world, plot_crs) |> clip_basemap_layer(map_extent)
  lakes = transform_basemap_layer(lakes_world, plot_crs) |> clip_basemap_layer(map_extent)
  hillshade = if (use_hillshade) {
    get_hillshade_basemap(
      extent_geom = st_as_sfc(map_extent),
      zoom = hillshade_zoom,
      land_mask = land
    )
  } else {
    NULL
  }
      satellite = if (use_satellite) {
        make_satellite_annotation(
          bbox_wgs84 = map_extent_wgs84,
          plot_crs = plot_crs,
          zoom = satellite_zoom,
          alpha = satellite_alpha,
          cover_extent = st_as_sfc(map_extent)
        )
      } else {
        NULL
      }

  ss = summarise_ctdf(ctdf)
  ss = transform_sf_columns(ss, plot_crs)
  ss[, Cluster := factor(cluster)]
  ss = cbind(
    ss,
    st_as_sf(ss$site_poly_center) |> st_transform(crs = plot_crs) |> st_coordinates()
  )

  tt = theme_bw() +
    theme(
      legend.position = "none",
      panel.background = element_rect(fill = "white", color = NA),
      plot.background = element_rect(fill = "white", color = NA),
      panel.grid.major = element_blank(),
      panel.grid.minor = element_blank(),
      axis.ticks = element_blank(),
      axis.text = element_blank(),
      axis.title = element_blank(),
      plot.margin = margin(2.5, 2.5, 2.5, 2.5)
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
        hillshade = hillshade,
        land = if (show_land_fill) land else land[0, ],
        coast = if (show_coast) coast else coast[0, ],
        lakes = if (show_lakes) lakes else lakes[0, ],
        rivers = if (show_rivers) rivers else rivers[0, ],
        extent_geom = st_as_sfc(map_extent),
        satellite = satellite,
        ocean_fill = ocean_fill
      ) +
      annotation_spatial(
        st_as_sf(ctdf[cluster == 0]),
        alpha = 0.5,
        color = "grey30",
        size = 2
      ) +
      layer_spatial(
        st_as_sf(ctdf[cluster == 0] |> as_ctdf_track()),
        linewidth = 0.2,
        alpha = 0.5
      ) +
      annotation_spatial(
        st_as_sf(ss[, .(Cluster, site_poly)]),
        aes(fill = Cluster, color = Cluster),
        alpha = 0.3
      ) +
      layer_spatial(
        st_as_sf(ctdf[cluster > 0]),
        aes(fill = Cluster),
        color = "white",
        shape = 21,
        alpha = 0.3,
        size = 2
      ) +
      scf +
      scc +
      annotation_scale(height = unit(0.15, "cm"), location = scloc) +
      tt +
      coord_from_geom(st_as_sfc(map_extent)),
    extent = map_extent
  )
}

#endregion

#### Vector layers to download ----
# Download once and reuse. The global river network is then cropped by bbox
# inside each panel rather than intersected, which is much more robust for
# large Natural Earth linework.
# sf::sf_use_s2(FALSE)
# rivers_world = ne_download(
#   scale = "large",
#   type = "rivers_lake_centerlines",
#   category = "physical",
#   returnclass = "sf"
# )
# land_world = ne_download(
#   scale = "large",
#   type = "land",
#   category = "physical",
#   returnclass = "sf"
# )
# coast_world = ne_download(
#   scale = "large",
#   type = "coastline",
#   category = "physical",
#   returnclass = "sf"
# )
# lakes_world = ne_download(
#   scale = "large",
#   type = "lakes",
#   category = "physical",
#   returnclass = "sf"
# )
# sf::sf_use_s2(TRUE)
#
# land_world = suppressWarnings(sf::st_make_valid(land_world))
# lakes_world = suppressWarnings(sf::st_make_valid(lakes_world))

#### make maps ----
#region ggplots
#Ignore "Warning messages": ' A shallow copy of this ... '
top_x_pad = 0.06
top_y_pad = 0.10

ruff_crs = make_local_lcc_crs(ruff)
ruff2_crs = make_local_lcc_crs(ruff2)
lbdo_crs = make_local_lcc_crs(lbdo)
nola_crs = make_local_lcc_crs(nola)

top_raw_extents = list(
  track_extent_in_crs(ruff, sf::st_crs(ruff_crs), x_pad = top_x_pad, y_pad = top_y_pad),
  track_extent_in_crs(ruff2, sf::st_crs(ruff2_crs), x_pad = top_x_pad, y_pad = top_y_pad),
  track_extent_in_crs(lbdo, sf::st_crs(lbdo_crs), x_pad = top_x_pad, y_pad = top_y_pad)
)
top_target_ratio = max(
  0.78,
  median(vapply(top_raw_extents, bbox_ratio, numeric(1)))
)

# gruff1_map =
  make_fig_map(
  ruff,
  crs = ruff_crs,
  x_pad = top_x_pad,
  y_pad = top_y_pad,
  target_ratio = top_target_ratio,
  hillshade_zoom = 7,
  show_coast = TRUE,
  show_lakes = TRUE,
  show_rivers = TRUE,
  ocean_fill = "white",
  use_hillshade = FALSE,
  show_land_fill = TRUE
)
gruff2_map = make_fig_map(
  ruff2,
  crs = ruff2_crs,
  x_pad = top_x_pad,
  y_pad = top_y_pad,
  target_ratio = top_target_ratio,
  hillshade_zoom = 5,
  show_coast = TRUE,
  show_lakes = TRUE,
  show_rivers = TRUE
)
glbdo_map = make_fig_map(
  lbdo,
  crs = lbdo_crs,
  reg = "North America",
  scloc = "bl",
  x_pad = 0.12,
  y_pad = top_y_pad,
  target_ratio = top_target_ratio,
  hillshade_zoom = 5,
  show_coast = TRUE,
  show_lakes = TRUE,
  show_rivers = TRUE
)
gnola_map = make_fig_map(
  nola,
  crs = nola_crs,
  scloc = "br",
  x_pad = 0.20,
  y_pad = 0.20,
  show_land_fill = FALSE,
  show_coast = TRUE,
  show_lakes = TRUE,
  show_rivers = TRUE,
  use_hillshade = TRUE,
  hillshade_zoom = 10,
  use_satellite = FALSE,
  satellite_zoom = 6,
  satellite_alpha = 0.5
)

gruff1 = gruff1_map$plot
gruff2 = gruff2_map$plot
glbdo = glbdo_map$plot
gnola = gnola_map$plot

map_theme = theme(
  plot.margin = margin(2, 2, 2, 2)
)

gruff1 = gruff1 + map_theme
gruff2 = gruff2 + map_theme
glbdo = glbdo + map_theme
gnola = gnola + map_theme

top_row =
  wrap_plots(gruff1, gruff2, glbdo, ncol = 3) +
  plot_layout(widths = c(1, 1, 1))

top_row_height = 1 / (3 * top_target_ratio)
bottom_row_height = 1 / bbox_ratio(gnola_map$extent)
row_heights = c(top_row_height, bottom_row_height)

gg =
  wrap_plots(top_row, gnola, ncol = 1) +
  plot_layout(heights = row_heights) +
  plot_annotation(tag_levels = "a") &
  theme(
    plot.tag.position = c(0.02, 0.95)
  )

output_dir = if (dir.exists(here::here("MANUSCRIPT"))) {
  here::here("MANUSCRIPT")
} else {
  here::here("figs")
}

dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

outfile <- file.path(output_dir, "figure3_.png")

fig_width = 7
fig_height = fig_width * sum(row_heights)

ggsave(
  filename = outfile,
  plot = gg,
  device = ragg::agg_png,
  width = fig_width,
  height = fig_height,
  units = "in",
  dpi = 600
)

# endregion

# region ctdf info

o = list(ruff, ruff2, lbdo, nola)
names(o) <- c("ruff", "ruff-gps", "lbdo", "nola")

lapply(o, \(x) {
  x[, .N, cluster] |> nrow()
})

#endregion
