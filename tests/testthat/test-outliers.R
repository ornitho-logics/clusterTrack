test_that("ctdf_lof scores clustered points only", {
  data(mini_ruff)
  x = as_ctdf(mini_ruff[1:20])
  x[, cluster := c(rep(0, 5), rep(1, 15))]

  out = ctdf_lof(x, minPts = 3)

  expect_identical(out, x)
  expect_true(all(is.na(x[cluster == 0]$lof)))
  expect_true(all(is.finite(x[cluster == 1]$lof)))
})
