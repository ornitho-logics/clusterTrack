# DTSCAN: Delaunay Triangulation-Based Spatial Clustering.

Runs a clustering using a Delaunay triangulation of point coordinates.

## Usage

``` r
sf_dtscan(x, min_pts = 5, area_z_min = -1, length_z_min = -1, id_col = NULL)
```

## Arguments

- x:

  An `sf` object with POINT geometry.

- min_pts:

  Minimum neighbour count for a point to be treated as a core point.
  Neighbours are the sites directly connected by kept Delaunay edges
  after pruning. If multiple input points share exactly the same
  coordinates, they are collapsed to one site and their multiplicity
  contributes to this count.

- area_z_min:

  Threshold (in SD units) on the inverse z-score of triangle areas used
  for pruning. Larger thresholds keep only progressively
  smaller-than-average triangles and prune more edges. Default to 0.

- length_z_min:

  Threshold (in SD units) on the inverse z-score of Delaunay edge
  lengths used for pruning. Larger thresholds keep only progressively
  shorter-than-average edges and prune more connections.

- id_col:

  Optional character scalar naming a unique identifier column in `x`
  used to align output. If `NULL` or missing from `x`, output is aligned
  by current row order.

## Value

An integer vector of cluster labels of length `nrow(x)`. `0` indicates
noise/unassigned; positive integers are cluster ids.

## Details

Identical coordinates are collapsed before triangulation; their
multiplicity contributes to MinPts via
`effective_degree = degree + (mult - 1)`. Cluster labels are produced by
starting a new cluster at each unassigned core site (a site meeting the
MinPts rule) and iteratively visiting all sites reachable through pruned
Delaunay edges from that seed; the cluster id is assigned to every
visited site.

## References

Kim, J., & Cho, J. (2019). Delaunay triangulation-based spatial
clustering technique for enhanced adjacent boundary detection and
segmentation of LiDAR 3D point clouds. Sensors, 19(18), 3926.
doi:10.3390/s19183926

## Examples

``` r
data(moons)
#> Warning: data set ‘moons’ not found
m = st_as_sf(moons, coords = c("X", "Y"))
#> Error: object 'moons' not found
m$cluster = sf_dtscan(m)
#> Error: object 'm' not found
hullplot(moons, m$cluster)
#> Error: object 'moons' not found
```
