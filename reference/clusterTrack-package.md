# clusterTrack: Spatiotemporal clustering of animal telemetry tracks

`clusterTrack` identifies spatiotemporally distinct use sites from
animal telemetry tracks.

## Package options

`clusterTrack` uses the following options:

`clusterTrack.verbose`: Logical. Default `TRUE`. Set to `FALSE` to
suppress `cli` alerts emitted during package workflows.

`clusterTrack.max_gap`: Numeric, in hours. Default `24`. A warning
reports adjacent timestamps separated by more than this threshold.

    options(
      clusterTrack.verbose = FALSE,
      clusterTrack.max_gap = 24
    )

## See also

Useful links:

- <https://ornitho-logics.github.io/clusterTrack/>

- Report bugs at <https://github.com/ornitho-logics/clusterTrack/issues>

## Author

**Maintainer**: Mihai Valcu <mvalcu@gwdg.de>
([ORCID](https://orcid.org/0000-0002-6907-7802))

Authors:

- Mihai Valcu <mvalcu@gwdg.de>
  ([ORCID](https://orcid.org/0000-0002-6907-7802))
