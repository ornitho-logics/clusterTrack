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
  - clusters: 16
- **Parameters**:  
  - nmin = 3  
  - minCluster = 3  
  - z_min = 1  
  - trim = 0.05  
  - deltaT = NA  
  - aggregate_dist = NA
- *clusterTrack v.0.1.0.1*

``` r

summary(ctdf) |>
  head()
#>    cluster               start                stop                 geometry
#>      <int>              <POSc>              <POSc>              <sfc_POINT>
#> 1:       1 2025-04-19 11:00:00 2025-05-02 02:00:00 POINT (646562.3 6238058)
#> 2:       2 2025-05-02 16:00:00 2025-05-02 20:00:00 POINT (642460.3 6235361)
#> 3:       3 2025-05-03 08:00:00 2025-05-31 01:00:00 POINT (630420.2 6228567)
#> 4:       4 2025-05-31 20:00:00 2025-06-01 02:00:00 POINT (565079.1 6244541)
#> 5:       5 2025-06-01 19:00:00 2025-06-02 04:00:00 POINT (505367.8 6245153)
#> 6:       6 2025-06-02 20:00:00 2025-06-03 03:00:00 POINT (476590.9 6241971)
#>          ids     N          tenure  dist_to_next
#>       <char> <int>      <difftime>       <units>
#> 1:     4-306   284 12.6250000 days  4908.815 [m]
#> 2:   320-324     4  0.1666667 days 13824.864 [m]
#> 3:  336-1000   622 27.7083333 days 67265.321 [m]
#> 4: 1019-1025     7  0.2500000 days 59714.479 [m]
#> 5: 1042-1051     9  0.3750000 days 28952.235 [m]
#> 6: 1067-1074     7  0.2916667 days  9377.227 [m]
```
