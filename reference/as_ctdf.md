# Coerce an object to clusterTrack data format

S3 generic for converting objects into a `ctdf`.

## Usage

``` r
as_ctdf(x, ...)
```

## Arguments

- x:

  An object to convert.

- ...:

  Passed to methods.

## Value

A `ctdf`: a timestamp-ordered `data.table` with an `sfc_POINT` geometry
column named `location`.

## Details

See
[`as_ctdf.data.frame()`](https://ornitho-logics.github.io/clusterTrack/reference/as_ctdf.data.frame.md)
for coordinate columns and
[`as_ctdf.sf()`](https://ornitho-logics.github.io/clusterTrack/reference/as_ctdf.sf.md)
for existing POINT geometries with a source CRS.

Internal working columns used by the clustering pipeline are
preallocated when a `ctdf` is created and reset after
[`cluster_track()`](https://ornitho-logics.github.io/clusterTrack/reference/cluster_track.md)
completes. Intermediate clustering states can be inspected with
[`putative_cluster_trace()`](https://ornitho-logics.github.io/clusterTrack/reference/putative_cluster_trace.md)
when `trace = TRUE`.

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

[`as_ctdf.data.frame()`](https://ornitho-logics.github.io/clusterTrack/reference/as_ctdf.data.frame.md),
[`as_ctdf.sf()`](https://ornitho-logics.github.io/clusterTrack/reference/as_ctdf.sf.md),
[`cluster_track()`](https://ornitho-logics.github.io/clusterTrack/reference/cluster_track.md)
