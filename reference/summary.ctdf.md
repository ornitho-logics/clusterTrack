# Summarise a ctdf by cluster

Returns one row per `cluster` with start/stop times, tenure (days),
convex‐hull centroid and row‐count.

## Usage

``` r
# S3 method for class 'ctdf'
summary(ctdf, ...)
```

## Arguments

- ...:

  Currently ignored.

- object:

  A `ctdf` (inherits `data.table`).

## Value

A `data.table` (and `data.frame`) of class
c("summary_ctdf","data.table","data.frame").

## Examples

``` r
#' data(mini_ruff)
ctdf = as_ctdf(mini_ruff)
cluster_track(ctdf)
#> → Finding putative cluster regions.
#> → Preparing for local clustering.
#> → Running local clustering.
summary(ctdf)
#>    cluster               start                stop                geometry     ids     N
#>      <int>              <POSc>              <POSc>             <sfc_POINT>  <char> <int>
#> 1:       1 2015-05-31 17:43:18 2015-06-01 02:25:38 POINT (2733519 7441508)    5-12     8
#> 2:       2 2015-06-01 08:58:48 2015-06-03 00:22:51 POINT (2863276 7442316)   26-82    50
#> 3:       3 2015-06-03 06:21:09 2015-06-05 12:40:33 POINT (2943517 7429601)  91-177    74
#> 4:       4 2015-06-06 01:36:52 2015-06-08 19:05:21 POINT (2865266 7441365) 191-276    81
#>            tenure  dist_to_next
#>        <difftime>       <units>
#> 1: 0.3627315 days 129759.27 [m]
#> 2: 1.6417014 days  81242.50 [m]
#> 3: 2.2634722 days  79130.26 [m]
#> 4: 2.7281134 days        NA [m]

```
