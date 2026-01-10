test_that("dtscan returns the right clustering on a simple dataset", {
  data(mini_ruff)

  x = as_ctdf(mini_ruff)[.id %in% 90:177]
  cl = sf_dtscan(
    st_as_sf(x),
    id_col = ".id",
    min_pts = 5,
    area_z_min = 0,
    length_z_min = 0
  )

  testthat::expect_equal(nrow(x), length(cl))

  testthat::expect_contains(cl, 0L)

  testthat::expect_length(unique(cl), 3)
})
