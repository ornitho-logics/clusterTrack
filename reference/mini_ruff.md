# Simulated ARGOS tracking data with 3 spatial clusters

A toy dataset simulating ARGOS satellite tracking data for one
individual. The dataset contains timestamped locations arranged in three
distinct spatial clusters.

## Usage

``` r
mini_ruff
```

## Format

A data.table with 44 rows and 3 columns:

- longitude:

  Numeric. Longitude in decimal degrees (WGS84).

- latitude:

  Numeric. Latitude in decimal degrees (WGS84).

- time:

  POSIXct. Timestamp of location fix (UTC).

## Details

This dataset is fully synthetic and was created to represent idealized
movement within and between three clusters. There is no associated
individual or species.

## Examples

``` r
data(mini_ruff)
plot(mini_ruff$longitude, mini_ruff$latitude, type = "l")
```
