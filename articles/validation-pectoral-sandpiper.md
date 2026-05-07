# Clustering tracks: validation and real-world example

Here we use a real ARGOS telemetry dataset for male Pectoral Sandpipers
(*Calidris melanotos*) to illustrate how `clusterTrack` works on a
larger set of individual tracks. The same dataset also provides a useful
validation case because it contains curated use-site assignments from
[Kempenaers and Valcu
(2017)](https://www.nature.com/articles/nature20813).

`clusterTrack` is run independently on each individual track, and the
extracted clusters are compared with the curated labels. The companion
package `clusterTrack.Vis` is used to save one interactive map per
individual track and also to create a local `site` for easy navigation
throughout the maps.

For validation, the number of curated use sites is compared with the
number of clusters inferred by `clusterTrack` and a point-level
agreement is quantified using the adjusted Rand index.

``` r

pckgs <- c(
  "data.table",
  "osfr",
  "fs",
  "sf",
  "RSQLite",
  "clusterTrack",
  "clusterTrack.Vis",
  "foreach",
  "doMC",
  "mclust"
)

sapply(pckgs, require, character.only = TRUE, quietly = TRUE)


download_dir <- tempdir()

if (!dir_exists(download_dir)) {
  dir_create(download_dir)
}

interactive_map_dir <- paste0(download_dir, "Kempenaers_and_Valcu_2017_pesa")

if (dir_exists(interactive_map_dir)) {
  dir_delete(interactive_map_dir)
}
```

## Download and prepare the curated dataset

The curated validation data are distributed through the Open Science
Framework project: <https://osf.io/vx2mk/overview>. The script downloads
`source_data.db`, reads the `sites` and `argos_locations` layers, and
joins each ARGOS fix to its curated site label according to bird
identity and the curated site’s time window. The ARGOS locations are
transformed from the original projection to WGS84 longitude and latitude
before being converted to the `clusterTrack` input format.

``` r

source_data <- paste0(download_dir, "/source_data.db")

if (!file_exists(source_data)) {
  proj <- osf_retrieve_node("vx2mk")

  ff <- osf_ls_files(proj)

  osf_download(
    dplyr::filter(ff, name == "source_data.db"),
    path = download_dir
  )
}

crs <- "+proj=laea +lat_0=90 +lon_0=-156.653428 +x_0=0 +y_0=0 +datum=WGS84 +units=m +no_defs"

ss <- st_read(dsn = source_data, layer = "sites") |> setDT()
ss[, GEOMETRY := NULL]


ds <- st_read(dsn = source_data, layer = "argos_locations")
st_crs(ds) <- crs
ds <- st_transform(ds, 4326)

ds <- cbind(ds, st_coordinates(ds)) |> setDT()
ds[, GEOMETRY := NULL]

ss[, let(
  min_datetime = as.POSIXct(min_datetime, tz = "UTC"),
  max_datetime = as.POSIXct(max_datetime, tz = "UTC")
)]

ds[, datetime_ := as.POSIXct(datetime_, tz = "UTC")]

dss <- ss[
  ds,
  on = .(
    bird_id,
    min_datetime <= datetime_,
    max_datetime >= datetime_
  ),
  .(
    year_,
    bird_id,
    quality,
    datetime_ = i.datetime_,
    X,
    Y,
    patchid
  )
]
```

The manuscript validation uses males tracked for at least 30 days within
the breeding range. The code below first excludes records after the last
curated breeding-site interval for each bird, then keeps individuals
whose remaining track duration is at least 30 days. Two trivial cases
with only one curated cluster are removed.

``` r

breeding_cutoff <- ss[,
  .(last_max_datetime = max(max_datetime, na.rm = TRUE)),
  by = bird_id
]

dss <- merge(dss, breeding_cutoff)
dss <- dss[datetime_ < last_max_datetime][, last_max_datetime := NULL]

duration_cutoff <- dss[,
  .(
    total_stay = difftime(max(datetime_), min(datetime_), units = "days") |>
      as.numeric()
  ),
  by = bird_id
][total_stay >= 30]

dss <- dss[bird_id %in% duration_cutoff$bird_id]

X <- dss[
  ,
  .(
    id = bird_id,
    time = datetime_,
    latitude = Y,
    longitude = X,
    true_cluster = patchid
  )
]

X[, ntruecl := max(true_cluster, na.rm = TRUE), by = id]

X <- X[ntruecl > 1][, ntruecl := NULL]
```

## Run `clusterTrack` and save interactive maps

The next block runs `clusterTrack` independently for each individual.
The resulting maps are saved with the companion `clusterTrack.Vis`
package. `site` creates a thumbnails for each map and an `index.qml`
file which can then be edited and compiled to create a navigation page.
The cluster truck output is then gathered in `out`.

``` r

ids <- X[, .N, id]

registerDoMC(nrow(ids))
o <- foreach(i = ids$id) %dopar% {
  x <- as_ctdf(X[id == i]) |>
    cluster_track()

  m <- clusterTrack.Vis::map(
    x,
    fix_dateline = TRUE
  )

  m |> save_map(path = interactive_map_dir, name = i)

  x
}

site(interactive_map_dir)

out <- rbindlist(o)
out[cluster == 0, cluster := NA]
```

## Compare the number of curated and inferred clusters

For each individual, the number of curated clusters is compared with the
number of clusters inferred by `clusterTrack`.

``` r

x <- merge(
  out[!is.na(true_cluster), .N, .(id, true_cluster)][, .N, id],
  out[!is.na(cluster), .N, .(id, cluster)][, .N, id],
  by = "id",
  suffixes = c("_old", "_new")
)

x[, cor(N_old, N_new)]
```

## Adjusted Rand index

The adjusted Rand index quantifies point-level agreement between the
curated labels and the labels inferred by `clusterTrack`, after
correcting for agreement expected by chance.

``` r

x <- out[!is.na(cluster) & !is.na(true_cluster)]

x <- x[, .(ari = adjustedRandIndex(cluster, true_cluster)), by = id]

x[
  ,
  .(
    q05 = quantile(ari, 0.05),
    median = median(ari),
    mean = mean(ari),
    q95 = quantile(ari, 0.95)
  )
]
```

## Notes for reproduction

This vignette is intended as a transparent record of the validation
workflow, not as an automatically executed example. To reproduce the
analysis, copy the code into a regular R script, install the optional
workflow packages listed above, set `download_dir` to a suitable local
directory, and run the script interactively.
