# Ruff

``` r
require(clusterTrack)
#> Loading required package: clusterTrack
require(clusterTrack.Vis)
#> Loading required package: clusterTrack.Vis
```

## ARGOS locations for one male Ruff.

See
[`ruff143789`](https://ornitho-logics.github.io/clusterTrack/reference/ruff143789.md)
for more information on the dataset.

``` r
data(ruff143789)

ctdf <- as_ctdf(ruff143789, time = "locationDate") |>
  cluster_track()

map(ctdf)
```

- **N**:  
  - fixes:2402  
  - clusters: 20
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
#> 1:       1 2015-04-15 14:26:13 2015-05-06 04:28:31 POINT (416596.3 6273560)
#> 2:       2 2015-05-06 09:52:40 2015-05-17 19:11:40 POINT (551689.2 6328462)
#> 3:       3 2015-05-18 04:50:47 2015-05-19 04:42:04  POINT (1666609 6267098)
#> 4:       4 2015-05-19 07:47:14 2015-05-22 14:52:59  POINT (1554699 6377796)
#> 5:       5 2015-05-23 08:59:39 2015-05-24 02:11:08  POINT (2410984 7329084)
#> 6:       6 2015-05-24 07:36:29 2015-05-26 02:50:44  POINT (3000405 7408612)
#>         ids     N          tenure  dist_to_next
#>      <char> <int>      <difftime>       <units>
#> 1:   16-488   433 20.5849306 days  145823.0 [m]
#> 2:  498-759   239 11.3881944 days 1116607.1 [m]
#> 3:  769-795    26  0.9939468 days  157409.1 [m]
#> 4:  799-879    69  3.2956597 days 1279911.6 [m]
#> 5:  909-930    22  0.7163079 days  594761.9 [m]
#> 6: 943-1003    53  1.8015625 days  178361.2 [m]
```
