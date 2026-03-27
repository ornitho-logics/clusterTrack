# Figure 2 with an Alaska terrain baselayer adapted from Luke_eudot_map_v2.R.

# PACKAGES, SETTINGS
sapply(
  c(
    "data.table",
    "here",
    "sf",
    "terra",
    "elevatr",
    "rnaturalearth",
    "ggspatial",
    "ggplot2",
    "ggrepel",
    "grid",
    "patchwork",
    "clusterTrack",
    "clusterTrack.Vis"
  ),
  require,
  character.only = TRUE,
  quietly = TRUE
)

crs = 3467 # Alaska Albers Equal Area Conic

# Small bbox helpers are reused for both map framing and DEM requests.
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

pad_bbox_sides = function(
  x,
  xmin_prop = 0.05,
  xmax_prop = xmin_prop,
  ymin_prop = xmin_prop,
  ymax_prop = ymin_prop
) {
  bb = sf::st_bbox(x)
  x_span = bb[["xmax"]] - bb[["xmin"]]
  y_span = bb[["ymax"]] - bb[["ymin"]]

  sf::st_bbox(
    c(
      xmin = bb[["xmin"]] - x_span * xmin_prop,
      ymin = bb[["ymin"]] - y_span * ymin_prop,
      xmax = bb[["xmax"]] + x_span * xmax_prop,
      ymax = bb[["ymax"]] + y_span * ymax_prop
    ),
    crs = sf::st_crs(x)
  )
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

# Terrain values are repeatedly rescaled when converting DEM and hillshade
# into a subtle RGB basemap.
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

# Download, project, and stylize a DEM for use as a raster underlay.
# The function returns an RGBA image plus its projected extent so it can
# be drawn with annotation_raster() inside a coord_sf() plot.
make_terrain_annotation = function(
  bbox_proj,
  zoom = 6,
  terrain_alpha = 0.45,
  min_shade = 0.6,
  disagg_factor = 1
) {
  bbox_wgs84 = sf::st_as_sfc(bbox_proj) |>
    sf::st_transform(4326) |>
    sf::st_bbox() |>
    sf::st_as_sfc()
  bbox_wgs84_ext = terra::ext(sf::st_bbox(bbox_wgs84))

  dem_raw = elevatr::get_elev_raster(
    locations = sf::st_sf(geometry = bbox_wgs84),
    z = zoom,
    clip = "locations"
  )

  dem = terra::rast(dem_raw)

  if (!nzchar(terra::crs(dem))) {
    terra::crs(dem) = sf::st_crs(4326)$wkt
  }

  if (extents_overlap(terra::ext(dem), bbox_wgs84_ext)) {
    dem = terra::crop(dem, bbox_wgs84_ext)
  }

  dem = terra::project(dem, sf::st_crs(crs)$wkt, method = "bilinear")

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

# Draw only the basemap layers. The biological layers are added later in
# the panel-specific plot objects.
map_background = function(terrain, extent_geom = NULL) {
  p = ggplot()

  if (!is.null(extent_geom)) {
    p = p +
      layer_spatial(extent_geom, fill = NA, color = NA)
  }

  p +
    annotation_raster(
      raster = terrain$image,
      xmin = terrain$xmin,
      xmax = terrain$xmax,
      ymin = terrain$ymin,
      ymax = terrain$ymax,
      interpolate = TRUE
    ) +
    annotation_spatial(
      rivers_ak,
      color = scales::alpha("#698ecf", 0.82),
      alpha = 0.5,
      linewidth = 0.16
    )
}

# Force a panel to use a specific geometry extent. This avoids raster layers
# silently training the panel limits in unexpected ways.
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

# clusterTrack/clusterTrack.Vis objects can carry multiple geometry columns.
# This helper keeps every spatial column in the plotting CRS before plotting.
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

# Translating sf objects with `+ c(dx, dy)` drops the CRS, so restore it
# immediately for any derived inset geometry.
shift_sf = function(x, dx = 0, dy = 0) {
  geom_crs = st_crs(x)
  st_geometry(x) = st_geometry(x) + c(dx, dy)
  st_geometry(x) = st_set_crs(st_geometry(x), geom_crs)
  x
}

# Build a soft transparent RGBA overlay used to shade the inset globe.
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

  as.raster(matrix(rgba, nrow = n, ncol = n, byrow = TRUE))
}

# Create the overview inset as an orthographic globe centered on the
# Alaska focus location rather than on a fixed global viewpoint.
make_globe_inset = function(focus_bbox) {
  world = ne_countries(scale = "medium", returnclass = "sf")
  focus_bbox_wgs84 = st_as_sfc(focus_bbox) |>
    st_transform(4326)
  focus_center = st_bbox(focus_bbox_wgs84)
  focus_lonlat = c(
    mean(c(focus_center[["xmin"]], focus_center[["xmax"]])),
    mean(c(focus_center[["ymin"]], focus_center[["ymax"]]))
  )
  globe_center = c(
    focus_lonlat[1],
    focus_lonlat[2]
  )
  globe_crs = sprintf(
    "+proj=ortho +lon_0=%s +lat_0=%s +x_0=0 +y_0=0",
    globe_center[1],
    globe_center[2]
  )

  earth_radius = 6378137
  globe_circle = st_sfc(st_point(c(0, 0)), crs = globe_crs) |>
    st_buffer(earth_radius)

  world_ortho = suppressWarnings(st_transform(world, globe_crs))
  world_ortho = suppressWarnings(st_intersection(st_make_valid(world_ortho), globe_circle))

  focus_point = st_sfc(st_point(focus_lonlat), crs = 4326) |>
    st_transform(globe_crs)

  shadow_specs = data.frame(
    expand = c(0.055, 0.035, 0.015),
    alpha = c(0.03, 0.05, 0.08)
  )
  shadow_layers = lapply(seq_len(nrow(shadow_specs)), function(i) {
    shadow = st_sf(
      alpha = shadow_specs$alpha[i],
      geometry = st_buffer(globe_circle, earth_radius * shadow_specs$expand[i])
    )
    shift_sf(
      shadow,
      dx = earth_radius * 0.08,
      dy = -earth_radius * 0.11
    )
  })
  shadow_sf = do.call(rbind, shadow_layers)
  st_crs(shadow_sf) = globe_crs

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

  ggplot() +
    geom_sf(
      data = shadow_sf,
      aes(alpha = alpha),
      fill = "#535c65",
      color = NA,
      show.legend = FALSE
    ) +
    scale_alpha_identity() +
    geom_sf(data = globe_circle, fill = "#dce7ef", color = NA, linewidth = 0) +
    geom_sf(data = world_ortho, fill = "#b6bac0", color = NA) +
    annotation_raster(
      raster = globe_shade,
      xmin = -earth_radius,
      xmax = earth_radius,
      ymin = -earth_radius,
      ymax = earth_radius,
      interpolate = TRUE
    ) +
    annotation_raster(
      raster = globe_highlight,
      xmin = -earth_radius,
      xmax = earth_radius,
      ymin = -earth_radius,
      ymax = earth_radius,
      interpolate = TRUE
    ) +
    geom_sf(
      data = st_sf(geometry = focus_point),
      shape = 21,
      size = 2.6,
      stroke = 0.45,
      fill = "black",
      color = "white",
      alpha = 0.95
    ) +
    geom_sf(data = globe_circle, fill = NA, color = "#b8c2ca", linewidth = 0) +
    coord_sf(
      crs = globe_crs,
      xlim = c(-earth_radius * 1.12, earth_radius * 1.15),
      ylim = c(-earth_radius * 1.18, earth_radius * 1.12),
      expand = FALSE,
      clip = "off"
    ) +
    theme_void() +
    theme(
      panel.background = element_rect(fill = NA, color = NA),
      plot.background = element_rect(fill = NA, color = NA)
    )
}

#
set_bbox_aspect = function(bb, target_ratio = 1) {
  # target_ratio = width / height
  xmid = (bb[["xmin"]] + bb[["xmax"]]) / 2
  ymid = (bb[["ymin"]] + bb[["ymax"]]) / 2

  width = bb[["xmax"]] - bb[["xmin"]]
  height = bb[["ymax"]] - bb[["ymin"]]
  current_ratio = width / height

  if (current_ratio < target_ratio) {
    # too tall -> widen
    new_width = height * target_ratio
    half_width = new_width / 2
    half_height = height / 2
  } else {
    # too wide -> increase height
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

#region DATA
# Track data are transformed into the plotting CRS before any summary
# geometry, bbox, or panel extent is derived from them.
data(pesa56511)
ctdf = as_ctdf(pesa56511, time = "locationDate") |> cluster_track()
ctdf = data.table::copy(ctdf)
plot_crs = sf::st_crs(crs)
ctdf = transform_sf_columns(ctdf, plot_crs)

ctdf[, Cluster := factor(cluster)]

ss = summarise_ctdf(ctdf)
ss = transform_sf_columns(ss, plot_crs)
ss[, Cluster := factor(cluster)]
ss = cbind(
  ss,
  st_as_sf(ss$site_poly_center) |> st_transform(crs) |> st_coordinates()
)

ss16 = ss[cluster %in% c(1, 6), site_poly_center] |>
  st_as_sf() |>
  st_buffer(dist = 1000 * 10)

ss23 = ss[cluster %in% c(2, 3), site_poly_center] |>
  st_as_sf() |>
  st_buffer(dist = 1000 * 5)

ss4 = ss[cluster == 4, site_poly_center] |>
  st_as_sf() |>
  st_buffer(dist = 1000 * 6)

ss5 = ss[cluster == 5, site_poly_center] |>
  st_as_sf() |>
  st_buffer(dist = 1000 * 10)

# Panel extents are defined separately from the buffered cluster polygons
# so the DEM request and the plotted window can be tuned independently.
overview_extent = pad_bbox_sides(
  st_as_sf(ctdf),
  xmin_prop = 0.12,
  xmax_prop = 0.05,
  ymin_prop = 0.34,
  ymax_prop = 0.24
)
extent_16 = set_bbox_aspect(pad_bbox(ss16, x_prop = 0.08), target_ratio = 1)
extent_23 = set_bbox_aspect(pad_bbox(ss23, x_prop = 0.05), target_ratio = 1)
extent_4  = set_bbox_aspect(pad_bbox(ss4,  x_prop = 0.05), target_ratio = 1)
extent_5  = set_bbox_aspect(pad_bbox(ss5,  x_prop = 0.3),  target_ratio = 1)
track_extent_wgs84 = st_as_sfc(overview_extent) |>
  st_transform(4326)

# Natural Earth physical layers are clipped to the overview window once and
# then reused across all panels.
sf::sf_use_s2(FALSE)
rivers_ak = ne_download(
  scale = 10,
  type = "rivers_lake_centerlines",
  category = "physical",
  returnclass = "sf"
) |>
  st_intersection(track_extent_wgs84) |>
  st_transform(crs)
sf::sf_use_s2(TRUE)

terrain_overview = make_terrain_annotation(
  overview_extent,
  zoom = 8,
  terrain_alpha = 0.58,
  min_shade = 0.54,
  disagg_factor = 2
)
terrain_16 = make_terrain_annotation(
  extent_16,
  zoom = 10,
  terrain_alpha = 0.5,
  min_shade = 0.6,
  disagg_factor = 2
)
terrain_23 = make_terrain_annotation(
  extent_23,
  zoom = 12,
  terrain_alpha = 0.5,
  min_shade = 0.6,
  disagg_factor = 2
)
terrain_4 = make_terrain_annotation(
  extent_4,
  zoom = 11,
  terrain_alpha = 0.5,
  min_shade = 0.6,
  disagg_factor = 2
)
terrain_5 = make_terrain_annotation(
  extent_5,
  zoom = 10,
  terrain_alpha = 0.5,
  min_shade = 0.6,
  disagg_factor = 2
)
globe_inset = make_globe_inset(overview_extent)

#endregion

#region Figure

# Shared theme/scales are defined once so troubleshooting style changes does
# not require editing all five panels.
tt = theme_bw(base_family = "Lato") +
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

# Summarize the occupancy period of each cluster directly from the track
# timestamps so the timeline reflects cluster entry and exit timing.
timeline_df = ctdf[
  cluster > 0,
  .(
    start = min(timestamp),
    stop = max(timestamp)
  ),
  by = cluster
][order(cluster)]
# Keep a numeric y position for the timeline while also preserving the
# discrete factor used by the shared viridis fill/color scales.
timeline_df[, cluster_id := as.integer(cluster)]
timeline_df[, Cluster := factor(cluster)]
dataset_start_timestamp = ctdf[order(timestamp)][1, timestamp]
start_cluster = ctdf[order(timestamp)][1, cluster]
start_cluster_id = if (
  is.finite(start_cluster) &&
  isTRUE(start_cluster > 0) &&
  start_cluster %in% timeline_df$cluster
) {
  timeline_df[cluster == start_cluster, cluster_id][1]
} else {
  timeline_df$cluster_id[1]
}
start_marker_y = start_cluster_id + 0.75
start_point_df = data.table::data.table(
  x = dataset_start_timestamp,
  y = start_marker_y
)
start_arrow_df = if (!is.na(dataset_start_timestamp)) {
  data.table::data.table(
    x = dataset_start_timestamp,
    xend = seq(
      from = dataset_start_timestamp,
      by = "1 days",
      length.out = 2
    )[2],
    y = start_marker_y,
    yend = start_marker_y
  )
} else {
  data.table::data.table()
}
y_upper_limit = max(
  timeline_df$cluster_id + 0.5,
  start_marker_y + 0.18,
  na.rm = TRUE
)

# Overview panel: full track context, background terrain, cluster points,
# and the globe inset. The lower insets reuse the same general layer order.
gall =
  map_background(terrain_overview) +
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
  layer_spatial(
    st_as_sf(ctdf[cluster > 0]),
    aes(fill = Cluster), color = "white", shape = 21,
    alpha = 0.3,
    size = 2
  ) +
  geom_label_repel(
    data = ss,
    aes(x = X, y = Y, label = cluster),
    alpha = 0.7,
    family = "Lato"
  ) +
  scf +
  scc +
  annotation_scale(
    location = "tl",
    height = unit(0.2, "cm"),
    text_family = "Lato"
  ) +
  tt +
  coord_from_geom(st_as_sfc(overview_extent)) +
  inset_element(
    globe_inset,
    left = 0.73,
    bottom = 0.40,
    right = 0.99,
    top = 1.03,
    align_to = "panel"
  )

g16 =
  map_background(terrain_16, ss16) +
  annotation_spatial(
    st_as_sf(ctdf[cluster == 0]),
    alpha = 0.5,
    color = "grey30",
    size = 2
  ) +
  annotation_spatial(
    st_as_sf(ctdf |> as_ctdf_track()),
    linewidth = 0.2,
    alpha = 0.5
  ) +
  annotation_spatial(
    st_as_sf(ss[, .(Cluster, site_poly)]),
    aes(fill = Cluster, color = Cluster),
    alpha = 0.3
  ) +
  annotation_spatial(
    st_as_sf(ctdf[cluster > 0]),
    aes(fill = Cluster), color = "white", shape = 21,
    alpha = 0.5,
    size = 2
  ) +
  geom_sf_label(
    data = ss[cluster %in% c(1, 6), .(site_poly_center, cluster)] |> st_as_sf(),
    aes(label = cluster),
    nudge_x = 0.1,
    alpha = 0.7,
    family = "Lato"
  ) +
  scf +
  scc +
  annotation_scale(height = unit(0.1, "cm"), text_cex = 0.5, location = "br", text_family = "Lato") +
  tt +
  coord_from_geom(st_as_sfc(extent_16))

g23 =
  map_background(terrain_23, ss23) +
  annotation_spatial(
    st_as_sf(ctdf[cluster == 0]),
    alpha = 0.5,
    color = "grey30",
    size = 2
  ) +
  annotation_spatial(
    st_as_sf(ctdf |> as_ctdf_track()),
    linewidth = 0.2,
    alpha = 0.5
  ) +
  annotation_spatial(
    st_as_sf(ss[, .(Cluster, site_poly)]),
    aes(fill = Cluster, color = Cluster),
    alpha = 0.3
  ) +
  annotation_spatial(
    st_as_sf(ctdf[cluster > 0]),
    aes(fill = Cluster), color = "white", shape = 21,
    alpha = 0.5,
    size = 2
  ) +
  geom_sf_label(
    data = ss[cluster %in% c(2, 3), .(site_poly_center, cluster)] |> st_as_sf(),
    aes(label = cluster),
    nudge_x = 0.1,
    alpha = 0.7,
    family = "Lato"
  ) +
  scf +
  scc +
  annotation_scale(height = unit(0.1, "cm"), text_cex = 0.5, text_family = "Lato") +
  tt +
  coord_from_geom(st_as_sfc(extent_23))

g4 =
  map_background(terrain_4, ss4) +
  annotation_spatial(
    st_as_sf(ctdf[cluster == 0]),
    alpha = 0.5,
    color = "grey30",
    size = 2
  ) +
  annotation_spatial(
    st_as_sf(ctdf |> as_ctdf_track()),
    linewidth = 0.2,
    alpha = 0.5
  ) +
  annotation_spatial(
    st_as_sf(ss[, .(Cluster, site_poly)]),
    aes(fill = Cluster, color = Cluster),
    alpha = 0.3
  ) +
  annotation_spatial(
    st_as_sf(ctdf[cluster > 0]),
    aes(fill = Cluster), color = "white", shape = 21,
    alpha = 0.5,
    size = 2
  ) +
  geom_sf_label(
    data = ss[cluster == 4, .(site_poly_center, cluster)] |> st_as_sf(),
    aes(label = cluster),
    nudge_x = 0.1,
    alpha = 0.7,
    family = "Lato"
  ) +
  scf +
  scc +
  annotation_scale(height = unit(0.1, "cm"), text_cex = 0.5, location = "br", text_family = "Lato") +
  tt +
  coord_from_geom(st_as_sfc(extent_4))


g5 =
  map_background(terrain_5, ss5) +
  annotation_spatial(
    st_as_sf(ctdf[cluster == 0]),
    alpha = 0.5,
    color = "grey30",
    size = 2
  ) +
  annotation_spatial(
    st_as_sf(ctdf |> as_ctdf_track()),
    linewidth = 0.2,
    alpha = 0.5
  ) +
  annotation_spatial(
    st_as_sf(ss[, .(Cluster, site_poly)]),
    aes(fill = Cluster, color = Cluster),
    alpha = 0.3
  ) +
  annotation_spatial(
    st_as_sf(ctdf[cluster > 0]),
    aes(fill = Cluster), color = "white", shape = 21,
    alpha = 0.5,
    size = 2
  ) +
  geom_sf_label(
    data = ss[cluster == 5, .(site_poly_center, cluster)] |> st_as_sf(),
    aes(label = cluster),
    nudge_x = 0.1,
    alpha = 0.7,
    family = "Lato"
  ) +
  scf +
  scc +
  annotation_scale(height = unit(0.1, "cm"), text_cex = 0.5, location = "br", text_family = "Lato") +
  tt +
  coord_from_geom(st_as_sfc(extent_5))

# Timeline panel for placing the six clusters along a shared time axis.
# Each bar spans the occupancy period of one cluster; segments connect the
# end of one occupied cluster to the start of the next.
gtime =
  ggplot(timeline_df) +
  geom_rect(
    aes(
      xmin = start,
      xmax = stop,
      ymin = cluster_id - 0.32,
      ymax = cluster_id + 0.32,
      fill = Cluster,
      color = Cluster
    ),
    linewidth = 0.3,
    alpha = 0.3
  ) +
  geom_segment(
    data = timeline_df[
      order(cluster_id),
      .(
        x = stop,
        xend = data.table::shift(start, type = "lead"),
        y = cluster_id,
        yend = data.table::shift(cluster_id, type = "lead")
      )
    ][!is.na(xend)],
    aes(x = x, xend = xend, y = y, yend = yend),
    inherit.aes = FALSE,
    color = "grey35",
    linewidth = 0.5,
    alpha = 0.5
  ) +
  {
    if (nrow(start_arrow_df)) {
      geom_segment(
        data = start_arrow_df,
        aes(x = x, xend = xend, y = y, yend = yend),
        inherit.aes = FALSE,
        color = "black",
        linewidth = 0.3,
        lineend = "round",
        arrow = grid::arrow(
          type = "closed",
          length = unit(0.06, "inches")
        )
      )
    }
  } +
  geom_point(
    data = start_point_df,
    aes(x = x, y = y),
    inherit.aes = FALSE,
    color = "white",
    fill = "black",
    size = 2,
    shape = 21
  ) +
  scf +
  scc +
  scale_x_datetime(
    date_labels = "%d-%b",
    date_breaks = "3 day",
    expand = expansion(mult = c(0.015, 0.03))
  ) +
  scale_y_continuous(
    breaks = timeline_df$cluster_id,
    limits = c(0.5, y_upper_limit),
    expand = expansion(mult = c(0.02, 0.06))
  ) +
  theme_bw(base_family = "Lato") +
  theme(
    legend.position = "none",
    panel.background = element_rect(fill = "white", color = NA),
    plot.background = element_rect(fill = "white", color = NA),
    panel.grid.major.y = element_blank(),
    panel.grid.minor = element_blank(),
    panel.grid.major.x = element_line(color = scales::alpha("grey60", 0.2), linewidth = 0.25),
    axis.ticks = element_blank(),
    axis.title.x = element_blank(),
    axis.text.x = element_text(color = "grey20", size = 8),
    axis.text.y = element_text(color = "grey20", size = 8),
    plot.margin = margin(2.5, 10, 2.5, 10)
  ) +
  ylab("cluster")

# Apply a light outer margin to the lower panels while keeping the overview
# panel flush so its scale bar and inset sit tightly within the frame.
map_theme <- theme(
  plot.margin = margin(2, 2, 2, 2)
)

gall <- gall + theme(
  plot.margin = margin(0, 0, 0, 0)
)
g16  <- g16  + map_theme
g23  <- g23  + map_theme
g4   <- g4   + map_theme
g5   <- g5   + map_theme

# Derive row heights from target panel aspect ratios so the overview row,
# square inset row, and short timeline row stack with predictable proportions.
ar_overview = unname(
  (overview_extent[["xmax"]] - overview_extent[["xmin"]]) /
    (overview_extent[["ymax"]] - overview_extent[["ymin"]])
)
ar_maprow = 4.08   # 4 square panels + a little allowance for spacing

h_overview = 1 / ar_overview
h_maprow   = 1 / ar_maprow
h_time     = 0.16

row_heights = c(h_overview, h_maprow, h_time)

# Build the four lower maps as one patchwork row, then stack overview,
# inset row, and timeline into the final figure object.
map_row <- wrap_plots(
  g16, g23, g4, g5,
  ncol = 4
) +
  plot_layout(widths = c(1, 1, 1, 1))

gg <- wrap_plots(
  gall,
  map_row,
  gtime,
  ncol = 1
) +
  plot_layout(heights = row_heights)

fig_width = 8
fig_height = fig_width * sum(row_heights)

# Prefer the manuscript folder when present, otherwise fall back to the
# project figs directory so the script still runs in a lighter checkout.
output_dir = if (dir.exists(here::here("MANUSCRIPT"))) {
  here::here("MANUSCRIPT")
} else {
  here::here("figs")
}
dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

outfile <- file.path(output_dir, "figure2_.png")

ragg::agg_png(
  filename = outfile,
  width = fig_width,
  height = fig_height,
  units = "in",
  res = 600
)

grid.newpage()
grid.draw(patchwork::patchworkGrob(gg))
dev.off()
