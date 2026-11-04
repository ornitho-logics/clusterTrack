# Deprecated clusterTrack functions

`as_tdbscan()` and `tdbscan()` are deprecated. Use
[`as_ctdf()`](https://ornitho-logics.github.io/clusterTrack/reference/as_ctdf.md)
and
[`cluster_track()`](https://ornitho-logics.github.io/clusterTrack/reference/cluster_track.md)
instead.

## Usage

``` r
as_tdbscan(x, coords = c("longitude", "latitude"), time = "time", crs = 4326)

tdbscan(track, eps, minPts = 5, borderPoints = FALSE, maxLag = 6, minTenure)
```

## Arguments

- x:

  A `data.frame` or `data.table` containing coordinates and a time
  column.

- coords:

  Character vector of length 2 giving coordinate column names.

- time:

  Name of the time column.

- crs:

  Coordinate reference system passed to
  [`sf::st_as_sf()`](https://r-spatial.github.io/sf/reference/st_as_sf.html).

- track:

  An `sf` object ordered by time.

- eps:

  Size of the epsilon neighborhood; see
  [`dbscan::dbscan()`](https://michael.hahsler.net/dbscan/reference/dbscan.html).

- minPts:

  Minimum number of points in an epsilon neighborhood.

- borderPoints:

  Logical; whether to include border points.

- maxLag:

  Maximum separation in row indices between connected points.

- minTenure:

  Optional minimum cluster duration, in hours.

## Value

`as_tdbscan()` returns an `sf` object with a `timestamp` column.
`tdbscan()` returns `track` with an integer `clustID` column; unassigned
locations have `NA` cluster IDs.

## Note

`tdbscan()` was used in Kempenaers, B., Valcu, M., Piersma, T., Santema,
P. and Vervoort, R. (2025). Large-scale sampling of potential breeding
sites in male ruffs. *Proceedings of the Royal Society B: Biological
Sciences*, **292**(2038), 20242225.

## Examples

``` r
data(pesa56511)
x = as_tdbscan(pesa56511, time = "locationDate")
#> Warning: 'as_tdbscan' is deprecated.
#> Use 'as_ctdf' instead.
#> See help("Deprecated") and help("clusterTrack-deprecated").
x = sf::st_transform(x, "+proj=eqearth")
z = tdbscan(track = x, eps = 6600, minPts = 8, maxLag = 6)
#> Warning: 'tdbscan' is deprecated.
#> Use 'cluster_track' instead.
#> See help("Deprecated") and help("clusterTrack-deprecated").
table(z$clustID)
#> 
#>   1   2   3   4   5   6 
#>  67  60  17  33 128 454 
```
