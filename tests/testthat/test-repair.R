test_that("temporal_repair merges clusters with overlapping time domains", {
  data(mini_ruff)
  x = as_ctdf(mini_ruff[1:16])
  x[, .putative_cluster := c(rep(c(1, 2), 6), rep(3, 4))]

  out = temporal_repair(x, trim = 0)

  expect_identical(out, x)
  expect_equal(unique(x$.putative_cluster), 1:2)
  expect_equal(x$.putative_cluster, c(rep(1, 12), rep(2, 4)))
})


test_that("spatial_repair fills internal gaps when requested", {
  data(mini_ruff)
  x = as_ctdf(mini_ruff[1:12])
  x[, .putative_cluster := c(rep(1, 5), NA, rep(1, 6))]

  spatial_repair(x, time_contiguity = TRUE)

  expect_false(anyNA(x$.putative_cluster))
  expect_equal(unique(x$.putative_cluster), 1)
})
