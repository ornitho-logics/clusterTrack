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
    'clusterTrack',
    'clusterTrack.Vis'
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
#' map(ctdf)
ctdf[, Cluster := factor(cluster)]

ss = summarise_ctdf(ctdf)
ss[, Cluster := factor(cluster)]
ss = cbind(
  ss,
  st_as_sf(ss$site_poly_center) |> st_transform(crs) |> st_coordinates()
)

ss[,
  lab := glue_data(
    .SD,
    "start:{format(start, '%d-%b %H:%M')}\n
    stop:{format(stop, '%d-%b %H:%M')}\n"
  )
]

ss[, next_start := shift(start, type = "lead")]
ss[, time_to_next := difftime(next_start, stop)]

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

#endregion

#region Figure

tt = theme_bw() +
  theme(
    legend.position = "none",
    axis.ticks = element_blank(),
    axis.text = element_blank(),
    axis.title = element_blank(),
    plot.margin = unit(c(0, 0, 0, 0), "cm")
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
basemap_fill = "#F3F1EE"
basemap_col = "#D9D3CC"


gall =
  ggplot() +
  annotation_spatial(ak, fill = "#F3F1EE", color = "#D9D3CC") +
  annotation_spatial(
    st_as_sf(ctdf[cluster == 0]),
    alpha = 0.5,
    color = "grey",
    size = 2
  ) +
  layer_spatial(
    st_as_sf(ctdf[cluster == 0] |> as_ctdf_track()),
    linewidth = 0.2,
    alpha = 0.5
  ) +
  layer_spatial(
    st_as_sf(ctdf[cluster > 0]),
    aes(fill = Cluster, color = Cluster),
    alpha = 0.3,
    size = 2
  ) +
  geom_label_repel(data = ss, aes(x = X, y = Y, label = cluster), alpha = 0.7) +
  scf +
  scc +
  annotation_scale(height = unit(0.2, "cm")) +
  tt

g16 =
  ggplot() +
  layer_spatial(ss16, fill = NA, color = NA) +
  annotation_spatial(ak, fill = basemap_fill, color = basemap_col) +
  annotation_spatial(
    st_as_sf(ctdf[cluster == 0]),
    alpha = 0.5,
    color = "grey",
    size = 3
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
    aes(fill = Cluster, color = Cluster),
    alpha = 0.7
  ) +
  geom_sf_label(
    data = ss[cluster %in% c(1, 6), .(site_poly_center, cluster)] |> st_as_sf(),
    aes(label = cluster),
    nudge_x = 0.1,
    alpha = 0.7
  ) +
  scf +
  scc +
  annotation_scale(height = unit(0.1, "cm"), text_cex = 0.5) +
  tt

g23 =
  ggplot() +
  layer_spatial(ss23, fill = NA, color = NA) +
  annotation_spatial(ak, fill = basemap_fill, color = basemap_col) +
  annotation_spatial(
    st_as_sf(ctdf[cluster == 0]),
    alpha = 0.5,
    color = "grey",
    size = 3
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
    aes(fill = Cluster, color = Cluster),
    alpha = 0.7
  ) +
  geom_sf_label(
    data = ss[cluster %in% c(2, 3), .(site_poly_center, cluster)] |> st_as_sf(),
    aes(label = cluster),
    nudge_x = 0.1,
    alpha = 0.7
  ) +
  scf +
  scc +
  annotation_scale(height = unit(0.1, "cm"), text_cex = 0.5) +
  tt

g4 =
  ggplot() +
  layer_spatial(ss4, fill = NA, color = NA) +
  annotation_spatial(ak, fill = basemap_fill, color = basemap_col) +
  annotation_spatial(
    st_as_sf(ctdf[cluster == 0]),
    alpha = 0.5,
    color = "grey",
    size = 3
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
    aes(fill = Cluster, color = Cluster),
    alpha = 0.7
  ) +
  geom_sf_label(
    data = ss[cluster == 4, .(site_poly_center, cluster)] |> st_as_sf(),
    aes(label = cluster),
    nudge_x = 0.1,
    alpha = 0.7
  ) +
  scf +
  scc +
  annotation_scale(height = unit(0.1, "cm"), text_cex = 0.5) +
  tt


g5 =
  ggplot() +
  layer_spatial(ss5, fill = NA, color = NA) +
  annotation_spatial(ak, fill = basemap_fill, color = basemap_col) +
  annotation_spatial(
    st_as_sf(ctdf[cluster == 0]),
    alpha = 0.5,
    color = "grey",
    size = 3
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
    aes(fill = Cluster, color = Cluster),
    alpha = 0.7
  ) +
  geom_sf_label(
    data = ss[cluster == 5, .(site_poly_center, cluster)] |> st_as_sf(),
    aes(label = cluster),
    nudge_x = 0.1,
    alpha = 0.7
  ) +
  scf +
  scc +
  annotation_scale(height = unit(0.1, "cm"), text_cex = 0.5) +
  tt


gg = gall /
  wrap_plots(g16, g23, g4, g5, ncol = 4) +
  plot_layout(nrow = 2, heights = c(1.317, 1))


ggsave(
  filename = './MANUSCRIPT/figure2.png',
  plot = gg,
  device = ragg::agg_png,
  width = 8,
  height = 5,
  units = "in",
  dpi = 600
)

#endregion
