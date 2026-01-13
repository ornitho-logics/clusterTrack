# DTSCAN: Delaunay Triangulation-Based Spatial Clustering.

Runs a DTSCAN-style clustering pipeline using a Delaunay triangulation
of point coordinates, global pruning based on z-scored triangle areas
and edge lengths, and MinPts graph expansion. Returns only the cluster
labels vector aligned to the input rows.

## Usage

``` r
sf_dtscan(x, min_pts = 5, area_z_min = 0, length_z_min = 0, id_col = NULL)
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
data(mini_ruff)
x = as_ctdf(mini_ruff)[.id %in% 90:177]
x[,
  cluster := sf_dtscan(
    st_as_sf(x),
    id_col = ".id",
    min_pts = 5,
    area_z_min = 0,
    length_z_min = 0
  )
]
#> Key: <.id>
#>               timestamp                location cluster   .id .move_seg .seg_id .putative_cluster
#>                  <POSc>             <sfc_POINT>   <num> <int>     <int>   <int>             <int>
#>  1: 2015-06-03 05:52:40 POINT (2964089 7430839)       0    90        NA      NA                NA
#>  2: 2015-06-03 06:21:09 POINT (2951938 7424552)       0    91        NA      NA                NA
#>  3: 2015-06-03 06:43:28 POINT (2956733 7422033)       0    92        NA      NA                NA
#>  4: 2015-06-03 07:00:02 POINT (2966187 7416690)       0    93        NA      NA                NA
#>  5: 2015-06-03 07:28:53 POINT (2980797 7417730)       0    94        NA      NA                NA
#>  6: 2015-06-03 08:03:23 POINT (2983278 7423811)       0    95        NA      NA                NA
#>  7: 2015-06-03 08:25:35 POINT (2970302 7418176)       0    96        NA      NA                NA
#>  8: 2015-06-03 08:40:46 POINT (2969657 7422552)       0    97        NA      NA                NA
#>  9: 2015-06-03 09:10:15 POINT (2965091 7422774)       0    98        NA      NA                NA
#> 10: 2015-06-03 09:44:04 POINT (2986953 7412527)       0    99        NA      NA                NA
#> 11: 2015-06-03 10:23:05 POINT (2971327 7416244)       0   100        NA      NA                NA
#> 12: 2015-06-03 10:56:11 POINT (2977182 7411411)       0   101        NA      NA                NA
#> 13: 2015-06-03 11:21:12 POINT (2952177 7424626)       0   102        NA      NA                NA
#> 14: 2015-06-03 11:37:00 POINT (2948262 7426033)       0   103        NA      NA                NA
#> 15: 2015-06-03 13:01:29 POINT (2950085 7430987)       0   104        NA      NA                NA
#> 16: 2015-06-03 13:18:38 POINT (2938722 7430174)       1   105        NA      NA                NA
#> 17: 2015-06-03 14:10:16 POINT (2944870 7426847)       0   106        NA      NA                NA
#> 18: 2015-06-03 14:42:37 POINT (2941471 7430396)       1   107        NA      NA                NA
#> 19: 2015-06-03 14:57:54 POINT (2941413 7430692)       1   108        NA      NA                NA
#> 20: 2015-06-03 15:07:35 POINT (2940221 7430470)       1   109        NA      NA                NA
#> 21: 2015-06-03 15:46:11 POINT (2940435 7429805)       1   110        NA      NA                NA
#> 22: 2015-06-03 16:46:34 POINT (2940133 7429879)       1   111        NA      NA                NA
#> 23: 2015-06-03 16:47:52 POINT (2938466 7430618)       1   112        NA      NA                NA
#> 24: 2015-06-03 17:28:16 POINT (2938264 7429657)       1   113        NA      NA                NA
#> 25: 2015-06-03 18:27:26 POINT (2936822 7430027)       1   114        NA      NA                NA
#> 26: 2015-06-03 19:09:24 POINT (2939893 7430766)       1   115        NA      NA                NA
#> 27: 2015-06-03 20:05:56 POINT (2940986 7431061)       1   116        NA      NA                NA
#> 28: 2015-06-03 22:29:17 POINT (2938592 7430323)       1   117        NA      NA                NA
#> 29: 2015-06-03 23:22:37 POINT (2939237 7430396)       1   118        NA      NA                NA
#> 30: 2015-06-04 00:14:01 POINT (2940955 7430174)       1   119        NA      NA                NA
#> 31: 2015-06-04 00:59:20 POINT (2940643 7429953)       1   120        NA      NA                NA
#> 32: 2015-06-04 01:49:05 POINT (2941168 7430470)       1   121        NA      NA                NA
#> 33: 2015-06-04 02:41:08 POINT (2941429 7430174)       1   122        NA      NA                NA
#> 34: 2015-06-04 02:51:28 POINT (2933318 7430470)       0   123        NA      NA                NA
#> 35: 2015-06-04 02:57:59 POINT (2942434 7429879)       1   124        NA      NA                NA
#> 36: 2015-06-04 03:31:36 POINT (2935229 7426107)       0   125        NA      NA                NA
#> 37: 2015-06-04 04:31:25 POINT (2943713 7427661)       0   126        NA      NA                NA
#> 38: 2015-06-04 04:40:01 POINT (2942024 7428770)       1   127        NA      NA                NA
#> 39: 2015-06-04 06:11:26 POINT (2936937 7425589)       0   128        NA      NA                NA
#> 40: 2015-06-04 06:17:35 POINT (2937477 7430396)       1   129        NA      NA                NA
#> 41: 2015-06-04 06:54:19 POINT (2939876 7425367)       0   130        NA      NA                NA
#> 42: 2015-06-04 07:08:35 POINT (2941626 7430987)       1   131        NA      NA                NA
#> 43: 2015-06-04 08:06:04 POINT (2942897 7430544)       1   132        NA      NA                NA
#> 44: 2015-06-04 08:29:25 POINT (2942690 7429436)       1   133        NA      NA                NA
#> 45: 2015-06-04 08:48:12 POINT (2946897 7429731)       2   134        NA      NA                NA
#> 46: 2015-06-04 09:33:10 POINT (2946645 7430323)       2   135        NA      NA                NA
#> 47: 2015-06-04 09:47:41 POINT (2945766 7430323)       2   136        NA      NA                NA
#> 48: 2015-06-04 10:11:29 POINT (2944473 7431135)       2   137        NA      NA                NA
#> 49: 2015-06-04 10:29:10 POINT (2945894 7431135)       2   138        NA      NA                NA
#> 50: 2015-06-04 11:12:58 POINT (2939435 7430249)       1   139        NA      NA                NA
#> 51: 2015-06-04 11:14:24 POINT (2940571 7428844)       1   140        NA      NA                NA
#> 52: 2015-06-04 11:56:26 POINT (2942401 7431874)       1   141        NA      NA                NA
#> 53: 2015-06-04 12:47:29 POINT (2959409 7434826)       0   142        NA      NA                NA
#> 54: 2015-06-04 12:53:34 POINT (2946477 7431357)       0   143        NA      NA                NA
#> 55: 2015-06-04 13:49:21 POINT (2944171 7431209)       1   144        NA      NA                NA
#> 56: 2015-06-04 14:30:53 POINT (2945511 7429805)       2   145        NA      NA                NA
#> 57: 2015-06-04 15:26:58 POINT (2945983 7427735)       0   146        NA      NA                NA
#> 58: 2015-06-04 16:15:19 POINT (2946127 7428992)       2   147        NA      NA                NA
#> 59: 2015-06-04 17:04:32 POINT (2937739 7429140)       1   148        NA      NA                NA
#> 60: 2015-06-04 17:55:06 POINT (2939268 7431283)       1   149        NA      NA                NA
#> 61: 2015-06-04 18:00:31 POINT (2939429 7431061)       1   150        NA      NA                NA
#> 62: 2015-06-04 18:47:09 POINT (2938034 7431800)       1   151        NA      NA                NA
#> 63: 2015-06-04 19:34:54 POINT (2936587 7432021)       1   152        NA      NA                NA
#> 64: 2015-06-04 21:14:28 POINT (2934671 7433350)       0   153        NA      NA                NA
#> 65: 2015-06-04 23:59:43 POINT (2940871 7431652)       1   154        NA      NA                NA
#> 66: 2015-06-05 00:27:49 POINT (2941928 7430913)       1   155        NA      NA                NA
#> 67: 2015-06-05 01:39:43 POINT (2939647 7431504)       1   156        NA      NA                NA
#> 68: 2015-06-05 02:06:57 POINT (2939597 7430027)       1   157        NA      NA                NA
#> 69: 2015-06-05 02:33:41 POINT (2940512 7431061)       1   158        NA      NA                NA
#> 70: 2015-06-05 02:40:05 POINT (2940444 7431061)       1   159        NA      NA                NA
#> 71: 2015-06-05 03:22:03 POINT (2940392 7431504)       1   160        NA      NA                NA
#> 72: 2015-06-05 04:13:55 POINT (2955247 7424256)       0   161        NA      NA                NA
#> 73: 2015-06-05 04:21:03 POINT (2939602 7430174)       1   162        NA      NA                NA
#> 74: 2015-06-05 05:53:58 POINT (2953218 7434752)       0   163        NA      NA                NA
#> 75: 2015-06-05 06:00:05 POINT (2949897 7426329)       0   164        NA      NA                NA
#> 76: 2015-06-05 06:49:08 POINT (2942660 7428548)       1   165        NA      NA                NA
#> 77: 2015-06-05 07:30:57 POINT (2933021 7433572)       0   166        NA      NA                NA
#> 78: 2015-06-05 07:40:29 POINT (2942324 7430618)       1   167        NA      NA                NA
#> 79: 2015-06-05 08:19:00 POINT (2942924 7429362)       1   168        NA      NA                NA
#> 80: 2015-06-05 08:28:16 POINT (2941206 7429583)       1   169        NA      NA                NA
#> 81: 2015-06-05 10:00:24 POINT (2928668 7429140)       0   170        NA      NA                NA
#> 82: 2015-06-05 10:09:30 POINT (2939064 7432243)       1   171        NA      NA                NA
#> 83: 2015-06-05 10:49:50 POINT (2935800 7432760)       0   172        NA      NA                NA
#> 84: 2015-06-05 11:00:25 POINT (2931116 7430396)       0   173        NA      NA                NA
#> 85: 2015-06-05 11:40:06 POINT (2950658 7430913)       0   174        NA      NA                NA
#> 86: 2015-06-05 11:49:18 POINT (2946378 7428401)       2   175        NA      NA                NA
#> 87: 2015-06-05 12:26:39 POINT (2946812 7433276)       0   176        NA      NA                NA
#> 88: 2015-06-05 12:40:33 POINT (2954952 7427661)       0   177        NA      NA                NA
#>               timestamp                location cluster   .id .move_seg .seg_id .putative_cluster
#>                  <POSc>             <sfc_POINT>   <num> <int>     <int>   <int>             <int>
```
