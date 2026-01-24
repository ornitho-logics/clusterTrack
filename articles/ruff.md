# Ruff

``` r
require(clusterTrack)
#> Loading required package: clusterTrack
require(clusterTrack.Vis)
#> Loading required package: clusterTrack.Vis
```

## ARGOS locations for one male Ruff.

See \[`ruff143789`\] for more information on the dataset.

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
  - nmin = 3  
  - minCluster = 3  
  - z_min = 1  
  - trim = 0.05  
  - deltaT = NA  
  - aggregate_dist = NA
- *clusterTrack v.0.1.0.1*
