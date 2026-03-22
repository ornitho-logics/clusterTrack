# Score outliers in a ctdf using dbscan methods

Computes outlier scores for each location in a `ctdf` and returns a copy
with one appended score column.

## Usage

``` r
outliers(
  ctdf,
  method = c("lof", "glosh"),
  type = c("within-cluster", "between-clusters"),
  minPts,
  k
)
```

## Arguments

- ctdf:

  A `ctdf` object.

- method:

  Character scalar. One of `"lof"` or `"glosh"`.

- type:

  Character scalar. Currently only `"within-cluster"` is supported.

- minPts:

  Optional integer. Passed to
  [`dbscan::lof()`](https://rdrr.io/pkg/dbscan/man/lof.html).

- k:

  Optional integer. Passed to
  [`dbscan::glosh()`](https://rdrr.io/pkg/dbscan/man/glosh.html).

## Value

A copy of `ctdf` with one appended outlier score column.

## Details

For now, only within-cluster scoring is supported. Existing `cluster`
labels are used only to define subsets. Outlier scores are then computed
independently within each subset.
