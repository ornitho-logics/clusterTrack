# Validate the structure of a ctdf object

Checks the class, required columns, column lengths, timestamp ordering,
point geometry, identifiers, and storage types expected by clusterTrack.

## Usage

``` r
validate_ctdf(x)
```

## Arguments

- x:

  An object to validate as a `ctdf`.

## Value

The input `x`, invisibly, if validation succeeds.

## Details

This is a low-level development utility intended primarily for packages
that extend clusterTrack. Objects used through the normal clusterTrack
workflow are validated internally, so most users do not need to call it
directly.
