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
#> 1:       1 2025-04-19 11:00:00 2025-05-02 02:00:00 POINT (646614.8 6238102)
#> 2:       2 2025-05-03 08:00:00 2025-05-31 03:00:00 POINT (630432.1 6228560)
#> 3:       3 2025-06-01 19:00:00 2025-06-02 04:00:00 POINT (505367.8 6245153)
#> 4:       4 2025-06-03 21:00:00 2025-06-05 04:00:00 POINT (475285.1 6251257)
#> 5:       5 2025-06-05 19:00:00 2025-06-11 03:00:00 POINT (461738.5 6242355)
#> 6:       6 2025-06-13 09:00:00 2025-06-14 06:00:00 POINT (457138.1 6231970)
#>      lof_q95       ids     N         tenure  dist_to_next elongation
#>        <num>    <char> <int>     <difftime>       <units>      <num>
#> 1:  2.463663     4-306   209 12.625000 days  18786.47 [m]  0.0000000
#> 2:  1.535200  336-1002   490 27.791667 days 126160.27 [m]  0.0000000
#> 3: 23.059129 1042-1051     9  0.375000 days  30695.74 [m]  0.0000000
#> 4:  2.757163 1092-1123    31  1.291667 days  16210.05 [m]  0.3705069
#> 5:  2.122727 1138-1266    87  5.333333 days  11358.31 [m]  0.0000000
#> 6:  4.834703 1320-1341    22  0.875000 days  20661.88 [m]  0.0000000
```
