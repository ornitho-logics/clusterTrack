# remove.packages("clusterTrack") # remove old version of the package

if (!requireNamespace("clusterTrack", quietly = TRUE)) {
  remotes::install_github("ornitho-logics/clusterTrack")
}

# PACKAGES, SETTINGS
sapply(
  c(
    'data.table',
    'dbo',
    'stringr',
    'here',
    'glue',
    'dplyr',
    'sf',
    'rnaturalearth',
    'ggspatial',
    'ggplot2',
    'ggrepel',
    'patchwork',
    'clusterTrack'
  ),
  require,
  character.only = TRUE,
  quietly = TRUE
)

crs = 3467 # Alaska Albers Equal Area Conic


#region DATA
ak = ne_countries(returnclass = "sf", scale = "large") |>
  filter(name == "United States of America") |>
  st_cast("POLYGON") |>
  mutate(id = row_number()) |>
  filter(id == 2) |>
  st_geometry() |>
  st_transform(crs)


data(pesa56511)
ctdf = as_ctdf(pesa56511, time = "locationDate") |> cluster_track()
ctdf = data.table::copy(ctdf)

if (is.na(st_crs(ctdf$location))) {
  ctdf[, location := suppressWarnings(st_set_crs(location, crs))]
}
#' map(ctdf)
ctdf[, Cluster := factor(cluster)]

ss = summary(ctdf)
ss = merge(
  ss,
  ctdf[
    cluster > 0,
    .(site_poly = st_union(location) |> st_convex_hull()),
    by = cluster
  ],
  by = "cluster"
)
setnames(ss, "geometry", "site_poly_center")
ss[, Cluster := factor(cluster)]
ss = cbind(
  ss,
  st_as_sf(ss, sf_column_name = "site_poly_center") |>
    st_transform(crs) |>
    st_coordinates()
)

ss[,
  lab := glue_data(
    .SD,
    "start:{format(start, '%d-%b %H:%M')}\n
    stop:{format(stop, '%d-%b %H:%M')}\n"
  )
]

ss[, next_start := data.table::shift(start, type = "lead")]
ss[, time_to_next := difftime(next_start, stop)]

ss16 = ss[cluster %in% c(1, 6), .(site_poly_center)] |>
  st_as_sf(sf_column_name = "site_poly_center") |>
  st_buffer(dist = 1000 * 10)


ss23 = ss[cluster %in% c(2, 3), .(site_poly_center)] |>
  st_as_sf(sf_column_name = "site_poly_center") |>
  st_buffer(dist = 1000 * 5)

ss4 = ss[cluster == 4, .(site_poly_center)] |>
  st_as_sf(sf_column_name = "site_poly_center") |>
  st_buffer(dist = 1000 * 6)

ss5 = ss[cluster == 5, .(site_poly_center)] |>
  st_as_sf(sf_column_name = "site_poly_center") |>
  st_buffer(dist = 1000 * 10)

background_points = st_as_sf(ctdf[cluster == 0])
cluster_points = st_as_sf(ctdf[cluster > 0])
all_points = st_as_sf(ctdf)
track_lines = st_as_sf(ctdf |> as_ctdf_track())
site_polys = st_as_sf(ss[, .(Cluster, site_poly)], sf_column_name = "site_poly")

#endregion

#region Figure

cluster_palette = c(
  "1" = "#F4E5E0",
  "2" = "#E9D0C4",
  "3" = "#DCB19E",
  "4" = "#CB8C70",
  "5" = "#AA563A",
  "6" = "#7D1A15"
)

water_fill = "#F1F0EC"
land_fill = "#E4DED4"
coast_col = "#D4CCBF"
grid_col = "#D8D8D8"
track_col = "#111111"
context_col = "#A6A6A6"

tt = theme_minimal(base_size = 10) +
  theme(
    legend.position = "none",
    panel.background = element_rect(fill = water_fill, color = NA),
    plot.background = element_rect(fill = "white", color = NA),
    panel.grid.major = element_line(color = grid_col, linewidth = 0.35),
    panel.grid.minor = element_blank(),
    panel.border = element_rect(color = "#565656", fill = NA, linewidth = 0.6),
    axis.ticks = element_blank(),
    axis.text = element_blank(),
    axis.title = element_blank(),
    plot.margin = unit(c(0.03, 0.03, 0.03, 0.03), "cm")
  )

scf = scale_fill_manual(
  values = cluster_palette,
  guide = "none"
)
scc = scale_color_manual(
  values = cluster_palette,
  guide = "none"
)

zoom_limits = function(zoom_geom, x_pad = 0.12, y_pad = x_pad) {
  bb = st_bbox(zoom_geom)
  x_pad = (bb[["xmax"]] - bb[["xmin"]]) * x_pad
  y_pad = (bb[["ymax"]] - bb[["ymin"]]) * y_pad

  list(
    x = c(bb[["xmin"]] - x_pad, bb[["xmax"]] + x_pad),
    y = c(bb[["ymin"]] - y_pad, bb[["ymax"]] + y_pad)
  )
}

zoom_coord = function(zoom_geom, x_pad = 0.12, y_pad = x_pad) {
  limits = zoom_limits(zoom_geom, x_pad = x_pad, y_pad = y_pad)

  coord_sf(
    crs = st_crs(crs),
    default_crs = st_crs(crs),
    xlim = limits$x,
    ylim = limits$y,
    expand = FALSE
  )
}

