# Repair temporally overlapping putative clusters

Merges `.putative_cluster` labels whose (trimmed) time domains overlap.
For each putative cluster, a time interval `[lo, hi]` is estimated from
the `timestamp` distribution after trimming a small fraction from each
tail to reduce sensitivity to single-point temporal outliers. Any
clusters with overlapping intervals are merged (transitively) using
connected components on an overlap graph.

## Usage

``` r
temporal_repair(ctdf, trim = 0.01)
```

## Arguments

- ctdf:

  A `ctdf` object. Must contain `timestamp` and `.putative_cluster`.

- trim:

  Numeric in `[0, 0.5)`. Maximum fraction trimmed from each tail when
  estimating each cluster's time domain. The effective trim per cluster
  is `min(trim, 1 / n_i)` where `n_i` is the number of points in that
  cluster.

## Value

The input `ctdf`, invisibly, with `.putative_cluster` updated in-place.

## Details

Clusters are merged using connected components of an *interval overlap
graph*: an undirected graph with one vertex per `.putative_cluster`, and
an edge between two vertices if their trimmed time intervals overlap.
