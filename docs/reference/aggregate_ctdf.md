# Aggregate (merge) adjacent clusters by spatial proximity

Iteratively merges temporally adjacent `cluster` ids whose locations are
within `dist` of each other. This is a repair/aggregation step for an
existing clustering: it does not compute clusters from scratch, it
merges neighbouring ones.

## Usage

``` r
aggregate_ctdf(ctdf, dist)
```

## Arguments

- ctdf:

  A `ctdf` object. Must contain `cluster`, `timestamp`, and `location`.

- dist:

  Aggregation scale in km.

## Value

The input `ctdf`, invisibly, with `cluster` updated in-place.

## Details

Merging is put as a graph problem. An undirected adjacency graph is
constructed with one vertex per `cluster`. An edge is added between two
vertices corresponding to consecutive cluster ids (`cluster` and
`cluster + 1`) if the distance between their geometries is less than
`dist`. clusters are merged by taking connected components of this
graph. The procedure is repeated until no further merges occur.

Representative geometry for each cluster is computed as the centroid of
the convex hull of all points in that cluster.

This updates `cluster` by reference.
