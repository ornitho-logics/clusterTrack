# Long-billed Dowitcher

``` r

require(clusterTrack)
#> Loading required package: clusterTrack
require(clusterTrack.Vis)
#> Loading required package: clusterTrack.Vis
```

## ARGOS locations for one Long-billed Dowitcher.

See
[`lbdo66862`](https://ornitho-logics.github.io/clusterTrack/reference/lbdo66862.md)
for more information on the dataset.

``` r

data(lbdo66862)

ctdf <- as_ctdf(lbdo66862, time = "locationDate") |>
  cluster_track()

map(ctdf)
```

- **N**:  
  - fixes:2501  
  - clusters: 25
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
#> 1:       1 2019-07-14 01:21:31 2019-08-02 04:29:09 POINT (-10063740 7768162)
#> 2:       2 2019-08-03 23:01:29 2019-08-04 04:32:38  POINT (-8739509 6390975)
#> 3:       3 2019-08-08 01:24:47 2019-08-15 01:06:50  POINT (-8479991 6179065)
#> 4:       4 2019-08-21 01:25:38 2019-09-02 23:47:17  POINT (-8878619 3461830)
#> 5:       5 2019-10-08 21:28:47 2019-11-02 15:14:56  POINT (-8892168 3255150)
#> 6:       6 2019-12-01 15:15:00 2020-02-17 21:56:28  POINT (-8674890 3692101)
#>     lof_q95     ids     N          tenure  dist_to_next elongation
#>       <num>  <char> <int>      <difftime>       <units>      <num>
#> 1: 1.740925    4-84    67 19.1303009 days 1910557.9 [m]  0.0000000
#> 2: 4.480081 106-112     7  0.2299653 days  335045.0 [m]  0.0000000
#> 3: 4.443263 133-162    26  6.9875347 days 2746319.6 [m]  0.2796672
#> 4: 5.177549 184-197    13 12.9317014 days  207123.9 [m]  0.0000000
#> 5: 2.731598 218-246    26 24.7820486 days  487992.6 [m]  0.0000000
#> 6: 2.115769 270-338    57 78.2787963 days  197547.9 [m]  0.0000000
```