map_base = function() {
  ggplot() +
    annotation_spatial(ak, fill = land_fill, color = coast_col) +
    geom_sf(
      data = track_lines,
      color = track_col,
      linewidth = 0.25,
      alpha = 0.45,
      show.legend = FALSE
    ) +
    geom_sf(
      data = background_points,
      color = context_col,
      size = 2.4,
      alpha = 0.35,
      show.legend = FALSE
    ) +
    geom_sf(
      data = site_polys,
      aes(fill = Cluster, color = Cluster),
      alpha = 0.25,
      linewidth = 0.35,
      show.legend = FALSE
    ) +
    geom_sf(
      data = cluster_points,
      aes(fill = Cluster),
      shape = 21,
      color = "black",
      stroke = 0.18,
      size = 2.3,
      alpha = 0.7,
      show.legend = FALSE
    ) +
    scf +
    scc +
    tt
}


gall =
  map_base() +
  geom_label_repel(
    data = ss,
    aes(x = X, y = Y, label = cluster),
    seed = 11,
    fill = scales::alpha("white", 0.88),
    color = "#222222",
    label.size = 0.25,
    label.r = unit(0.12, "lines"),
    label.padding = unit(0.14, "lines"),
    box.padding = 0.25,
    point.padding = 0.2,
    segment.color = scales::alpha("#5C5C5C", 0.6),
    size = 4
  ) +
  annotation_scale(
    location = "bl",
    width_hint = 0.23,
    style = "bar",
    height = unit(0.18, "cm"),
    text_cex = 0.6,
    line_width = 0.25,
    text_col = "#222222",
    bar_cols = c("grey20", "white")
  ) +
  zoom_coord(all_points, x_pad = 0.04, y_pad = 0.45)

g16 =
  map_base() +
  geom_sf_label(
    data = ss[cluster %in% c(1, 6), .(site_poly_center, cluster)] |>
      st_as_sf(sf_column_name = "site_poly_center"),
    aes(label = cluster),
    fill = scales::alpha("white", 0.88),
    color = "#222222",
    label.size = 0.25,
    label.r = unit(0.12, "lines"),
    label.padding = unit(0.12, "lines"),
    size = 4
  ) +
  annotation_scale(
    location = "bl",
    width_hint = 0.27,
    style = "bar",
    height = unit(0.1, "cm"),
    text_cex = 0.5,
    line_width = 0.2,
    text_col = "#222222",
    bar_cols = c("grey20", "white")
  ) +
  zoom_coord(ss16)

g23 =
  map_base() +
  geom_sf_label(
    data = ss[cluster %in% c(2, 3), .(site_poly_center, cluster)] |>
      st_as_sf(sf_column_name = "site_poly_center"),
    aes(label = cluster),
    fill = scales::alpha("white", 0.88),
    color = "#222222",
    label.size = 0.25,
    label.r = unit(0.12, "lines"),
    label.padding = unit(0.12, "lines"),
    size = 4
  ) +
  annotation_scale(
    location = "bl",
    width_hint = 0.27,
    style = "bar",
    height = unit(0.1, "cm"),
    text_cex = 0.5,
    line_width = 0.2,
    text_col = "#222222",
    bar_cols = c("grey20", "white")
  ) +
  zoom_coord(ss23)

g4 =
  map_base() +
  geom_sf_label(
    data = ss[cluster == 4, .(site_poly_center, cluster)] |>
      st_as_sf(sf_column_name = "site_poly_center"),
    aes(label = cluster),
    fill = scales::alpha("white", 0.88),
    color = "#222222",
    label.size = 0.25,
    label.r = unit(0.12, "lines"),
    label.padding = unit(0.12, "lines"),
    size = 4
  ) +
  annotation_scale(
    location = "bl",
    width_hint = 0.27,
    style = "bar",
    height = unit(0.1, "cm"),
    text_cex = 0.5,
    line_width = 0.2,
    text_col = "#222222",
    bar_cols = c("grey20", "white")
  ) +
  zoom_coord(ss4)


g5 =
  map_base() +
  geom_sf_label(
    data = ss[cluster == 5, .(site_poly_center, cluster)] |>
      st_as_sf(sf_column_name = "site_poly_center"),
    aes(label = cluster),
    fill = scales::alpha("white", 0.88),
    color = "#222222",
    label.size = 0.25,
    label.r = unit(0.12, "lines"),
    label.padding = unit(0.12, "lines"),
    size = 4
  ) +
  annotation_scale(
    location = "bl",
    width_hint = 0.27,
    style = "bar",
    height = unit(0.1, "cm"),
    text_cex = 0.5,
    line_width = 0.2,
    text_col = "#222222",
    bar_cols = c("grey20", "white")
  ) +
  zoom_coord(ss5)


gg = gall /
  wrap_plots(g16, g23, g4, g5, ncol = 4) +
  plot_layout(nrow = 2, heights = c(1.317, 1))

output_dir = if (dir.exists(here::here("MANUSCRIPT"))) {
  here::here("MANUSCRIPT")
} else {
  here::here("figs")
}

dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
output_file = file.path(output_dir, "figure2.png")


ggsave(
  filename = output_file,
  plot = gg,
  device = ragg::agg_png,
  width = 8,
  height = 5,
  units = "in",
  dpi = 600
)

#endregion
