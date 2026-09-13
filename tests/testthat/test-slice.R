make_deltaT_ctdf <- function() {
  as_ctdf(
    data.frame(
      longitude = c(-1, 1, 2, 1, -1),
      latitude = c(-1, 1, 1, -1, 1),
      time = as.POSIXct("2025-01-01", tz = "UTC") +
        c(0, 1, 2, 10, 11) * 3600
    )
  )
}

test_that("deltaT filters temporally distant segment crossings", {
  x <- make_deltaT_ctdf()

  .prepare_segs(x, deltaT = 0.2)

  expect_identical(
    x$.move_seg,
    c(NA_integer_, 1L, 1L, 1L, 1L)
  )

  expect_identical(
    x$.seg_id,
    c(NA_integer_, 1L, 1L, 1L, 1L)
  )
})


test_that("NA deltaT does not filter segment crossings", {
  x <- make_deltaT_ctdf()

  .prepare_segs(x, deltaT = NA)

  expect_identical(
    x$.move_seg,
    c(NA_integer_, 0L, 1L, 1L, 0L)
  )

  expect_identical(
    x$.seg_id,
    c(NA_integer_, 1L, 2L, 2L, 3L)
  )
})
