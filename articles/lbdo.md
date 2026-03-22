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
  - clusters: 30
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
#> 3:       3 2019-08-05 02:57:52 2019-08-05 22:37:49  POINT (-8515915 6230399)
#> 4:       4 2019-08-08 01:24:47 2019-08-15 01:06:50  POINT (-8479991 6179065)
#> 5:       5 2019-08-21 01:25:38 2019-09-02 23:47:17  POINT (-8878619 3461830)
#> 6:       6 2019-10-07 13:12:36 2019-10-07 21:40:28  POINT (-8914965 3264117)
#>        ids     N          tenure   dist_to_next
#>     <char> <int>      <difftime>        <units>
#> 1:    4-84    67 19.1303009 days 1910557.91 [m]
#> 2: 106-112     7  0.2299653 days  275280.10 [m]
#> 3: 119-125     7  0.8194097 days   62654.73 [m]
#> 4: 133-162    26  6.9875347 days 2746319.60 [m]
#> 5: 184-197    13 12.9317014 days  201025.46 [m]
#> 6: 213-217     5  0.3526852 days   24497.13 [m]
```
