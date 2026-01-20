# Slice a CTDF into putative clusters using temporal continuity and spatial clustering

Identifies spatially heterogeneous regions (via HDBSCAN on point
coordinates) and, for those regions, recursively subdivides the track
into temporally continuous movement segments. Subdivision continues
until a region is spatially homogeneous (no evidence for multiple
clusters) .

## Usage

``` r
slice_ctdf(ctdf, deltaT = 30, nmin = 5)
```

## Arguments

- ctdf:

  A *CTDF* object.

- deltaT:

  Numeric; maximum allowable time gap (in days) between segment
  endpoints for intersections to consider them continuous.

- nmin:

  Integer; the `minPts` parameter passed to
  [`dbscan::hdbscan()`](https://rdrr.io/pkg/dbscan/man/hdbscan.html).

## Value

Invisibly returns `ctdf`, with `.putative_cluster` updated in-place.

## Details

This function updates a `ctdf` in-place.

Internally, candidate regions are queued. Regions that show evidence for
multiple clusters are split by movement segmentation; otherwise they are
retained as a single putative cluster.

## See also

[`hdbscan`](https://rdrr.io/pkg/dbscan/man/hdbscan.html)

## Examples

``` r
data(mini_ruff)
ctdf = as_ctdf(mini_ruff, s_srs = 4326, t_srs = "+proj=eqearth")
ctdf = slice_ctdf(ctdf)

data(pesa56511)
ctdf = as_ctdf(pesa56511, time = "locationDate", s_srs = 4326, t_srs = "+proj=eqearth")
ctdf = slice_ctdf(ctdf)
#> 
 ⠙ 13 segments processed [2.1s]

#> 
 ⠹ 15 segments processed [2.2s]

#> 
 ⠸ 18 segments processed [2.4s]

#> 
 ⠼ 20 segments processed [2.6s]

#> 
 ⠴ 25 segments processed [2.8s]

#> 
 ⠦ 29 segments processed [3s]

#> 
 ⠧ 37 segments processed [3.2s]

#> 
 ⠇ 44 segments processed [3.5s]

#> 
 ⠏ 48 segments processed [3.6s]

#> 
 ⠋ 54 segments processed [3.8s]

#> 
 ⠙ 58 segments processed [4s]

#> 
 ⠹ 63 segments processed [4.2s]

#> 
 ⠸ 69 segments processed [4.4s]

#> 
 ⠼ 74 segments processed [4.6s]

#> 
 ⠴ 88 segments processed [4.8s]

#> 
 ⠴ 90 segments processed [5s]

#> 
```
