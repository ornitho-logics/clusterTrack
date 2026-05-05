test_that("cluster_track does not store trace by default", {
  data(mini_ruff)

  x = as_ctdf(mini_ruff)
  cluster_track(x)

  expect_null(putative_cluster_trace(x))
  expect_false("putative_cluster_trace" %in% names(x))
})

test_that("cluster_track stores wide putative cluster trace", {
  data(mini_ruff)

  x = as_ctdf(mini_ruff)
  cluster_track(x, trace = TRUE)

  tr = putative_cluster_trace(x)

  expect_s3_class(tr, "data.table")
  expect_equal(nrow(tr), nrow(x))
  expect_equal(ncol(tr), 8)
  expect_equal(tr[[1]], x$.id)
  expect_equal(tr[[ncol(tr)]], x$.putative_cluster)
  expect_false("putative_cluster_trace" %in% names(x))
})
