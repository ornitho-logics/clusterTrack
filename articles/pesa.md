# Pectoral Sandpiper

``` r
require(clusterTrack)
require(clusterTrack.Vis)
```

## ARGOS locations for one male Pectoral Sandpiper.

See
[`pesa56511`](https://ornitho-logics.github.io/clusterTrack/reference/pesa56511.md)
for more information on the dataset.

``` r
data(pesa56511)

pesa <- as_ctdf(pesa56511, time = "locationDate") |>
  cluster_track()

map(pesa)
```

- **N**:  
  - fixes:863  
  - clusters: 6
- **Parameters**:  
  - nmin = 3  
  - minCluster = 3  
  - z_min = 1  
  - trim = 0.05  
  - deltaT = NA  
  - aggregate_dist = NA
- *clusterTrack v.0.1.0.1*

``` r


summary(pesa) |>
  head()
#>    cluster               start                stop                  geometry
#>      <int>              <POSc>              <POSc>               <sfc_POINT>
#> 1:       1 2014-06-03 00:34:18 2014-06-03 23:21:32 POINT (-10055270 7772432)
#> 2:       2 2014-06-04 07:39:07 2014-06-04 15:37:33  POINT (-9968399 7758418)
#> 3:       3 2014-06-04 17:20:36 2014-06-05 04:22:12  POINT (-9970427 7754612)
#> 4:       4 2014-06-05 13:55:36 2014-06-05 18:16:43  POINT (-9862118 7729126)
#> 5:       5 2014-06-05 22:21:00 2014-06-09 20:01:01  POINT (-9657317 7711109)
#> 6:       6 2014-06-10 09:39:02 2014-06-21 02:07:48 POINT (-10051222 7769608)
#>        ids     N          tenure   dist_to_next
#>     <char> <int>      <difftime>        <units>
#> 1:    8-67    55  0.9494676 days  87994.387 [m]
#> 2:  82-107    26  0.3322454 days   4312.954 [m]
#> 3: 112-137    22  0.4594444 days 111267.054 [m]
#> 4: 150-165    15  0.1813310 days 205591.644 [m]
#> 5: 177-351   167  3.9027894 days 398225.234 [m]
#> 6: 363-862   463 10.6866435 days         NA [m]
```
