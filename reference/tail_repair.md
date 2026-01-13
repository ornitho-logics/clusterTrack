# Repair putative clusters by trimming track tails

Removes leading and trailing "tail" portions of each `.putative_cluster`
based on self-crossings of the within-cluster track. The intent is to
keep only the locally revisited core of a cluster and drop commuting
legs at the both beginning and end.

## Usage

``` r
tail_repair(ctdf)
```

## Arguments

- ctdf:

  A `ctdf` object. Must contain `.id`, `timestamp`, `location`, and
  `.putative_cluster`.

## Value

The input `ctdf`, invisibly, with `.putative_cluster` updated in-place.

## Details

If the track has any self-crossing steps, the kept "core" is defined as
the contiguous block of steps between the first and last crossing; all
points outside this block are set to `NA` in `.putative_cluster`. If a
cluster has no self-crossings at all, the entire cluster is dropped (all
its points are set to `NA`).
