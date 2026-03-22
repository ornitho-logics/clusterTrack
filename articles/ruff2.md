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
  - clusters: 38
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
#> 3:       3 2023-05-11 07:00:00 2023-05-11 15:00:00 POINT (644180.5 6232104)
#> 4:       4 2023-05-11 12:00:00 2023-05-16 03:00:00 POINT (644428.6 6232152)
#> 5:       5 2023-05-17 07:00:00 2023-05-27 19:00:00 POINT (645544.4 6239096)
#> 6:       6 2023-05-28 19:00:00 2023-05-29 00:00:00  POINT (2630551 7315072)
#>        ids     N          tenure     dist_to_next
#>     <char> <int>      <difftime>          <units>
#> 1:    5-11     7  0.2500000 days    3715.0912 [m]
#> 2:   13-17     5  0.1666667 days    1005.1532 [m]
#> 3:   37-45     7  0.3333333 days     252.7692 [m]
#> 4:  42-153    83  4.6250000 days    7033.6943 [m]
#> 5: 181-428   173 10.5000000 days 2257869.4599 [m]
#> 6: 457-462     6  0.2083333 days  249692.9519 [m]
```
