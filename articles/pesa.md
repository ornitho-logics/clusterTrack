# Pectoral Sandpiper

``` r
require(clusterTrack)
require(clusterTrack.Vis)
```

## ARGOS locations for one male Pectoral Sandpiper.

See
[`pesa56511`](https://ornitho-logics.github.io/clusterTrack/reference/pesa56511.md)
for more information on the dataset.

``` r
data(pesa56511)

pesa <- as_ctdf(pesa56511, time = "locationDate") |>
  cluster_track()

map(pesa)
```

- **N**:  
  - fixes:863  
  - segments: 6  
  - clusters: 6
- **Parameters**:  
  - nmin = 3  
  - minCluster = 3  
  - z_min = 1  
  - trim = 0.05  
  - deltaT = NA  
  - aggregate_dist = NA
- *clusterTrack v.0.1.0.1*

``` r


summary(pesa) |>
  head()
#>    cluster               start                stop                  geometry
#>      <int>              <POSc>              <POSc>               <sfc_POINT>
#> 1:       1 2014-06-03 01:30:53 2014-06-04 05:00:22 POINT (-10052790 7771939)
#> 2:       2 2014-06-04 07:52:17 2014-06-04 15:37:33  POINT (-9968399 7758418)
#> 3:       3 2014-06-04 17:27:19 2014-06-05 04:22:12  POINT (-9970427 7754612)
#> 4:       4 2014-06-05 15:24:14 2014-06-05 18:16:43  POINT (-9865444 7728828)
#> 5:       5 2014-06-06 06:34:07 2014-06-09 20:01:01  POINT (-9658012 7710815)
#> 6:       6 2014-06-10 11:10:21 2014-06-21 02:07:48 POINT (-10051222 7769608)
#>        ids     N          tenure   dist_to_next
#>     <char> <int>      <difftime>        <units>
#> 1:    9-75    63  1.1454745 days  85467.551 [m]
#> 2:  83-107    25  0.3231019 days   4312.954 [m]
#> 3: 113-137    20  0.4547801 days 108102.828 [m]
#> 4: 155-165    10  0.1197801 days 208212.881 [m]
#> 5: 191-351   154  3.5603472 days 397581.709 [m]
#> 6: 364-862   462 10.6232292 days         NA [m]
```
