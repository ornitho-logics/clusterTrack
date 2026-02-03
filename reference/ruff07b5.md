# GNSS tracking data for an individual ruff.

A dataset containing GNSS locations for an individual male ruff.

## Usage

``` r
ruff07b5
```

## Format

A data.table with 2772 rows and 3 columns:

- timestamp:

  POSIXct. Timestamp of location fix (UTC).

- latitude:

  Numeric. Latitude in decimal degrees (WGS84).

- longitude:

  Numeric. Longitude in decimal degrees (WGS84).

## Source

Unpublished data.

## Examples

``` r
data(ruff07b5)
head(ruff07b5)
#>              timestamp latitude longitude
#>                 <POSc>    <num>     <num>
#> 1: 2023-11-21 15:00:00 37.14421 -8.615738
#> 2: 2023-11-21 14:30:00 37.14402 -8.615566
#> 3: 2023-11-05 16:00:00 37.14416 -8.615699
#> 4: 2023-11-05 15:00:00 37.14331 -8.615194
#> 5: 2023-11-05 12:00:00 37.14389 -8.615477
#> 6: 2023-11-03 16:00:00 37.14394 -8.615429
```
