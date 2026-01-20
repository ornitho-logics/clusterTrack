# Pectoral Sandpiper

``` r
require(clusterTrack)
require(clusterTrack.Vis)
```

## ARGOS locations for one male Pectoral Sandpiper.

``` r
data(mini_ruff)

pesa <- as_ctdf(mini_ruff, time = "time") |>
  cluster_track()

map(pesa)
```

- **N**:  
  - fixes:276  
  - segments: 4  
  - clusters: 4
- **Parameters**:  
  - deltaT = 30  
  - nmin = 3  
  - minCluster = 3  
  - area_z_min = 1  
  - length_z_min = 1  
  - trim = 0.05  
  - aggregate_dist = NA
- *clusterTrack v.0.1.0.1*

``` r


summary(pesa) |>
  head()
#>    cluster               start                stop                geometry
#>      <int>              <POSc>              <POSc>             <sfc_POINT>
#> 1:       1 2015-05-31 17:43:18 2015-06-01 02:25:38 POINT (2733519 7441508)
#> 2:       2 2015-06-01 08:58:48 2015-06-03 00:22:51 POINT (2863276 7442316)
#> 3:       3 2015-06-03 06:21:09 2015-06-05 12:40:33 POINT (2943517 7429601)
#> 4:       4 2015-06-06 01:36:52 2015-06-08 19:05:21 POINT (2865266 7441365)
#>        ids     N         tenure  dist_to_next
#>     <char> <int>     <difftime>       <units>
#> 1:    5-12     8 0.3627315 days 129759.27 [m]
#> 2:   26-82    50 1.6417014 days  81242.50 [m]
#> 3:  91-177    74 2.2634722 days  79130.26 [m]
#> 4: 191-276    81 2.7281134 days        NA [m]
```
