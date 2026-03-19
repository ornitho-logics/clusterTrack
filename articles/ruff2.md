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
  - clusters: 30
- **Parameters**:  
  - nmin = 3  
  - minCluster = 3  
  - z_min = 1  
  - trim = 0.05  
  - deltaT = NA  
  - aggregate_dist = NA
- *clusterTrack v.0.1.1*

``` r

summary(ctdf) |>
  head()
#>    cluster               start                stop                 geometry
#>      <int>              <POSc>              <POSc>              <sfc_POINT>
#> 1:       1 2023-05-09 23:00:00 2023-05-10 05:00:00 POINT (646745.5 6231214)
#> 2:       2 2023-05-10 07:00:00 2023-05-10 11:00:00 POINT (643199.6 6232323)
#> 3:       3 2023-05-10 18:00:00 2023-05-16 03:00:00 POINT (644320.7 6232123)
#> 4:       4 2023-05-17 07:00:00 2023-05-27 19:00:00 POINT (645603.8 6239140)
#> 5:       5 2023-05-29 11:00:00 2023-05-29 22:00:00  POINT (2845257 7442539)
#> 6:       6 2023-05-30 08:00:00 2023-05-31 16:00:00  POINT (2869379 7461406)
#>        ids     N          tenure    dist_to_next
#>     <char> <int>      <difftime>         <units>
#> 1:    5-11     7  0.2500000 days    3715.091 [m]
#> 2:   13-17     4  0.1666667 days    1138.757 [m]
#> 3:  24-153   117  5.3750000 days    7133.224 [m]
#> 4: 181-428   226 10.5000000 days 2507318.050 [m]
#> 5: 472-483    11  0.4583333 days   30624.097 [m]
#> 6: 493-525    25  1.3333333 days  124807.012 [m]
```
