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

ruff <- as_ctdf(ruff07b5, time = "timestamp") |>
  cluster_track()

map(ruff)
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
