# Slice a CTDF into putative clusters using temporal continuity and spatial clustering

Identifies spatially heterogeneous regions (via HDBSCAN on point
coordinates) and, for those regions, recursively subdivides the track
into temporally continuous movement segments. Subdivision continues
until a region is spatially homogeneous (no evidence for multiple
clusters) .

## Usage

``` r
slice_ctdf(ctdf, nmin = 5, deltaT)
```

## Arguments

- ctdf:

  A *CTDF* object.

- nmin:

  Integer; smallest size of a putative cluster.

- deltaT:

  Numeric; maximum allowable time gap (in days) between segment
  endpoints for intersections to consider them continuous.

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
#>  ⠙ 13 segments processed [2s]
#>  ⠹ 17 segments processed [2.2s]
#>  ⠸ 20 segments processed [2.4s]
#>  ⠼ 28 segments processed [2.6s]
#>  ⠴ 32 segments processed [2.8s]
#>  ⠦ 34 segments processed [3s]
#>  ⠧ 37 segments processed [3.2s]
#>  ⠇ 43 segments processed [3.4s]
#>  ⠇ 46 segments processed [3.6s]
```
