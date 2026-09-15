test_that("cluster_track does not store trace by default", {
  data(mini_ruff)

  x <- as_ctdf(mini_ruff)
  cluster_track(x)

  expect_null(putative_cluster_trace(x))
  expect_null(attr(x, "putative_cluster_trace", exact = TRUE))

  for (column in ctdf_internal_cols) {
    expect_true(all(is.na(x[[column]])))
  }
})


test_that("cluster_track stores wide putative cluster trace", {
  data(mini_ruff)

  x <- as_ctdf(mini_ruff)
  cluster_track(x, trace = TRUE)

  tr <- putative_cluster_trace(x)

  expect_s3_class(tr, "data.table")
  expect_equal(nrow(tr), nrow(x))

  expect_named(
    tr,
    c(
      ".id",
      "slice",
      "spatial_repair_1",
      "dtscan",
      "spatial_repair_2",
      "subset_by_minCluster",
      "drop_false_cluster",
      "temporal_repair"
    )
  )

  expect_identical(tr$.id, x$.id)

  expect_identical(
    tr$temporal_repair,
    fifelse(x$cluster == 0L, NA_integer_, x$cluster)
  )

  for (column in ctdf_internal_cols) {
    expect_true(all(is.na(x[[column]])))
  }

  expect_false("putative_cluster_trace" %in% names(x))
})


test_that("putative_cluster_trace binds trace to ctdf", {
  x <- as_ctdf(mini_ruff)
  cluster_track(x, trace = TRUE)

  tr <- putative_cluster_trace(x)
  out <- putative_cluster_trace(x, bind = TRUE)

  trace_nams <- setdiff(names(tr), ".id")

  expect_s3_class(out, "ctdf")
  expect_identical(out$.id, x$.id)
  expect_identical(names(out), c(names(x), trace_nams))

  for (nam in trace_nams) {
    expect_identical(out[[nam]], tr[[nam]])
  }

  expect_false(any(trace_nams %in% names(x)))
})


test_that("putative_cluster_trace errors when trace does not match ctdf", {
  x <- as_ctdf(mini_ruff)
  cluster_track(x, trace = TRUE)

  attr(x, "putative_cluster_trace")$.id[1] <- -1L

  expect_error(
    putative_cluster_trace(x, bind = TRUE),
    "Trace does not match ctdf."
  )
})


test_that("putative_cluster_trace returns NULL without stored trace", {
  x <- as_ctdf(mini_ruff)

  expect_null(putative_cluster_trace(x))
  expect_null(putative_cluster_trace(x, bind = TRUE))
})
