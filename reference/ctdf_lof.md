# Compute cluster-wise local outlier factor scores with `dbscan::lof()`

Uses [`dbscan::lof()`](https://rdrr.io/pkg/dbscan/man/lof.html) to
compute Local Outlier Factor (LOF) scores separately within each
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
  [`dbscan::lof()`](https://rdrr.io/pkg/dbscan/man/lof.html). If `NULL`,
  [`dbscan::lof()`](https://rdrr.io/pkg/dbscan/man/lof.html) is called
  with its defaults.

  The function updates `ctdf` by reference by updating the `lof` column.

## See also

[`dbscan::lof()`](https://rdrr.io/pkg/dbscan/man/lof.html),
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
x = ctdf_lof(x)
#> Error in ctdf_lof(x): could not find function "ctdf_lof"
head(x[, .(.id, cluster, lof)])
#> Error in eval(jsub, SDenv, parent.frame()): object 'lof' not found
```
