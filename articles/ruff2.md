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
  - clusters: 28
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
#> 2:       2 2023-05-11 12:00:00 2023-05-16 03:00:00 POINT (644428.6 6232152)
#> 3:       3 2023-05-17 07:00:00 2023-05-27 19:00:00 POINT (645544.4 6239096)
#> 4:       4 2023-05-29 11:00:00 2023-05-29 22:00:00  POINT (2845257 7442539)
#> 5:       5 2023-05-30 08:00:00 2023-06-01 04:00:00  POINT (2868101 7461703)
#> 6:       6 2023-06-02 07:00:00 2023-06-07 15:00:00  POINT (2990751 7464611)
#>     lof_q95     ids     N          tenure    dist_to_next  elongation
#>       <num>  <char> <int>      <difftime>         <units>       <num>
#> 1: 1.162738    5-11     7  0.2500000 days    2499.255 [m] 0.000000000
#> 2: 4.400319  42-153    83  4.6250000 days    7033.694 [m] 0.455860321
#> 3: 4.182494 181-428   173 10.5000000 days 2507391.057 [m] 0.000000000
#> 4: 2.267933 472-483    12  0.4583333 days   29817.777 [m] 0.000000000
#> 5: 4.641147 493-537    43  1.8333333 days  122684.539 [m] 0.005209972
#> 6: 2.597580 565-693    93  5.3333333 days    5238.258 [m] 0.000000000
```
