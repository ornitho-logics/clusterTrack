clusterTrack [![clusterTrack
website](reference/figures/logo.png)](https://ornitho-logics.github.io/clusterTrack/)

`clusterTrack` identifies spatiotemporally distinct use sites from
animal telemetry tracks.

The package is designed for relocation data in which animals alternate
between local site use and movement, often under irregular sampling,
location error, and repeated revisits to the same places. It combines
temporal segmentation of the track, local spatial clustering, and
iterative repair steps to recover use sites while limiting
over-fragmentation.

The package works with both lower-precision telemetry data such as ARGOS
and high-resolution GNSS tracks.

## Main idea

`clusterTrack` follows a multi-step workflow:

1.  **Segmentation**  
    The track is recursively split into temporally ordered candidate
    regions when there is evidence for spatial heterogeneity.

2.  **Local clustering**  
    Within each candidate region, local spatial clusters are detected
    using a Delaunay triangulation-based clustering method implemented
    in
    [`sf_dtscan()`](https://ornitho-logics.github.io/clusterTrack/reference/sf_dtscan.md).

3.  **Repair**  
    Spatially overlapping adjacent regions are merged, temporally
    overlapping clusters are reconciled.

The final output is a set of temporally indexed spatial clusters stored
directly in the input object.

## Installation

You can install the development version from GitHub with:

``` r
remotes::install_github('ornitho-logics/clusterTrack')
remotes::install_github('ornitho-logics/clusterTrack.Vis')
```
