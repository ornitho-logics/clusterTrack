# Cluster a movement track into spatiotemporal clusters `cluster_track()` identifies use sites: areas where an individual concentrates its activity during distinct periods along a movement track.

The method initially splits the track into provisional regions, allowing
spatial clustering to adapt to local conditions. Neighbouring regions or
clusters are combined when their spatial structure provides insufficient
evidence for keeping them separate.

## Usage

``` r
cluster_track(
  ctdf,
  nmin = 3,
  z_min = 1,
  trim = 0.05,
  minCluster = 3,
  deltaT,
  aggregate_dist,
  trace = FALSE
)
```

## Arguments

- ctdf:

  A `ctdf` object (see
  [`as_ctdf()`](https://ornitho-logics.github.io/clusterTrack/reference/as_ctdf.md)).

- nmin:

  Integer; local DTSCAN support threshold. Passed to
  [`local_cluster_ctdf()`](https://ornitho-logics.github.io/clusterTrack/reference/local_cluster_ctdf.md)
  as `nmin`, then to
  [`sf_dtscan()`](https://ornitho-logics.github.io/clusterTrack/reference/sf_dtscan.md)
  as `min_pts`, where it defines the minimum effective
  Delaunay-neighbour count for a core site.

- z_min:

  Numeric; pruning strictness in SD units. Smaller values produce more
  compact clusters and often more unassigned points. Implementation
  detail: the underlying thresholds use an inverse z-score convention,
  so the sign is flipped internally; see
  [`sf_dtscan()`](https://ornitho-logics.github.io/clusterTrack/reference/sf_dtscan.md)
  and
  [`local_cluster_ctdf()`](https://ornitho-logics.github.io/clusterTrack/reference/local_cluster_ctdf.md).

- trim:

  Numeric; passed to
  [`temporal_repair()`](https://ornitho-logics.github.io/clusterTrack/reference/temporal_repair.md).
  Maximum fraction trimmed from each tail estimating each cluster's time
  domain.

- minCluster:

  Integer; post-clustering pruning threshold. Putative clusters with
  `N <= minCluster` are dropped.

- deltaT:

  Optional numeric; passed to
  [`slice_ctdf()`](https://ornitho-logics.github.io/clusterTrack/reference/slice_ctdf.md).
  Maximum allowable time gap (in days).

- aggregate_dist:

  Optional numeric; if supplied, passed to
  [`aggregate_ctdf()`](https://ornitho-logics.github.io/clusterTrack/reference/aggregate_ctdf.md)
  as `dist` (numeric treated as km).

- trace:

  Logical; if TRUE, store intermediate .putative_cluster labels from the
  cluster_track() pipeline in attr(ctdf, "putative_cluster_trace").

## Value

Invisibly returns `ctdf`, with `cluster` updated in-place and
`attr(ctdf, "cluster_params")` set.

## Details

The resulting use sites describe where and when the animal concentrated
its activity, allowing separate visits to the same place to be
distinguished. Optional distance-based aggregation combines nearby,
temporally adjacent sites at a spatial scale chosen by the user.

The function updates `ctdf` by reference and stores its parameters in
`attr(ctdf, "cluster_params")`.

## See also

[`as_ctdf()`](https://ornitho-logics.github.io/clusterTrack/reference/as_ctdf.md),
[`slice_ctdf()`](https://ornitho-logics.github.io/clusterTrack/reference/slice_ctdf.md),
[`spatial_repair()`](https://ornitho-logics.github.io/clusterTrack/reference/spatial_repair.md),
[`local_cluster_ctdf()`](https://ornitho-logics.github.io/clusterTrack/reference/local_cluster_ctdf.md),
[`sf_dtscan()`](https://ornitho-logics.github.io/clusterTrack/reference/sf_dtscan.md),
[`temporal_repair()`](https://ornitho-logics.github.io/clusterTrack/reference/temporal_repair.md),
[`aggregate_ctdf()`](https://ornitho-logics.github.io/clusterTrack/reference/aggregate_ctdf.md),
[`putative_cluster_trace()`](https://ornitho-logics.github.io/clusterTrack/reference/putative_cluster_trace.md)

## Examples

``` r
data(mini_ruff)
x = as_ctdf(mini_ruff) |> cluster_track()
#> → Find putative cluster regions.
#> ! Repairing[1]...
#> → Local clustering.
#> ! Repairing[2]...
#> ! Compute lof scores...

if (FALSE) { # \dontrun{
data(pesa56511)
pesa = as_ctdf(pesa56511, time = "locationDate") |> cluster_track()

data(ruff143789)
ruff = as_ctdf(ruff143789, time = "locationDate") |> cluster_track()

data(ruff07b5)
ruff2 = as_ctdf(ruff07b5, time = "timestamp") |> cluster_track()

data(lbdo66862)
lbdo = as_ctdf(lbdo66862, time = "locationDate") |> cluster_track()

data(nola125a)
nola = as_ctdf(nola125a, time = "timestamp") |> cluster_track()


} # }
```
