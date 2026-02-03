# Summarise a ctdf by cluster

Returns one row per `cluster` with start/stop times, tenure (days),
convex‐hull centroid and row‐count.

## Usage

``` r
# S3 method for class 'ctdf'
summary(object, ...)
```

## Arguments

- object:

  A `ctdf` (inherits `data.table`).

- ...:

  Currently ignored.

## Value

A `data.table` (and `data.frame`) of class
c("summary_ctdf","data.table","data.frame").

## Examples

``` r
#' data(mini_ruff)
ctdf = as_ctdf(mini_ruff)
cluster_track(ctdf)
#> → Find putative cluster regions.
#> ! Spatial repair.
#> → Local clustering.
#> ! Temporal repair.
summary(ctdf)
#>    cluster               start                stop                geometry
#>      <int>              <POSc>              <POSc>             <sfc_POINT>
#> 1:       1 2015-05-31 17:43:18 2015-06-01 02:25:38 POINT (2733519 7441508)
#> 2:       2 2015-06-01 06:30:05 2015-06-03 00:22:51 POINT (2864236 7442328)
#> 3:       3 2015-06-03 06:21:09 2015-06-05 12:40:33 POINT (2943517 7429601)
#> 4:       4 2015-06-05 16:45:33 2015-06-08 19:05:21 POINT (2866074 7441004)
#>        ids     N         tenure  dist_to_next
#>     <char> <int>     <difftime>       <units>
#> 1:    5-12     8 0.3627315 days 130719.95 [m]
#> 2:   20-82    57 1.7449769 days  80295.78 [m]
#> 3:  91-177    74 2.2634722 days  78278.08 [m]
#> 4: 184-276    87 3.0970833 days        NA [m]

```
