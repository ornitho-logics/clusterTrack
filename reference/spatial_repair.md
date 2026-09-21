# Repair spatially overlapping adjacent putative clusters

Iteratively merges temporally adjacent putative clusters that overlap
spatially. This operates on the `.putative_cluster` column created by
[`slice_ctdf()`](https://ornitho-logics.github.io/clusterTrack/reference/slice_ctdf.md)
and updates it in-place.

## Usage

``` r
spatial_repair(ctdf, time_contiguity = TRUE)
```

## Arguments

- ctdf:

  A `ctdf` object. Must contain `.putative_cluster` (typically produced
  by
  [`slice_ctdf()`](https://ornitho-logics.github.io/clusterTrack/reference/slice_ctdf.md)).

- time_contiguity:

  Logical; if `TRUE`, enforce temporal contiguity within clusters by
  filling internal gaps as described above. Default is `TRUE`.

## Value

The input `ctdf`, invisibly, with `.putative_cluster` updated in-place.

## Details

For each adjacent pair, the locations in each cluster are combined
separately and their convex hulls are tested for intersection. If the
convex hulls do not intersect, a k-nearest-neighbour (kNN) mixing test
is used as a secondary criterion. The kNN test pools the two clusters'
locations, uses `floor(sqrt(n))` neighbours and compares the observed
fraction of neighbours assigned to the other cluster with the expected
mixing fraction under random labels. The pair is considered overlapping
when the observed mixing is at least 60% of that expectation.

If `time_contiguity = TRUE`, missing `.putative_cluster` values between
identical forward- and backward-filled labels are filled, so each
cluster becomes temporally contiguous (short spatial outliers inside a
cluster are absorbed).
