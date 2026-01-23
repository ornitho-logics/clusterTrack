# Long-billed Dowitcher

``` r
require(clusterTrack)
#> Loading required package: clusterTrack
require(clusterTrack.Vis)
#> Loading required package: clusterTrack.Vis
```

## ARGOS locations for one Long-billed Dowitcher.

``` r
data(lbdo66862)

lbdo <- as_ctdf(lbdo66862, time = "locationDate") |>
  cluster_track()

map(lbdo)
```

- **N**:  
  - fixes:2501  
  - segments: 28  
  - clusters: 28
- **Parameters**:  
  - nmin = 3  
  - minCluster = 3  
  - z_min = 1  
  - trim = 0.05  
  - deltaT = NA  
  - aggregate_dist = NA
- *clusterTrack v.0.1.0.1*
