# Summarise geometric elongation of clusters

Computes shape descriptors for each `cluster` in a `ctdf`, based on the
convex hull of its locations and the minimum rotated rectangle enclosing
that hull.

## Usage

``` r
ctdf_elongation(ctdf)
```

## Arguments

- ctdf:

  A `ctdf` object.

## Value

A `data.table` with one row per `cluster`.

## Details

For each cluster, the function computes:

- `convex_hull_area`:

  Area of the cluster convex hull.

- `log_axis_length`:

  Log of the maximum edge length of the minimum rotated rectangle.

- `log_shape_ratio`:

  Log ratio `axis_length^2 / convex_hull_area`.

- `elongation`:

  Product of the standardised values of `axis_length` and
  `log_shape_ratio`. Clusters below average on either component receive
  a score of `0` so only above-average values on both components
  increase the score.

Larger values indicate clusters that are both relatively large in one
principal dimension and relatively elongated for their area.

## References

Chorley, R. J., Malm, D. E. G., & Pogorzelski, H. A. (1957). A new
standard for estimating drainage basin shape. *American Journal of
Science*, 255, 138–141.

## See also

[`summary.ctdf()`](https://ornitho-logics.github.io/clusterTrack/reference/summary.ctdf.md),
[`cluster_track()`](https://ornitho-logics.github.io/clusterTrack/reference/cluster_track.md),
[`sf::st_minimum_rotated_rectangle()`](https://r-spatial.github.io/sf/reference/geos_unary.html)

## Examples

``` r
data(mini_ruff)
x = as_ctdf(mini_ruff)
cluster_track(x)
#> → Find putative cluster regions.
#> ! Repairing[1]...
#> → Local clustering.
#> ! Repairing[2]...
#> ! Compute lof scores...
o = ctdf_elongation(x)
head(o)
#>    cluster axis_length convex_hull_area log_axis_length         log_shape_ratio
#>      <int>       <num>          <units>           <num>                 <units>
#> 1:       1    17706.40   54669211 [m^2]        9.781682 1.746552 [ln(re 1 m-2)]
#> 2:       2    20378.79   98142821 [m^2]        9.922250 1.442566 [ln(re 1 m-2)]
#> 3:       3    23526.12  155042745 [m^2]       10.065867 1.272522 [ln(re 1 m-2)]
#> 4:       4    23615.77  146762134 [m^2]       10.069670 1.335016 [ln(re 1 m-2)]
#>    elongation
#>         <num>
#> 1:          0
#> 2:          0
#> 3:          0
#> 4:          0
```
