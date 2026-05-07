# Extract putative-cluster trace

Extract putative-cluster trace

## Usage

``` r
putative_cluster_trace(x)
```

## Arguments

- x:

  A `ctdf` object returned by `cluster_track(trace = TRUE)`.

## Value

A `data.table`, or `NULL`.

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

tr = putative_cluster_trace(x)
tr
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
```
