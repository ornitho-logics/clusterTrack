context('tdbscan')

test_that('tdbscan is sf', {
  data(pesa56511)
  expect_warning(x <- as_tdbscan(pesa56511, time = "locationDate"), "deprecated")

  expect_warning(
    z <- tdbscan(x, eps = 6600, minPts = 8, maxLag = 6, borderPoints = TRUE),
    "deprecated"
  )

  expect_s3_class(z, 'sf')
})
