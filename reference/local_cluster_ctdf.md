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
#> Key: <.id>
#>               timestamp                location cluster   lof   .id .move_seg
#>                  <POSc>             <sfc_POINT>   <int> <num> <int>     <int>
#>  1: 2015-05-31 14:33:09 POINT (2768520 7462407)      NA    NA     1        NA
#>  2: 2015-05-31 15:12:44 POINT (2754196 7461678)      NA    NA     2        NA
#>  3: 2015-05-31 16:41:01 POINT (2750888 7456491)      NA    NA     3        NA
#>  4: 2015-05-31 16:50:30 POINT (2763441 7456126)      NA    NA     4        NA
#>  5: 2015-05-31 17:43:18 POINT (2735106 7438659)      NA    NA     5        NA
#>  6: 2015-05-31 18:20:13 POINT (2733011 7442926)      NA    NA     6        NA
#>  7: 2015-05-31 18:29:54 POINT (2736923 7441750)      NA    NA     7        NA
#>  8: 2015-05-31 21:39:40 POINT (2730516 7440352)      NA    NA     8        NA
#>  9: 2015-05-31 23:16:09 POINT (2731106 7440057)      NA    NA     9        NA
#> 10: 2015-06-01 00:40:46 POINT (2728589 7444029)      NA    NA    10        NA
#> 11: 2015-06-01 00:54:55 POINT (2734721 7442191)      NA    NA    11        NA
#> 12: 2015-06-01 02:25:38 POINT (2738852 7442338)      NA    NA    12        NA
#> 13: 2015-06-01 02:32:32 POINT (2738948 7442264)      NA    NA    13        NA
#> 14: 2015-06-01 02:33:30 POINT (2738005 7441235)      NA    NA    14        NA
#> 15: 2015-06-01 03:23:38 POINT (2746202 7441014)      NA    NA    15        NA
#> 16: 2015-06-01 04:05:21 POINT (2737081 7443735)      NA    NA    16        NA
#> 17: 2015-06-01 04:14:45 POINT (2717859 7445205)      NA    NA    17        NA
#> 18: 2015-06-01 04:45:02 POINT (2722075 7445131)      NA    NA    18        NA
#> 19: 2015-06-01 05:06:36 POINT (2819856 7454370)      NA    NA    19        NA
#>     .seg_id .putative_cluster
#>       <int>             <int>
#>  1:      NA                NA
#>  2:      NA                NA
#>  3:      NA                NA
#>  4:      NA                NA
#>  5:      NA                 1
#>  6:      NA                 1
#>  7:      NA                 1
#>  8:      NA                 1
#>  9:      NA                 1
#> 10:      NA                 1
#> 11:      NA                 1
#> 12:      NA                 1
#> 13:      NA                 1
#> 14:      NA                 1
#> 15:      NA                NA
#> 16:      NA                 1
#> 17:      NA                NA
#> 18:      NA                NA
#> 19:      NA                NA
x
#> Key: <.id>
#>               timestamp                location cluster   lof   .id .move_seg
#>                  <POSc>             <sfc_POINT>   <int> <num> <int>     <int>
#>  1: 2015-05-31 14:33:09 POINT (2768520 7462407)      NA    NA     1        NA
#>  2: 2015-05-31 15:12:44 POINT (2754196 7461678)      NA    NA     2        NA
#>  3: 2015-05-31 16:41:01 POINT (2750888 7456491)      NA    NA     3        NA
#>  4: 2015-05-31 16:50:30 POINT (2763441 7456126)      NA    NA     4        NA
#>  5: 2015-05-31 17:43:18 POINT (2735106 7438659)      NA    NA     5        NA
#>  6: 2015-05-31 18:20:13 POINT (2733011 7442926)      NA    NA     6        NA
#>  7: 2015-05-31 18:29:54 POINT (2736923 7441750)      NA    NA     7        NA
#>  8: 2015-05-31 21:39:40 POINT (2730516 7440352)      NA    NA     8        NA
#>  9: 2015-05-31 23:16:09 POINT (2731106 7440057)      NA    NA     9        NA
#> 10: 2015-06-01 00:40:46 POINT (2728589 7444029)      NA    NA    10        NA
#> 11: 2015-06-01 00:54:55 POINT (2734721 7442191)      NA    NA    11        NA
#> 12: 2015-06-01 02:25:38 POINT (2738852 7442338)      NA    NA    12        NA
#> 13: 2015-06-01 02:32:32 POINT (2738948 7442264)      NA    NA    13        NA
#> 14: 2015-06-01 02:33:30 POINT (2738005 7441235)      NA    NA    14        NA
#> 15: 2015-06-01 03:23:38 POINT (2746202 7441014)      NA    NA    15        NA
#> 16: 2015-06-01 04:05:21 POINT (2737081 7443735)      NA    NA    16        NA
#> 17: 2015-06-01 04:14:45 POINT (2717859 7445205)      NA    NA    17        NA
#> 18: 2015-06-01 04:45:02 POINT (2722075 7445131)      NA    NA    18        NA
#> 19: 2015-06-01 05:06:36 POINT (2819856 7454370)      NA    NA    19        NA
#>     .seg_id .putative_cluster
#>       <int>             <int>
#>  1:      NA                NA
#>  2:      NA                NA
#>  3:      NA                NA
#>  4:      NA                NA
#>  5:      NA                 1
#>  6:      NA                 1
#>  7:      NA                 1
#>  8:      NA                 1
#>  9:      NA                 1
#> 10:      NA                 1
#> 11:      NA                 1
#> 12:      NA                 1
#> 13:      NA                 1
#> 14:      NA                 1
#> 15:      NA                NA
#> 16:      NA                 1
#> 17:      NA                NA
#> 18:      NA                NA
#> 19:      NA                NA
```
