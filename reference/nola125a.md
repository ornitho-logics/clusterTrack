# GNSS tracking data for an individual northern lapwing.

A dataset containing GNSS locations for an individual female northern
lapwing.

## Usage

``` r
nola125a
```

## Format

A data.table with 2484 rows and 3 columns:

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
data(nola125a)
head(nola125a)
#>              timestamp latitude longitude
#>                 <POSc>    <num>     <num>
#> 1: 2025-07-31 23:00:00 52.60784  6.100084
#> 2: 2025-07-31 22:00:00 52.60831  6.100772
#> 3: 2025-07-31 21:00:00 52.60833  6.100711
#> 4: 2025-07-31 20:00:00 52.60924  6.097118
#> 5: 2025-07-31 19:00:00 52.60918  6.097602
#> 6: 2025-07-31 18:00:00 52.60542  6.091116
```
