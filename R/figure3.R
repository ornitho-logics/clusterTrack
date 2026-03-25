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
    'patchwork',
    'clusterTrack',
    'clusterTrack.Vis'
  ),
  require,
  character.only = TRUE,
  quietly = TRUE
)

#region ctdf-s

data(ruff143789)
ruff = as_ctdf(ruff143789, time = "locationDate") |> cluster_track()

data(ruff07b5)
ruff2 = as_ctdf(ruff07b5, time = "timestamp") |> cluster_track()

data(lbdo66862)
lbdo = as_ctdf(lbdo66862, time = "locationDate") |> cluster_track()

data(nola125a)
nola = as_ctdf(nola125a, time = "timestamp") |> cluster_track()

#endregion

#region MAPPING FUNCTION

make_fig_map <- function(
  ctdf,
  crs = 3995,
  time = "locationDate",
  reg = "Europe & Central Asia",
  scloc = "br"
) {
  ctdf[, Cluster := factor(cluster)]

  base_map =
    ne_countries(returnclass = "sf", scale = "large") |>
    filter(region_wb == reg) |>
    st_make_valid() |>
    st_cast("POLYGON") |>
    st_geometry() |>
    st_transform(crs = crs)

  ss = summarise_ctdf(ctdf)
  ss[, Cluster := factor(cluster)]
  ss = cbind(
    ss,
    st_as_sf(ss$site_poly_center) |> st_transform(crs = crs) |> st_coordinates()
  )

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
  basemap_col = "#F3F1EE"

  ggplot() +
    annotation_spatial(base_map, fill = basemap_fill, color = basemap_col) +
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
    annotation_spatial(
      st_as_sf(ss[, .(Cluster, site_poly)]),
      aes(fill = Cluster, color = Cluster),
      alpha = 0.3
    ) +
    layer_spatial(
      st_as_sf(ctdf[cluster > 0]),
      aes(fill = Cluster, color = Cluster),
      alpha = 0.3,
      size = 2
    ) +
    scf +
    scc +
    annotation_scale(height = unit(0.15, "cm"), location = scloc) +
    tt
}

#endregion

#region ggplots
#Ignore "Warning messages": ' A shallow copy of this ... '
gruff1 = make_fig_map(ruff, crs = 3995)
gruff2 = make_fig_map(ruff2, crs = 3995)
glbdo = make_fig_map(lbdo, crs = 8858, reg = 'North America', scloc = 'bl')
gnola = make_fig_map(nola, crs = 3995, scloc = 'br')


gg =
  (gruff1 + gruff2 + glbdo) /
  (gnola) +
  plot_annotation(tag_levels = "a") &

  theme(
    plot.tag.position = c(0.02, 0.95)
  )


ggsave(
  filename = './MANUSCRIPT/figure3.png',
  plot = gg,
  device = ragg::agg_png,
  width = 3.4,
  height = 14.5,
  units = "in",
  dpi = 600
)

# endregion

# region ctdf info

o = list(ruff, ruff2, lbdo, nola)
names(o) <- c('ruff', 'ruff-gps', 'lbdo', 'nola')

lapply(o, \(x) {
  x[, .N, cluster] |> nrow()
})

#endregion
