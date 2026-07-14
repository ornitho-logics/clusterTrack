test_that("aggregate_ctdf merges nearby consecutive clusters", {
  data(mini_ruff)
  x = as_ctdf(mini_ruff[1:12])
  x[, cluster := rep(1:3, each = 4)]

  out = aggregate_ctdf(x, dist = 10000)

  expect_identical(out, x)
  expect_equal(unique(x$cluster), 1)
})


test_that("aggregate_ctdf leaves distant clusters unchanged", {
  data(mini_ruff)
  x = as_ctdf(mini_ruff[1:12])
  x[, cluster := rep(1:3, each = 4)]

  aggregate_ctdf(x, dist = 0)

  expect_equal(unique(x$cluster), 1:3)
})
