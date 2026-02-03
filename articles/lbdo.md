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
  - clusters: 28
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
#>    cluster               start                stop                  geometry
#>      <int>              <POSc>              <POSc>               <sfc_POINT>
#> 1:       1 2019-07-14 01:21:31 2019-08-02 04:29:09 POINT (-10067092 7767607)
#> 2:       2 2019-08-03 23:01:29 2019-08-04 04:32:38  POINT (-8739509 6390975)
#> 3:       3 2019-08-05 02:57:52 2019-08-05 17:29:34  POINT (-8517196 6230354)
#> 4:       4 2019-08-07 16:07:42 2019-08-15 01:06:50  POINT (-8475449 6178622)
#> 5:       5 2019-08-21 01:25:38 2019-08-30 16:37:33  POINT (-8879517 3461064)
#> 6:       6 2019-10-07 13:12:36 2019-10-07 21:40:28  POINT (-8914965 3264117)
#>        ids     N          tenure   dist_to_next
#>     <char> <int>      <difftime>        <units>
#> 1:    4-84    73 19.1303009 days 1912483.70 [m]
#> 2: 106-112     7  0.2299653 days  274266.30 [m]
#> 3: 119-123     5  0.6053472 days   66475.70 [m]
#> 4: 128-162    29  7.3743981 days 2747433.61 [m]
#> 5: 184-194     9  9.6332755 days  200111.73 [m]
#> 6: 213-217     5  0.3526852 days   24497.13 [m]
```
