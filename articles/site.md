# Map gallery

Once you have exported a bunch of interactive map HTML files with
`map(ctdf, path = ...)`, you can call
[`site()`](https://rdrr.io/pkg/clusterTrack.Vis/man/site.html) to create
a simple browsable index for that folder.

[`site()`](https://rdrr.io/pkg/clusterTrack.Vis/man/site.html) copies a
Quarto `index.qmd` template into the same directory as your saved map
`.html` files. Render that `index.qmd` to produce an `index.html` that
links to the maps.

### Use site()

``` r
require(clusterTrack )
require(clusterTrack.Vis)

out_path = "path/to/empty/dir"
```

Export many maps (use whatever loop/apply/parallel approach you prefer)

``` r
map(x1, path = out_path)
map(x2, path = out_path)
...
map(xn, path = out_path)
```

Copy the Quarto index template into `out_path`

``` r
site(out_path)
```

Then render `out_path/index.qmd` to get `out_path/index.html`
