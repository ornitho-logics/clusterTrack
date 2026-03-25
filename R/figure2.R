#### BASELAYER CODE FROM "Luke_eudot_map_v2.R" that needs to be recycled/modified for figure 2 ----
### Packages and settings ----
packages <- c(
  "data.table",
  "here",
  "aniMotum",
  "tracktools",      # install via remotes::install_github('mpio-be/tracktools')
  "mapview",
  "sf",
  "tidyverse",
  "geodist",
  "clusterTrack",    # install via remotes::install_github('mpio-be/clusterTrack')
  "rnaturalearth",
  "htmlwidgets",
  "giscoR",
  "geodata",
  "terra",
  "raster",
  "tidyterra",
  "ggfx",
  "ggnewscale",
  "ggblend",
  "leaflet",
  "ggside",
  "dbo",
  "ggspatial",
  "patchwork"
)

# Define the custom rotated Lambert Conformal Conic projection parameters
lcc_crs_ <- "+proj=lcc +lat_1=57 +lat_2=65 +lat_0=61 +lon_0=-5 +x_0=0 +y_0=0 +ellps=WGS84 +units=m +no_defs"
### static map ----
# bounding box of Scandinavia region
scand_bb <-
  st_as_sfc(st_bbox(c(xmin = -20, ymin = 40,
                      xmax =  50, ymax = 72), crs = 4326))

### Download all layers
# countries from giscoR
countries <-
  gisco_get_countries(resolution = "3", epsg = 4326)

# rivers
rivers_scand <-
  ne_download(scale = 10, type = "rivers_lake_centerlines",
              category = "physical", returnclass = "sf") %>%
  st_intersection(., scand_bb)

# lakes
sf::sf_use_s2(FALSE)
lakes_scand <-
  ne_download(scale = 10, type = "lakes",
              category = "physical", returnclass = "sf") %>%
  st_intersection(., scand_bb)
sf::sf_use_s2(TRUE)

# DEM
scandi_dem_7 <-
  elevatr::get_elev_raster(locations = st_sf(geometry = scand_bb),
                           z = 7, clip = "locations")

# DEM
scandi_dem_3 <-
  elevatr::get_elev_raster(locations = st_sf(geometry = scand_bb),
                           z = 6, clip = "locations")

# transform projection of the DEM
scandi_dem_proj_7 <-
  terra::project(terra::rast(scandi_dem_7), terra::crs(countries_))

scandi_dem_proj_3 <-
  terra::project(terra::rast(scandi_dem_3), terra::crs(countries_))

# remove parts of the DEM below sea level
values(scandi_dem_proj_7)[values(scandi_dem_proj_7) < 0] <- NA
values(scandi_dem_proj_3)[values(scandi_dem_proj_3) < 0] <- NA


# Original bbox
map_bb <- st_bbox(c(
  xmin = 726351.4,  ymin = -154464.1,
  xmax = 2453719.9, ymax = 1666919.4
))

# xlim = c(map_bb["xmin"]-360000, map_bb["xmax"]-1000000),
# ylim = c(map_bb["ymin"]-300000, map_bb["ymax"]-250000),

# Reproduce the coord_sf limits
xlim <- c(map_bb["xmin"] - 300000, map_bb["xmax"] - 1500000)
ylim <- c(map_bb["ymin"] - 50000,  map_bb["ymax"] - 800000)

ext_crop <- ext(xlim[1], xlim[2], ylim[1], ylim[2])
scandi_dem_proj_7_crop <- crop(scandi_dem_proj_7, ext_crop)
scandi_dem_proj_3_crop <- scandi_dem_proj_3


xlim_box = c(map_bb["xmin"]-150000, map_bb["xmax"]-1650000)
ylim_box = c(map_bb["ymin"]-10000, map_bb["ymax"]-1400000)

# make DEM raster into a dataframe
mdtdf_7 <- as.data.frame(scandi_dem_proj_7_crop, xy = TRUE) %>% rename(alt = 3)
mdtdf_3 <- as.data.frame(scandi_dem_proj_3_crop, xy = TRUE) %>% rename(alt = 3)


### Compute hillshade for terrain visualization
sl_7 <- terra::terrain(scandi_dem_proj_7_crop, "slope", unit = "radians")
asp_7 <- terra::terrain(scandi_dem_proj_7_crop, "aspect", unit = "radians")

