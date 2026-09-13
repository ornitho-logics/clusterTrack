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

## Examples

``` r
data(mini_ruff)
x = as_ctdf(mini_ruff)
x = x[.id < 20][, .putative_cluster := 1]
local_cluster_ctdf(x)
#> <ctdf: 19 locations>
#> 
#>               timestamp                location   .id
#>                  <POSc>             <sfc_POINT> <int>
#>  1: 2015-05-31 14:33:09 POINT (2768520 7462407)     1
#>  2: 2015-05-31 15:12:44 POINT (2754196 7461678)     2
#>  3: 2015-05-31 16:41:01 POINT (2750888 7456491)     3
#> ---                                                  
#> 17: 2015-06-01 04:14:45 POINT (2717859 7445205)    17
#> 18: 2015-06-01 04:45:02 POINT (2722075 7445131)    18
#> 19: 2015-06-01 05:06:36 POINT (2819856 7454370)    19
x
#> <ctdf: 19 locations>
#> 
#>               timestamp                location   .id
#>                  <POSc>             <sfc_POINT> <int>
#>  1: 2015-05-31 14:33:09 POINT (2768520 7462407)     1
#>  2: 2015-05-31 15:12:44 POINT (2754196 7461678)     2
#>  3: 2015-05-31 16:41:01 POINT (2750888 7456491)     3
#> ---                                                  
#> 17: 2015-06-01 04:14:45 POINT (2717859 7445205)    17
#> 18: 2015-06-01 04:45:02 POINT (2722075 7445131)    18
#> 19: 2015-06-01 05:06:36 POINT (2819856 7454370)    19
```
