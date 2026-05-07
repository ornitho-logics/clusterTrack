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

ctdf <- as_ctdf(nola125a, time = "timestamp") |>
  cluster_track()

map(ctdf)
```

- **N**:  
  - fixes:2484  
  - clusters: 10
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
#> 1:       1 2025-04-19 11:00:00 2025-05-01 19:00:00 POINT (646614.8 6238102)
#> 2:       2 2025-05-03 08:00:00 2025-05-31 03:00:00 POINT (630199.4 6228638)
#> 3:       3 2025-06-01 19:00:00 2025-06-02 04:00:00 POINT (505367.8 6245153)
#> 4:       4 2025-06-03 21:00:00 2025-06-05 04:00:00 POINT (474320.5 6250520)
#> 5:       5 2025-06-05 19:00:00 2025-06-11 03:00:00 POINT (461738.5 6242355)
#> 6:       6 2025-06-13 09:00:00 2025-06-14 06:00:00 POINT (457138.1 6231970)
#>      lof_q95       ids     N         tenure  dist_to_next elongation
#>        <num>    <char> <int>     <difftime>       <units>      <num>
#> 1:  2.402383     4-299   200 12.333333 days  18948.24 [m]          0
#> 2:  1.498983  336-1002   453 27.791667 days 125919.36 [m]          0
#> 3: 23.059129 1042-1051     9  0.375000 days  31507.81 [m]          0
#> 4:  6.124514 1092-1123    24  1.291667 days  14999.56 [m]          0
#> 5:  2.122727 1138-1266    87  5.333333 days  11358.31 [m]          0
#> 6:  4.834703 1320-1341    22  0.875000 days  20661.88 [m]          0
```
