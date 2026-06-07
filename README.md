
clusterTrack <a href="https://ornitho-logics.github.io/clusterTrack/"><img src="man/figures/logo.png" align="right" height="139" alt="clusterTrack website" /></a>

[![pkgdown](https://github.com/ornitho-logics/clusterTrack/actions/workflows/pkgdown.yaml/badge.svg?branch=main)](https://github.com/ornitho-logics/clusterTrack/actions/workflows/pkgdown.yaml)
[![GitHub version](https://img.shields.io/github/r-package/v/ornitho-logics/clusterTrack?label=version)](https://github.com/ornitho-logics/clusterTrack)
[![License: GPL >= 2](https://img.shields.io/badge/license-GPL%20%3E%3D%202-blue.svg)](https://www.gnu.org/licenses/old-licenses/gpl-2.0)
[![GitHub last commit](https://img.shields.io/github/last-commit/ornitho-logics/clusterTrack)](https://github.com/ornitho-logics/clusterTrack/commits/main)


`clusterTrack` identifies spatiotemporally distinct use sites from animal telemetry tracks.

The package is designed for relocation data where animals alternate between local site use and movement, often with irregular sampling, location error, and repeated returns to the same places. It combines temporal track segmentation, local spatial clustering, and iterative repair procedures to identify and label use sites.

`clusterTrack` works with both lower-precision telemetry data such as ARGOS and high-resolution GNSS tracks.


See also [`clusterTrack.Vis`](https://github.com/ornitho-logics/clusterTrack.Vis), the extension package for `clusterTrack`.

## Installation

You can install the development versions from GitHub with:

``` r
remotes::install_github('ornitho-logics/clusterTrack')
remotes::install_github('ornitho-logics/clusterTrack.Vis')
```
