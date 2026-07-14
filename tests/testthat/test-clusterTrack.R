test_that("cluster_track works using defaults", {
  data(mini_ruff)
  x = as_ctdf(mini_ruff, s_srs = 4326, t_srs = "+proj=eqearth")
  out = cluster_track(x)

  expect_s3_class(x, "ctdf")
  expect_identical(out, x)
  expect_equal(sort(unique(x$cluster)), 0:4)
  expect_equal(x[, .N, cluster]$N, c(51, 12, 58, 68, 87))
  expect_true(all(is.na(x[cluster == 0]$lof)))
  expect_true(all(is.finite(x[cluster > 0]$lof)))
})


test_that("cluster_track stores the parameters used", {
  data(mini_ruff)
  x = as_ctdf(mini_ruff)

  cluster_track(
    x,
    nmin = 4,
    z_min = 0.5,
    trim = 0.1,
    minCluster = 4,
    deltaT = 2,
    aggregate_dist = 0
  )

  params = attr(x, "cluster_params")

  expect_equal(
    params,
    list(
      nmin = 4,
      minCluster = 4,
      z_min = 0.5,
      trim = 0.1,
      deltaT = 2,
      aggregate_dist = 0
    )
  )
})


test_that("cluster_track restores data.table progress option", {
  data(mini_ruff)
  x = as_ctdf(mini_ruff)

  old_options = options(datatable.showProgress = TRUE)
  on.exit(options(old_options), add = TRUE)

  cluster_track(x)

  expect_true(getOption("datatable.showProgress"))
})