sl_3 <- terra::terrain(scandi_dem_proj_3_crop, "slope", unit = "radians")
asp_3 <- terra::terrain(scandi_dem_proj_3_crop, "aspect", unit = "radians")

hillmulti_7 <-
  map(c(270, 15, 60, 330),
      ~terra::shade(sl_7, asp_7, angle = 45,
                    direction = .x,
                    normalize = TRUE)) %>%
  terra::rast() %>% sum()

hillmultidf_7 <- as.data.frame(hillmulti_7, xy = TRUE)

hillmulti_3 <-
  map(c(270, 15, 60, 330),
      ~terra::shade(sl_3, asp_3, angle = 45,
                    direction = .x,
                    normalize = TRUE)) %>%
  terra::rast() %>% sum()

hillmultidf_3 <- as.data.frame(hillmulti_3, xy = TRUE)

### Re-project layers
# Define the custom rotated Lambert Conformal Conic projection parameters
lcc_crs_ <- "+proj=lcc +lat_1=57 +lat_2=65 +lat_0=61 +lon_0=-5 +x_0=0 +y_0=0 +ellps=WGS84 +units=m +no_defs"

# Crop to bounding box (returns only intersecting countries)
countries_ <-
  countries %>%
  st_transform(lcc_crs_)

# rivers
rivers_scand_ <-
  rivers_scand %>%
  st_transform(lcc_crs_)

# lakes
lakes_scand_ <-
  lakes_scand %>%
  st_transform(lcc_crs_)

# transform projection of the tracks
tracks_c_ <-
  clusters_centroids_tracks %>%
  st_transform(lcc_crs_)

# transform projection of the clusters
clusters_ <-
  clusters_centroids %>%
  st_transform(lcc_crs_)

eudot_range_ <-
  eudot_range %>%
  st_transform(lcc_crs_)

# Define color palette for elevation visualization
data(hypsometric_tints_db)
scandi_pal <- hypsometric_tints_db %>%
  filter(pal == "wiki-2.0_hypso") %>%
  mutate(limit = seq(0, 2235, length.out = nrow(.)))# %>%
# mutate(hex = ifelse(limit > 1500, "#FFFFFF", hex))

scandi_pal_ <- tibble(
  limit = seq(0, 2235, length.out = 100)
) %>%
  mutate(
    hex = colorRampPalette(c("#1A1A1A", "#7A7A7A", "#FFFFFF"))(100),
    hex = ifelse(limit > 1500, "#FFFFFF", hex)
  )

map_bb <-
  st_bbox(c(xmin = 726351.4, ymin = -154464.1,
            xmax =  2453719.9, ymax = 1666919.4))

# Create sf points in WGS84
arrow_points <- st_as_sf(data.frame(
  lon = c(7.56, 8.4333),
  lat = c(60.38, 60.9833),
  label = c("A", "B")
), coords = c("lon", "lat"), crs = 4326)

# Transform to your map's projection
arrow_points_proj <- st_transform(arrow_points, crs = lcc_crs_)

# Extract coordinates for plotting
coords <- st_coordinates(arrow_points_proj)

# CODEX: I only want the baselayer aesthetics from the eudot_map plot applied to the production of figure2, not the curved_lines or the clusters_centroids_
# for the editing of figure2, I want the current tracks and polygons to stay the same, e.g.,:
# annotation_spatial(
#   st_as_sf(ctdf[cluster == 0]),
#   alpha = 0.5,
#   color = "grey",
#   size = 3
# ) +
#   annotation_spatial(
#     st_as_sf(ctdf |> as_ctdf_track()),
#     linewidth = 0.2,
#     alpha = 0.5
#   ) +
#   annotation_spatial(
#     st_as_sf(ss[, .(Cluster, site_poly)]),
#     aes(fill = Cluster, color = Cluster),
#     alpha = 0.3
#   ) +
#   annotation_spatial(
#     st_as_sf(ctdf[cluster > 0]),
#     aes(fill = Cluster, color = Cluster),
#     alpha = 0.7
#   ) +
#   geom_sf_label(
#     data = ss[cluster == 5, .(site_poly_center, cluster)] |> st_as_sf(),
#     aes(label = cluster),
#     nudge_x = 0.1,
#     alpha = 0.7
#   )

