# Coerce a track-like table to an sf object for tdbscan

A small convenience helper that renames a time column to `timestamp`,
orders by time, and converts coordinates to an `sf` point geometry.

## Usage

``` r
as_tdbscan(x, coords = c("longitude", "latitude"), time = "time", crs = 4326)
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

## Value

An `sf` object with a `timestamp` column.
