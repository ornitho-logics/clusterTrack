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
#> ! Repairing[1]...
#> → Local clustering.
#> ! Repairing[2]...
summary(ctdf)
#>    cluster               start                stop                geometry
#>      <int>              <POSc>              <POSc>             <sfc_POINT>
#> 1:       1 2015-05-31 17:43:18 2015-06-01 04:05:21 POINT (2736090 7441518)
#> 2:       2 2015-06-01 06:30:05 2015-06-03 01:29:59 POINT (2864460 7442170)
#> 3:       3 2015-06-03 06:21:09 2015-06-05 12:40:33 POINT (2944221 7429070)
#> 4:       4 2015-06-05 16:45:33 2015-06-08 19:05:21 POINT (2866074 7441004)
#>        ids     N         tenure  dist_to_next
#>     <char> <int>     <difftime>       <units>
#> 1:    5-16    12 0.4319792 days 128371.32 [m]
#> 2:   20-83    58 1.7915972 days  80830.16 [m]
#> 3:  91-177    77 2.2634722 days  79053.36 [m]
#> 4: 184-276    87 3.0970833 days        NA [m]

```