### Draw map
eudot_map <-
  ggplot() +
  geom_sf(data = countries_, fill = "grey85", color = NA, alpha = 0.5) +
  # list(
  #   geom_raster(data = hillmultidf_3,
  #               aes(x, y, fill = sum),
  #               show.legend = FALSE,
  #               alpha = 0.7),
  #   scale_fill_distiller(palette = "Greys"),
  #   new_scale_fill(),
  #   geom_raster(data = mdtdf_3,
  #               aes(x, y, fill = alt),
  #               show.legend = FALSE,
  #               alpha = 0.7),
  #   scale_fill_gradientn(
  #     colors = scandi_pal$hex,
  #     values = scales::rescale(scandi_pal$limit),
  #     limit = range(scandi_pal$limit)
  #   )) %>%
  # blend("multiply") +
  geom_sf(data = rivers_scand_, color = "#698ecf", alpha = 1, linewidth = 0.2) +
  geom_sf(data = lakes_scand_, color = NA, fill = "#698ecf", alpha = 1) +
  # geom_sf(data = eudot_range_, color = "grey40", fill = "yellow", alpha = 0.1, linewidth = 0.1) +
  geom_curve(data = curved_lines_df, aes(x = start_x, y = start_y, xend = end_x, yend = end_y),
             curvature = 0.2, linewidth = 0.5, color = "black") +
  geom_curve(data = pre_cluster_track %>% filter(str_detect(tagID, "b")), aes(x = start_x, y = start_y, xend = end_x, yend = end_y),
             curvature = 0.2, linewidth = 0.5, color = "black", linetype = "dashed") +
  geom_curve(data = NO_dploy %>% filter(tagID == "198119"), aes(x = start_x, y = start_y, xend = end_x, yend = end_y),
             curvature = -0.1, linewidth = 0.5, color = "black", linetype = "dashed") +
  # geom_sf(data = pre_cluster_track, linetype = "dashed",
  #         color = "black", alpha = 1, linewidth = 0.5) +
  new_scale_fill() +
  geom_sf(data = clusters_centroids_,
          aes(size = as.numeric(dur), fill = date_),
          shape = 21, color = "black", alpha = 0.75) +
  # scale_fill_gradientn(
  #   colors = c("#016C6C", "#F0F0F0", "#7F0000"),  # choose one of the palettes above
  #   # values = scales::rescale(c(min_value, midpoint_value, max_value)),
  #   name = "Arrival date",
  #   breaks = as.Date(c("2021-06-01", "2021-06-16", "2021-07-01", "2021-07-16")),
  #   labels = scales::date_format("%b %d")
  # ) +  # or your main geom
  annotate(
    "rect",
    xmin = xlim_box["xmin"],
    xmax = xlim_box["xmax"],
    ymin = ylim_box["ymin"],
    ymax = ylim_box["ymax"],
    color = "black",     # border color
    fill = NA,         # transparent inside
    size = 0.25           # border thickness
  ) +
  scale_fill_gradient(
    low = "white",
    high = "#7D1A15", name = "Arrival date",
    breaks = as.Date(c("2021-06-01", "2021-06-16", "2021-07-01", "2021-07-16")),
    labels = scales::date_format("%b %d")) +
  # scale_fill_gradient2(
  #   low = "#8E017E",
  #   mid = "#F0F0F0",
  #   high = "#D73027",
  #   midpoint = mean(clusters_centroids$doy), name = "Arrival date\n(Julian)") +
  # scale_fill_viridis_c(option = "F", direction = -1, name = "Arrival date\n(Julian)") +
  scale_size_continuous(range = c(0.5, 8),
                        breaks = c(2, 5, 15, 30, 60),
                        labels = c("2", "5", "15", "30", "60"), name = "Tenure (days)") +
  labs(fill = "m", x = "Longitude", y = "Latitude") +
  coord_sf(xlim = c(map_bb["xmin"]-360000, map_bb["xmax"]-1000000),
           ylim = c(map_bb["ymin"]-300000, map_bb["ymax"]-250000),
           crs = lcc_crs_) +
  theme(legend.position = c(0.19, 0.8),
        legend.background = element_rect(fill = "transparent", color = NA),
        legend.key = element_rect(fill = "transparent", color = NA),
        legend.box.background = element_rect(fill = "transparent", color = NA),
        legend.title = element_text(color = "black", size = 10, hjust = 0.5),
        legend.text = element_text(color = "black", size = 8),
        legend.box.just = "center",
        legend.spacing.y = unit(0.5, "in"),
        axis.title.x = element_blank(),
        axis.title.y = element_blank(),
        axis.ticks = element_blank(),
        axis.text = element_text(color = "grey70", size = 8),
        panel.border = element_blank(),
        panel.background = element_rect(fill = 'white', color = NA),
        plot.background = element_rect(color = NA, fill = "white"),
        panel.grid.major = element_line(color = "grey50", linewidth = 0.1),
        text = element_text(family = "lato")) +
  guides(
    size = guide_legend(
      override.aes = list(color = "black", fill = "grey50"),
      title.position = "top", title.hjust = 0.5,
      label.position = "bottom", label.hjust = 0.5,
      direction = "horizontal", nrow = 1
    ),
    fill = guide_colorbar(
      barwidth = 7,
      barheight = 0.5,
      title.position = "top", title.hjust = 0.5,
      label.position = "bottom", label.hjust = 0.5,
      direction = "horizontal",
      label.theme = element_text(angle = 45, hjust = 1, vjust = 1)
    )
  ) +
  annotation_scale(location = "tl",
                   width_hint = 0.5,
                   style = "bar",
                   text_cex = 0.8,
                   line_width = 0.1,
                   bar_cols = c("grey20", "white")) +
  annotate("segment",
           x = coords[1, "X"] + 100000, y = coords[1, "Y"] - 10000,
           xend = coords[1, "X"], yend = coords[1, "Y"],
           arrow = arrow(type = "closed", length = unit(0.2, "cm")),
           color = "white", linewidth = 0.5) +
  annotate("segment",
           x = coords[2, "X"] + 100000, y = coords[2, "Y"] - 10000,
           xend = coords[2, "X"], yend = coords[2, "Y"],
           arrow = arrow(type = "closed", length = unit(0.2, "cm")),
           color = "white", linewidth = 0.5)

