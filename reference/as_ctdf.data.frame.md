# Coerce an object to clusterTrack data format

Converts an object with spatial coordinates and a timestamp column to a
standardized `sf/data.table`-based format used by the clusterTrack
package.

## Usage

``` r
# S3 method for class 'data.frame'
as_ctdf(
  x,
  coords = c("longitude", "latitude"),
  time = "time",
  s_srs = 4326,
  t_srs = "+proj=eqearth",
  ...
)
```

## Arguments

- x:

  A `data.frame` object.

- coords:

  Character vector of length 2 specifying the coordinate column names.
  Defaults to `c("longitude", "latitude")`.

- time:

  Name of the time column. Will be renamed to `"timestamp"` internally.

- s_srs:

  Source spatial reference. Default is EPSG:4326

- t_srs:

  target spatial reference passed to `st_transform()`. Default is
  "+proj=eqearth".

- ...:

  Currently unused

## Value

An object of class `ctdf` (inherits from `sf`, `data.table`).

## Note

This is currently a thin wrapper around `st_as_sf()`, but standardizes
timestamp naming, ordering, and geometry column name (`"location"`).
Several dot columns,updated by upstream methods, are added as well.

## Examples

``` r
data(mini_ruff)
x = as_ctdf(mini_ruff)
plot(x)

```
