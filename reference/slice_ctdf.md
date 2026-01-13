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
#>  ⠙ 17 segments processed [2.1s]
#>  ⠹ 19 segments processed [2.3s]
#>  ⠸ 22 segments processed [2.4s]
#>  ⠼ 27 segments processed [2.6s]
#>  ⠴ 35 segments processed [2.9s]
#>  ⠦ 40 segments processed [3.1s]
#>  ⠧ 44 segments processed [3.2s]
#>  ⠇ 51 segments processed [3.5s]
#>  ⠏ 56 segments processed [3.7s]
#>  ⠋ 59 segments processed [3.9s]
#>  ⠙ 64 segments processed [4.1s]
#>  ⠹ 72 segments processed [4.3s]
#>  ⠸ 77 segments processed [4.4s]
#>  ⠼ 89 segments processed [4.7s]
#>  ⠼ 90 segments processed [4.7s]
```
