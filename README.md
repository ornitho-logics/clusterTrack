

`clusterTrack` identifies spatiotemporally distinct use sites from animal telemetry tracks.

The package is designed for relocation data where animals alternate between local site use and movement, often with irregular sampling, location error, and repeated returns to the same places. It combines temporal track segmentation, local spatial clustering, and iterative repair procedures to identify and label use sites.

`clusterTrack` works with both lower-precision telemetry data such as ARGOS and high-resolution GNSS tracks.


## Installation

You can download `clusterTrack` from  https://anonymous.4open.science/r/clusterTrack-MEE   

and optionally `clusterTrack.Vis`   from https://anonymous.4open.science/r/clusterTrackVis-MEE

Once downloaded, install packages with: 


``` r

setwd('your/download/dir')
remotes::install_local("clusterTrack-MEE.zip")
remotes::install_local("clusterTrackVis-MEE.zip")


```
