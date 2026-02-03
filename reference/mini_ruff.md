# Reduced ARGOS satellite tracking data for an individual Ruff

`mini_ruff` is a reduced subset of `ruff143789` used in examples and
tests.

## Usage

``` r
mini_ruff
```

## Format

A data.table with 276 rows and 4 columns:

- latitude:

  Numeric. Latitude in decimal degrees (WGS84).

- longitude:

  Numeric. Longitude in decimal degrees (WGS84).

- locationDate:

  POSIXct. Timestamp of location fix (UTC).

- locationClass:

  Character. ARGOS location quality class.

## Source

See `ruff143789`.

## Examples

``` r
data(mini_ruff)
head(mini_ruff)
#>    latitude longitude                time
#>       <num>     <num>              <POSc>
#> 1:   66.751    41.098 2015-05-31 14:33:09
#> 2:   66.741    40.881 2015-05-31 15:12:44
#> 3:   66.670    40.801 2015-05-31 16:41:01
#> 4:   66.665    40.985 2015-05-31 16:50:30
#> 5:   66.427    40.462 2015-05-31 17:43:18
#> 6:   66.485    40.456 2015-05-31 18:20:13
```
