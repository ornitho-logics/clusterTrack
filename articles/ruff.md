# Ruff

``` r
require(clusterTrack)
#> Loading required package: clusterTrack
require(clusterTrack.Vis)
#> Loading required package: clusterTrack.Vis
```

## ARGOS locations for one male Ruff.

``` r
data(ruff143789)

ruff <- as_ctdf(ruff143789, time = "locationDate") |>
  cluster_track()

map(ruff)
```

- **N**:  
  - fixes:2402  
  - segments: 25  
  - clusters: 25
- **Parameters**:  
  - deltaT = 30  
  - nmin = 3  
  - minCluster = 3  
  - area_z_min = 1  
  - length_z_min = 1  
  - trim = 0.05  
  - aggregate_dist = NA
- *clusterTrack v.0.1.0.1*
