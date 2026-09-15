# Extract putative-cluster trace

Extracts the intermediate `.putative_cluster` assignments recorded
during
[`cluster_track()`](https://ornitho-logics.github.io/clusterTrack/reference/cluster_track.md)
when called with `trace = TRUE`.

## Usage

``` r
putative_cluster_trace(x, bind = FALSE)
```

## Arguments

- x:

  A `ctdf` object returned by `cluster_track(trace = TRUE)`.

- bind:

  Logical. If `FALSE`, return the trace as a `data.table`. If `TRUE`,
  return a copy of `x` with the trace columns appended.

## Value

If `bind = FALSE`, a `data.table` containing `.id` and one column for
each recorded clustering stage. If `bind = TRUE`, a `ctdf` with the
trace columns appended. Returns `NULL` if no trace is stored.

## Details

The stored trace is aligned to the `ctdf` by `.id`. When `bind = TRUE`,
`.id` must be identical in the trace and `x`; otherwise an error is
raised. The input `x` is not modified.

## Examples

``` r
data(mini_ruff)

x = as_ctdf(mini_ruff)
cluster_track(x, trace = TRUE)
#> → Find putative cluster regions.
#> ! Repairing[1]...
#> → Local clustering.
#> ! Repairing[2]...
#> ! Compute lof scores...

putative_cluster_trace(x)
#>        .id slice spatial_repair_1 dtscan spatial_repair_2 subset_by_minCluster
#>      <int> <int>            <int>  <int>            <int>                <int>
#>   1:     1    NA               NA     NA               NA                   NA
#>   2:     2    NA               NA     NA               NA                   NA
#>   3:     3     1                1     NA               NA                   NA
#>   4:     4     1                1     NA               NA                   NA
#>   5:     5     1                1      1                1                    1
#>  ---                                                                          
#> 272:   272     7                4      4                4                    4
#> 273:   273     7                4      4                4                    4
#> 274:   274     7                4      4                4                    4
#> 275:   275     7                4      4                4                    4
#> 276:   276     7                4      4                4                    4
#>      drop_false_cluster temporal_repair
#>                   <int>           <int>
#>   1:                 NA              NA
#>   2:                 NA              NA
#>   3:                 NA              NA
#>   4:                 NA              NA
#>   5:                  1               1
#>  ---                                   
#> 272:                  4               4
#> 273:                  4               4
#> 274:                  4               4
#> 275:                  4               4
#> 276:                  4               4
putative_cluster_trace(x, bind = TRUE)
#> <ctdf: 276 locations, 4 clusters, 51 unassigned>
#> 
#>                timestamp                location   .id cluster      lof slice
#>                   <POSc>             <sfc_POINT> <int>   <int>    <num> <int>
#>   1: 2015-05-31 14:33:09 POINT (2768520 7462407)     1       0       NA    NA
#>   2: 2015-05-31 15:12:44 POINT (2754196 7461678)     2       0       NA    NA
#>   3: 2015-05-31 16:41:01 POINT (2750888 7456491)     3       0       NA     1
#>  ---                                                                         
#> 274: 2015-06-08 17:29:12 POINT (2866087 7439689)   274       4 1.463335     7
#> 275: 2015-06-08 18:17:42 POINT (2864375 7440720)   275       4 1.014616     7
#> 276: 2015-06-08 19:05:21 POINT (2869939 7439689)   276       4 1.124653     7
#>      spatial_repair_1 dtscan spatial_repair_2 subset_by_minCluster
#>                 <int>  <int>            <int>                <int>
#>   1:               NA     NA               NA                   NA
#>   2:               NA     NA               NA                   NA
#>   3:                1     NA               NA                   NA
#>  ---                                                              
#> 274:                4      4                4                    4
#> 275:                4      4                4                    4
#> 276:                4      4                4                    4
#>      drop_false_cluster temporal_repair
#>                   <int>           <int>
#>   1:                 NA              NA
#>   2:                 NA              NA
#>   3:                 NA              NA
#>  ---                                   
#> 274:                  4               4
#> 275:                  4               4
#> 276:                  4               4
```
