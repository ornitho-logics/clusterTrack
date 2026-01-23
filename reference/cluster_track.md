# Cluster a movement track into spatiotemporal clusters

`cluster_track` that assigns a `cluster` id to each location in a `ctdf`
by running a multi-step pipeline:

1.  identify temporally continuous putative regions via
    [`slice_ctdf()`](https://ornitho-logics.github.io/clusterTrack/reference/slice_ctdf.md).

2.  merge adjacent putative regions with intersecting convex hulls via
    [`spatial_repair()`](https://ornitho-logics.github.io/clusterTrack/reference/spatial_repair.md).

3.  locally split each putative region using DTSCAN via
    [`local_cluster_ctdf()`](https://ornitho-logics.github.io/clusterTrack/reference/local_cluster_ctdf.md)
    and
    [`sf_dtscan()`](https://ornitho-logics.github.io/clusterTrack/reference/sf_dtscan.md).

4.  enforce non-overlap in time by merging any putative regions with
    overlapping time domains via
    [`temporal_repair()`](https://ornitho-logics.github.io/clusterTrack/reference/temporal_repair.md).

5.  drop small clusters and run additional spatial and track-shape
    repairs via
    [`spatial_repair()`](https://ornitho-logics.github.io/clusterTrack/reference/spatial_repair.md)
    and
    [`tail_repair()`](https://ornitho-logics.github.io/clusterTrack/reference/tail_repair.md).

6.  optionally merge adjacent clusters within `aggregate_dist` via
    [`aggregate_ctdf()`](https://ornitho-logics.github.io/clusterTrack/reference/aggregate_ctdf.md).

## Usage

``` r
cluster_track(
  ctdf,
  nmin = 3,
  z_min = 1,
  trim = 0.05,
  minCluster = 3,
  deltaT,
  aggregate_dist
)
```

## Arguments

- ctdf:

  A `ctdf` object (see
  [`as_ctdf()`](https://ornitho-logics.github.io/clusterTrack/reference/as_ctdf.md)).

- nmin:

  Integer; passed to
  [`local_cluster_ctdf()`](https://ornitho-logics.github.io/clusterTrack/reference/local_cluster_ctdf.md)
  (`nmin`). (clusters with `N <= minCluster` are dropped before final
  repairs).

- z_min:

  Numeric; pruning threshold forwarded to
  [`local_cluster_ctdf()`](https://ornitho-logics.github.io/clusterTrack/reference/local_cluster_ctdf.md)
  and ultimately
  [`sf_dtscan()`](https://ornitho-logics.github.io/clusterTrack/reference/sf_dtscan.md)
  as `area_z_min` and `length_z_min` (sign is flipped internally).

- trim:

  Numeric; passed to
  [`temporal_repair()`](https://ornitho-logics.github.io/clusterTrack/reference/temporal_repair.md).
  Maximum fraction trimmed from each

- minCluster:

  Integer; minimum number of points required to keep a putative cluster
  used when splitting candidate regions into movement segments. tail
  when estimating each cluster's time domain.

- deltaT:

  Optional numeric; passed to
  [`slice_ctdf()`](https://ornitho-logics.github.io/clusterTrack/reference/slice_ctdf.md).
  Maximum allowable time gap (in days)

- aggregate_dist:

  Optional numeric; if supplied, passed to
  [`aggregate_ctdf()`](https://ornitho-logics.github.io/clusterTrack/reference/aggregate_ctdf.md)
  as `dist` (numeric treated as km).

## Value

Invisibly returns `ctdf`, with `cluster` updated in-place and
`attr(ctdf, "cluster_params")` set.

## Details

The function updates `ctdf` by reference and stores its parameters in
`attr(ctdf, "cluster_params")`.

## See also

[`as_ctdf()`](https://ornitho-logics.github.io/clusterTrack/reference/as_ctdf.md),
[`slice_ctdf()`](https://ornitho-logics.github.io/clusterTrack/reference/slice_ctdf.md),
[`spatial_repair()`](https://ornitho-logics.github.io/clusterTrack/reference/spatial_repair.md),
[`local_cluster_ctdf()`](https://ornitho-logics.github.io/clusterTrack/reference/local_cluster_ctdf.md),
[`sf_dtscan()`](https://ornitho-logics.github.io/clusterTrack/reference/sf_dtscan.md),
[`temporal_repair()`](https://ornitho-logics.github.io/clusterTrack/reference/temporal_repair.md),
[`tail_repair()`](https://ornitho-logics.github.io/clusterTrack/reference/tail_repair.md),
[`aggregate_ctdf()`](https://ornitho-logics.github.io/clusterTrack/reference/aggregate_ctdf.md)

## Examples

``` r
data(mini_ruff)
x = as_ctdf(mini_ruff) |> cluster_track()
#> → Find putative cluster regions.
#> ! Spatial repair.
#> → Local clustering.
#> ! Temporal repair.

if (FALSE) { # \dontrun{
data(pesa56511)
pesa = as_ctdf(pesa56511, time = "locationDate") |> cluster_track()

data(ruff143789)
ruff = as_ctdf(ruff143789, time = "locationDate") |> cluster_track()


data(lbdo66862)
lbdo = as_ctdf(lbdo66862, time = "locationDate") |> cluster_track()


} # }
```
