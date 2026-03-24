# Summarise a ctdf by cluster

Returns one row per `cluster` with start and stop times, tenure in days,
convex-hull centroid, row count, the 95th percentile of within-cluster
`lof` scores, and a cluster elongation score.

## Usage

``` r
# S3 method for class 'ctdf'
summary(object, ...)
```

## Arguments

- object:

  A `ctdf` (inherits `data.table`).

- ...:

  Currently ignored.

## Value

A `summary_ctdf` `data.table` .

## Details

`lof_q95` is the 95th percentile of lof scores within each cluster.
Larger values indicate that the most extreme points in the cluster are
more locally isolated relative to their neighbours, so this can be used
as a summary of within-cluster outlier-ness.

`elongation` is a geometric cluster-shape summary derived from the
convex hull and its minimum rotated rectangle. Larger values indicate
clusters that are both relatively long in one principal dimension and
elongated for their area.

## See also

[`cluster_track()`](https://ornitho-logics.github.io/clusterTrack/reference/cluster_track.md),
[`ctdf_lof()`](https://ornitho-logics.github.io/clusterTrack/reference/ctdf_lof.md),
[`ctdf_elongation()`](https://ornitho-logics.github.io/clusterTrack/reference/ctdf_elongation.md)

## Examples

``` r
data(mini_ruff)
ctdf = as_ctdf(mini_ruff)
cluster_track(ctdf)
#> → Find putative cluster regions.
#> ! Repairing[1]...
#> → Local clustering.
#> ! Repairing[2]...
summary(ctdf)
#>    cluster               start                stop                geometry
#>      <int>              <POSc>              <POSc>             <sfc_POINT>
#> 1:       1 2015-05-31 17:43:18 2015-06-01 04:05:21 POINT (2736090 7441518)
#> 2:       2 2015-06-01 06:30:05 2015-06-03 01:29:59 POINT (2864460 7442170)
#> 3:       3 2015-06-03 06:21:09 2015-06-05 12:26:39 POINT (2941186 7429251)
#> 4:       4 2015-06-05 16:45:33 2015-06-08 19:05:21 POINT (2866074 7441004)
#>        ids     N         tenure  dist_to_next
#>     <char> <int>     <difftime>       <units>
#> 1:    5-16    12 0.4319792 days 128371.32 [m]
#> 2:   20-83    58 1.7915972 days  77806.00 [m]
#> 3:  91-176    68 2.2538194 days  76025.75 [m]
#> 4: 184-276    87 3.0970833 days        NA [m]

```
