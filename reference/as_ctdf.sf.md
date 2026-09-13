# Coerce an sf object to clusterTrack data format

Converts an `sf` object with POINT geometries and a timestamp column to
a `ctdf`. The source CRS is taken from `x`; a missing CRS is an error.

## Usage

``` r
# S3 method for class 'sf'
as_ctdf(x, time = "time", t_srs = "+proj=eqearth", ...)
```

## Arguments

- x:

  An `sf` object with POINT geometries and a source CRS.

- time:

  Name of the POSIXt time column. Will be renamed to `"timestamp"`
  internally.

- t_srs:

  Target spatial reference passed to
  [`sf::st_transform()`](https://r-spatial.github.io/sf/reference/st_transform.html).
  Default is "+proj=eqearth".

- ...:

  Currently unused

## Value

An object of class `ctdf` (inherits from `data.table` and `data.frame`),
with an `sfc_POINT` geometry column named `location`.

## Details

Rows are sorted by timestamp, geometry is transformed to `t_srs`, and
clusterTrack columns are initialized. Existing reserved columns are
overwritten with a warning.

The converted object is checked for duplicate locations with the same
timestamp and temporal gaps exceeding
`getOption("clusterTrack.max_gap", 24)` hours. Duplicate warnings
identify row positions in the returned, timestamp-sorted `ctdf`.

## ctdf columns

In addition to columns retained from the input, a `ctdf` contains the
following standardized columns:

- `timestamp`: Observation time. Rows are ordered by this column when
  the `ctdf` is created.

- `location`: Point geometry in the target coordinate reference system.

- `.id`: Sequential row identifier assigned after ordering by
  `timestamp`. It is used internally to track locations through the
  clustering workflow and does not refer to the row number in the
  original input.

- `cluster`: Final cluster assignment. It is initialized to `NA`.
  [`cluster_track()`](https://ornitho-logics.github.io/clusterTrack/reference/cluster_track.md)
  assigns positive integers to clustered locations and `0` to unassigned
  locations.
  [`aggregate_ctdf()`](https://ornitho-logics.github.io/clusterTrack/reference/aggregate_ctdf.md)
  may subsequently merge and renumber clusters.

- `lof`: Local Outlier Factor score for each location. It is initialized
  to `NA` and populated by
  [`ctdf_lof()`](https://ornitho-logics.github.io/clusterTrack/reference/ctdf_lof.md)
  for locations with `cluster > 0`. Unassigned locations retain `NA`.

## See also

[`as_ctdf()`](https://ornitho-logics.github.io/clusterTrack/reference/as_ctdf.md),
[`as_ctdf.data.frame()`](https://ornitho-logics.github.io/clusterTrack/reference/as_ctdf.data.frame.md)

## Examples

``` r
data(mini_ruff)
points <- sf::st_as_sf(
  mini_ruff,
  coords = c("longitude", "latitude"),
  crs = 4326
)
x <- as_ctdf(points)
```
