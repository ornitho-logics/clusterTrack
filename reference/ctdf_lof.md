# Compute cluster-wise local outlier factor scores with `dbscan::lof()`

Uses
[`dbscan::lof()`](https://michael.hahsler.net/dbscan/reference/lof.html)
to compute Local Outlier Factor (LOF) scores separately within each
`cluster` of a `ctdf`, and writes the result into the `lof` column.

## Usage

``` r
ctdf_lof(ctdf, minPts = NULL)
```

## Arguments

- ctdf:

  A `ctdf` object .

- minPts:

  Optional integer passed to
  [`dbscan::lof()`](https://michael.hahsler.net/dbscan/reference/lof.html).
  If `NULL`,
  [`dbscan::lof()`](https://michael.hahsler.net/dbscan/reference/lof.html)
  is called with its defaults.

## Value

The input `ctdf` object, updated by reference with a numeric `lof`
column containing Local Outlier Factor scores computed separately within
each cluster. Locations with `cluster == 0` retain `NA` scores.

## See also

[`dbscan::lof()`](https://michael.hahsler.net/dbscan/reference/lof.html),
[`cluster_track()`](https://ornitho-logics.github.io/clusterTrack/reference/cluster_track.md).

## Examples

``` r
data(mini_ruff)
x = as_ctdf(mini_ruff)
cluster_track(x)
#> → Find putative cluster regions.
#> ! Repairing[1]...
#> → Local clustering.
#> ! Repairing[2]...
#> ! Compute lof scores...
x = ctdf_lof(x)
head(x[, .(.id, cluster, lof)])
#> <ctdf: 6 locations, 1 cluster, 4 unassigned>
#> 
#>      .id cluster      lof
#>    <int>   <int>    <num>
#> 1:     1       0       NA
#> 2:     2       0       NA
#> 3:     3       0       NA
#> 4:     4       0       NA
#> 5:     5       1 1.315277
#> 6:     6       1 1.184660
```
