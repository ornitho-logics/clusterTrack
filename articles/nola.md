# Northern Lapwing

``` r
require(clusterTrack)
#> Loading required package: clusterTrack
require(clusterTrack.Vis)
#> Loading required package: clusterTrack.Vis
```

## GNSS locations for one female Northern Lapwing.

See
[`nola125a`](https://ornitho-logics.github.io/clusterTrack/reference/nola125a.md)
for more information on the dataset.

``` r
data(nola125a)

ruff <- as_ctdf(nola125a, time = "timestamp") |>
  cluster_track()

map(ruff)
```

- **N**:  
  - fixes:2484  
  - clusters: 16
- **Parameters**:  
  - nmin = 3  
  - minCluster = 3  
  - z_min = 1  
  - trim = 0.05  
  - deltaT = NA  
  - aggregate_dist = NA
- *clusterTrack v.0.1.0.1*
