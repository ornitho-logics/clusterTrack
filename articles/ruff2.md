# Ruff

``` r
require(clusterTrack)
#> Loading required package: clusterTrack
require(clusterTrack.Vis)
#> Loading required package: clusterTrack.Vis
```

## GNSS locations for one male Ruff.

See
[`ruff07b5`](https://ornitho-logics.github.io/clusterTrack/reference/ruff07b5.md)
for more information on the dataset.

``` r
data(ruff07b5)

ctdf <- as_ctdf(ruff07b5, time = "timestamp") |>
  cluster_track()

map(ctdf)
```

- **N**:  
  - fixes:2772  
  - clusters: 29
- **Parameters**:  
  - nmin = 3  
  - minCluster = 3  
  - z_min = 1  
  - trim = 0.05  
  - deltaT = NA  
  - aggregate_dist = NA
- *clusterTrack v.0.1.0.1*

``` r

summary(ctdf) |>
  head()
#>    cluster               start                stop                 geometry
#>      <int>              <POSc>              <POSc>              <sfc_POINT>
#> 1:       1 2023-05-09 23:00:00 2023-05-10 05:00:00 POINT (646745.5 6231214)
#> 2:       2 2023-05-10 07:00:00 2023-05-10 11:00:00 POINT (643199.6 6232323)
#> 3:       3 2023-05-10 13:00:00 2023-05-16 03:00:00 POINT (644221.2 6232176)
#> 4:       4 2023-05-17 07:00:00 2023-05-27 19:00:00 POINT (645602.3 6239139)
#> 5:       5 2023-05-29 11:00:00 2023-05-29 22:00:00  POINT (2845257 7442539)
#> 6:       6 2023-05-30 08:00:00 2023-06-01 04:00:00  POINT (2868101 7461703)
#>        ids     N          tenure    dist_to_next
#>     <char> <int>      <difftime>         <units>
#> 1:    5-11     7  0.2500000 days    3715.091 [m]
#> 2:   13-17     4  0.1666667 days    1032.105 [m]
#> 3:  19-153   124  5.5833333 days    7098.787 [m]
#> 4: 181-428   236 10.5000000 days 2507319.633 [m]
#> 5: 472-483    11  0.4583333 days   29817.777 [m]
#> 6: 493-537    45  1.8333333 days  125855.540 [m]
```
