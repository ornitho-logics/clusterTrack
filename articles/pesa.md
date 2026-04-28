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

ctdf <- as_ctdf(pesa56511, time = "locationDate") |>
  cluster_track()

map(ctdf)
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
- *clusterTrack v.0.1.1*

``` r



summary(ctdf) |>
  head()
#>    cluster               start                stop                  geometry
#>      <int>              <POSc>              <POSc>               <sfc_POINT>
#> 1:       1 2014-06-02 23:25:19 2014-06-04 05:00:22 POINT (-10052790 7771939)
#> 2:       2 2014-06-04 07:39:07 2014-06-04 15:37:33  POINT (-9968113 7758451)
#> 3:       3 2014-06-04 17:20:36 2014-06-05 04:22:12  POINT (-9970427 7754612)
#> 4:       4 2014-06-05 13:55:36 2014-06-05 18:55:02  POINT (-9862130 7729138)
#> 5:       5 2014-06-05 22:21:00 2014-06-09 20:01:01  POINT (-9658104 7710720)
#> 6:       6 2014-06-10 09:31:53 2014-06-21 02:07:48 POINT (-10051693 7769286)
#>     lof_q95     ids     N          tenure   dist_to_next elongation
#>       <num>  <char> <int>      <difftime>        <units>      <num>
#> 1: 2.436335    5-75    66  1.2326736 days  85744.755 [m]  0.0000000
#> 2: 1.579420  82-107    23  0.3322454 days   4482.812 [m]  0.0000000
#> 3: 2.123607 112-137    22  0.4594444 days 111252.561 [m]  0.0000000
#> 4: 3.102805 150-167    16  0.2079398 days 204855.239 [m]  0.0000000
#> 5: 1.984879 177-351   142  3.9027894 days 397922.526 [m]  0.7360091
#> 6: 1.553390 362-862   447 10.6916088 days         NA [m]  0.0000000
```
