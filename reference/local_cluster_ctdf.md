# Local clustering using DTSCAN

Within each existing `.putative_cluster` region (typically produced by
[`slice_ctdf()`](https://ornitho-logics.github.io/clusterTrack/reference/slice_ctdf.md)),
run
[`sf_dtscan()`](https://ornitho-logics.github.io/clusterTrack/reference/sf_dtscan.md)
on the points in that region to split it into one or more local spatial
subclusters. The resulting labels are combined with the parent
`.putative_cluster` id and written back to `.putative_cluster` in-place.

## Usage

``` r
local_cluster_ctdf(ctdf, nmin = 3, area_z_min = 0, length_z_min = 0)
```

## Arguments

- ctdf:

  A `ctdf` object.

- nmin:

  Integer; passed as `min_pts` to
  [`sf_dtscan()`](https://ornitho-logics.github.io/clusterTrack/reference/sf_dtscan.md)
  when clustering within each `.putative_cluster` region.

- area_z_min:

  Numeric; passed to
  [`sf_dtscan()`](https://ornitho-logics.github.io/clusterTrack/reference/sf_dtscan.md)
  as `area_z_min`.

- length_z_min:

  Numeric; passed to
  [`sf_dtscan()`](https://ornitho-logics.github.io/clusterTrack/reference/sf_dtscan.md)
  as `length_z_min`.

## Value

The input `ctdf`, invisibly, with `.putative_cluster` updated in-place.

## See also

[`sf_dtscan()`](https://ornitho-logics.github.io/clusterTrack/reference/sf_dtscan.md)
