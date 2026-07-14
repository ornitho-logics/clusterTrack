# R/clusterTrack-package.R

#' clusterTrack: Spatiotemporal clustering of animal telemetry tracks
#'
#' `clusterTrack` identifies spatiotemporally distinct use sites from animal
#' telemetry tracks.
#'
#' @section Package options:
#' `clusterTrack` uses the following options:
#'
#' `clusterTrack.verbose`: Logical. Default `TRUE`. Set to `FALSE` to
#' suppress `cli` alerts emitted during package workflows.
#'
#' `clusterTrack.max_gap`: Numeric, in hours. Default `24`. A warning reports
#' adjacent timestamps separated by more than this threshold.
#'
#' ```r
#' options(
#'   clusterTrack.verbose = FALSE,
#'   clusterTrack.max_gap = 24
#' )
#' ```
#'
#' @keywords internal
"_PACKAGE"
