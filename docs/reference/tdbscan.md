# tdbscan

tdbscan

## Usage

``` r
tdbscan(track, eps, minPts = 5, borderPoints = FALSE, maxLag = 6, minTenure)
```

## Arguments

- track:

  A sf object (for now).

- eps:

  size of the epsilon neighborhood (see
  [`dbscan::dbscan()`](https://rdrr.io/pkg/dbscan/man/dbscan.html) ).

- minPts:

  number of minimum points in the eps region (for core points). Default
  is 5 points (see
  [`dbscan::dbscan()`](https://rdrr.io/pkg/dbscan/man/dbscan.html) ).

- borderPoints:

  Logical; default to FALSE (see
  [`dbscan::dbscan()`](https://rdrr.io/pkg/dbscan/man/dbscan.html) ).

- maxLag:

  maximum relative temporal lag (see notes). Default to 6.

- minTenure:

  minimum time difference, in hours, between the last and the first
  entry a cluster. Clusters with values smaller than minTenure are
  discarded.

## Note

When maxLag is set to `maxLag>N` output is the same as for
[dbscan](https://rdrr.io/pkg/dbscan/man/dbscan.html).

## Examples

``` r
data(pesa56511)
x = as_tdbscan(pesa56511, time = "locationDate", s_srs = 4326)
#> Error in as_tdbscan(pesa56511, time = "locationDate", s_srs = 4326): unused argument (s_srs = 4326)
x = st_transform(x, '+proj=eqearth')
#> Error in st_transform(x, "+proj=eqearth"): could not find function "st_transform"
z = tdbscan(track=x, eps =6600 , minPts   = 8, maxLag = 6, borderPoints = TRUE )
#> Error: object 'x' not found

# Set minTenure
z = tdbscan(x, eps =6600, minPts   = 8, maxLag = 6, borderPoints = TRUE, minTenure= 24 )
#> Error: object 'x' not found
```
