test_that("summary.ctdf returns correct summary", {
  ctdf = as_ctdf(mini_ruff)
  cluster_track(ctdf)

  out = summary(ctdf)

  expect_s3_class(out, c("summary_ctdf", "data.table", "data.frame"))
  expect_equal(nrow(out), uniqueN(ctdf[cluster > 0]$cluster))

  expect_true(all(
    c(
      "cluster",
      "start",
      "stop",
      "geometry",
      "lof_q95",
      "ids",
      "N",
      "tenure",
      "dist_to_next",
      "elongation"
    ) %in%
      names(out)
  ))

  expect_true(all(out$cluster > 0))
  expect_true(all(out$start <= out$stop))
  expect_true(all(out$N > 0))
  expect_true(all(is.finite(out$lof_q95) | is.na(out$lof_q95)))
  expect_true(all(is.finite(out$elongation) | is.na(out$elongation)))

  expect_s3_class(out$geometry, "sfc_POINT")
  expect_length(out$dist_to_next, nrow(out))
  expect_true(is.na(out$dist_to_next[nrow(out)]))

  expect_match(out$ids[1], "^[0-9]+-[0-9]+$")
})