eudot_map

eudot_map_zoom <-
  ggplot() +
  geom_sf(data = countries_, fill = "grey85", color = NA, alpha = 0.5) +
  list(
    geom_raster(data = hillmultidf_7,
                aes(x, y, fill = sum),
                show.legend = FALSE,
                alpha = 0.7),
    scale_fill_distiller(palette = "Greys"),
    new_scale_fill(),
    geom_raster(data = mdtdf_7,
                aes(x, y, fill = alt),
                show.legend = FALSE,
                alpha = 0.7),
    scale_fill_gradientn(
      colors = scandi_pal$hex,
      values = scales::rescale(scandi_pal$limit),
      limit = range(scandi_pal$limit)
    )) %>%
  blend("multiply") +
  geom_sf(data = rivers_scand_, color = "#698ecf", alpha = 1, linewidth = 0.2) +
  geom_sf(data = lakes_scand_, color = NA, fill = "#698ecf", alpha = 1) +
  # geom_sf(data = eudot_range_, color = "grey40", fill = "yellow", alpha = 0.1, linewidth = 0.1) +
  geom_curve(data = curved_lines_df, aes(x = start_x, y = start_y, xend = end_x, yend = end_y),
             curvature = 0.2, linewidth = 0.5, color = "black") +
  geom_curve(data = pre_cluster_track, aes(x = start_x, y = start_y, xend = end_x, yend = end_y),
             curvature = 0.2, linewidth = 0.5, color = "black", linetype = "dashed") +
  geom_curve(data = NO_dploy %>% filter(tagID == "198119"), aes(x = start_x, y = start_y, xend = end_x, yend = end_y),
             curvature = -0.1, linewidth = 0.5, color = "black", linetype = "dashed") +
  # geom_sf(data = tracks_c_,
  #         color = "white", alpha = 1, linewidth = 0.3) +
  new_scale_fill() +
  geom_sf(data = clusters_centroids_,
          aes(size = as.numeric(dur), fill = date_),
          shape = 21, color = "black", alpha = 0.75) +
  # scale_fill_gradientn(
  #   colors = c("#016C6C", "#F0F0F0", "#7F0000"),  # choose one of the palettes above
  #   # values = scales::rescale(c(min_value, midpoint_value, max_value)),
  #   name = "Arrival date",
  #   breaks = as.Date(c("2021-06-01", "2021-06-16", "2021-07-01", "2021-07-16")),
  #   labels = scales::date_format("%b %d")
  # ) +
  scale_fill_gradient(
    low = "white",
    high = "#7D1A15", name = "Arrival date",
    breaks = as.Date(c("2021-06-01", "2021-06-16", "2021-07-01", "2021-07-16")),
    labels = scales::date_format("%b %d")) +
  # scale_fill_gradient2(
  #   low = "#8E017E",
  #   mid = "#F0F0F0",
  #   high = "#D73027",
  #   midpoint = mean(clusters_centroids$doy), name = "Arrival date\n(Julian)") +
  # scale_fill_viridis_c(option = "F", direction = -1, name = "Arrival date\n(Julian)") +
  scale_size_continuous(range = c(0.5, 8),
                        breaks = c(2, 5, 15, 30, 60),
                        labels = c("2", "5", "15", "30", "60"), name = "Tenure (days)") +
  labs(fill = "m", x = "Longitude", y = "Latitude") +
  coord_sf(xlim = c(map_bb["xmin"]-150000, map_bb["xmax"]-1650000),
           ylim = c(map_bb["ymin"]-10000, map_bb["ymax"]-1400000),
           crs = lcc_crs_) +
  theme(legend.position = "none",
        legend.background = element_rect(fill = "transparent", color = NA),
        legend.key = element_rect(fill = "transparent", color = NA),
        legend.box.background = element_rect(fill = "transparent", color = NA),
        legend.title = element_text(color = "black", size = 10, hjust = 0.5),
        legend.text = element_text(color = "black", size = 8),
        legend.box.just = "center",
        legend.spacing.y = unit(0.5, "in"),
        axis.title.x = element_blank(),
        axis.title.y = element_blank(),
        axis.ticks = element_blank(),
        axis.text = element_blank(),
        panel.border = element_blank(),
        panel.background = element_rect(fill = 'white', color = NA),
        plot.background = element_rect(color = "black", fill = "white", size = 1),
        panel.grid.major = element_line(color = "grey50", linewidth = 0.1),
        text = element_text(family = "lato"),
        plot.margin = unit(c(0.03, 0.03, 0.03, 0.03), "cm")) +
  guides(
    size = guide_legend(
      override.aes = list(color = "black", fill = "grey50"),
      title.position = "bottom", title.hjust = 0.5,
      label.position = "bottom", label.hjust = 0.5,
      direction = "horizontal", nrow = 1
    ),
    fill = guide_colorbar(
      barwidth = 7,
      barheight = 0.5,
      title.position = "bottom", title.hjust = 0.5,
      label.position = "bottom", label.hjust = 0.5,
      direction = "horizontal",
      label.theme = element_text(angle = 45, hjust = 1, vjust = 1)
    )
  ) +
  annotation_scale(location = "bl",
                   width_hint = 0.5,
                   style = "bar",
                   text_cex = 0.8,
                   line_width = 0.1,
                   text_col = "black",
                   bar_cols = c("grey20", "white")) +
  annotate("segment",
           x = coords[1, "X"] + 50000, y = coords[1, "Y"] - 5000,
           xend = coords[1, "X"], yend = coords[1, "Y"],
           arrow = arrow(type = "closed", length = unit(0.2, "cm")),
           color = "white", linewidth = 0.5) +
  annotate("segment",
           x = coords[2, "X"] + 50000, y = coords[2, "Y"] - 5000,
           xend = coords[2, "X"], yend = coords[2, "Y"],
           arrow = arrow(type = "closed", length = unit(0.2, "cm")),
           color = "white", linewidth = 0.5)
eudot_map_zoom

# library(patchwork)

main_plot <- eudot_map
inset_plot <- eudot_map_zoom

merged_plots <-
  main_plot +
  inset_element(
    inset_plot,
    left = 0.65,   # x position (0–1)
    bottom = 0.05, # y position (0–1)
    right = 1.65,  # width
    top = 0.6     # height
  )
### Export map to disk
ggsave(plot = merged_plots,
       filename = "eudot_map_draft.png",
       path = here("tabs_figs/"),
       height = 5*1.7, width = 11, units = "in")

#### original figure2.R script starts here ----
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

ss[, next_start := data.table::shift(start, type = "lead")]
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

output_dir = if (dir.exists(here::here("MANUSCRIPT"))) {
  here::here("MANUSCRIPT")
} else {
  here::here("figs")
}

dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)


ggsave(
  filename = file.path(output_dir, "figure2.png"),
  plot = gg,
  device = ragg::agg_png,
  width = 8,
  height = 5,
  units = "in",
  dpi = 600
)

# ggsave(
#   filename = './MANUSCRIPT/figure2.png',
#   plot = gg,
#   device = ragg::agg_png,
#   width = 8,
#   height = 5,
#   units = "in",
#   dpi = 600
# )

#endregion
