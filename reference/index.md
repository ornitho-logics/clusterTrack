# Package index

## Main clustering function

High-level track clustering and post-processing.

- [`cluster_track()`](https://ornitho-logics.github.io/clusterTrack/reference/cluster_track.md)
  : Cluster a movement track into spatiotemporal clusters
- [`aggregate_ctdf()`](https://ornitho-logics.github.io/clusterTrack/reference/aggregate_ctdf.md)
  : Aggregate (merge) adjacent clusters by spatial proximity
- [`summary(`*`<ctdf>`*`)`](https://ornitho-logics.github.io/clusterTrack/reference/summary.ctdf.md)
  : Summarise a ctdf by cluster

## Core data format

Coercion and helpers around the ctdf format.

- [`as_ctdf()`](https://ornitho-logics.github.io/clusterTrack/reference/as_ctdf.md)
  : Coerce an object to clusterTrack data format

- [`as_ctdf(`*`<data.frame>`*`)`](https://ornitho-logics.github.io/clusterTrack/reference/as_ctdf.data.frame.md)
  : Coerce an object to clusterTrack data format

- [`as_ctdf_track()`](https://ornitho-logics.github.io/clusterTrack/reference/as_ctdf_track.md)
  :

  Convert a `ctdf` track to movement step segments as LINESTRINGs

## Pipeline steps

Lower-level steps used by cluster_track().

- [`slice_ctdf()`](https://ornitho-logics.github.io/clusterTrack/reference/slice_ctdf.md)
  : Slice a CTDF into putative clusters using temporal continuity and
  spatial clustering
- [`spatial_repair()`](https://ornitho-logics.github.io/clusterTrack/reference/spatial_repair.md)
  : Repair spatially overlapping adjacent putative clusters
- [`local_cluster_ctdf()`](https://ornitho-logics.github.io/clusterTrack/reference/local_cluster_ctdf.md)
  : Local clustering using DTSCAN
- [`temporal_repair()`](https://ornitho-logics.github.io/clusterTrack/reference/temporal_repair.md)
  : Repair temporally overlapping putative clusters

## Spatial clustering backends

DTSCAN and time-aware DBSCAN.

- [`sf_dtscan()`](https://ornitho-logics.github.io/clusterTrack/reference/sf_dtscan.md)
  : DTSCAN: Delaunay Triangulation-Based Spatial Clustering.
- [`tdbscan()`](https://ornitho-logics.github.io/clusterTrack/reference/tdbscan.md)
  : tdbscan

## Diagnostics and scoring

Within- and between-cluster outlier scoring.

- [`ctdf_lof()`](https://ornitho-logics.github.io/clusterTrack/reference/ctdf_lof.md)
  :

  Compute cluster-wise local outlier factor scores with
  [`dbscan::lof()`](https://rdrr.io/pkg/dbscan/man/lof.html)

- [`ctdf_elongation()`](https://ornitho-logics.github.io/clusterTrack/reference/ctdf_elongation.md)
  : Summarise geometric elongation of clusters

- [`putative_cluster_trace()`](https://ornitho-logics.github.io/clusterTrack/reference/putative_cluster_trace.md)
  : Extract putative-cluster trace

## Datasets

Example datasets shipped with the package.

- [`lbdo66862`](https://ornitho-logics.github.io/clusterTrack/reference/lbdo66862.md)
  : ARGOS satellite tracking data for an individual Long-billed
  dowitcher
- [`mini_ruff`](https://ornitho-logics.github.io/clusterTrack/reference/mini_ruff.md)
  : Reduced ARGOS satellite tracking data for an individual Ruff
- [`pesa56511`](https://ornitho-logics.github.io/clusterTrack/reference/pesa56511.md)
  : ARGOS satellite tracking data for an individual Pectoral Sandpiper
- [`ruff143789`](https://ornitho-logics.github.io/clusterTrack/reference/ruff143789.md)
  : ARGOS satellite tracking data for an individual Ruff
- [`nola125a`](https://ornitho-logics.github.io/clusterTrack/reference/nola125a.md)
  : GNSS tracking data for an individual northern lapwing.
- [`ruff07b5`](https://ornitho-logics.github.io/clusterTrack/reference/ruff07b5.md)
  : GNSS tracking data for an individual ruff.
