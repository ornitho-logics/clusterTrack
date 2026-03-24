# Test .check_ctdf

test_that(".check_ctdf errors on non-ctdf input", {
  expect_error(.check_ctdf(mini_ruff))
})


test_that(".check_ctdf errors on unsorted timestamp", {
  ctdf = as_ctdf(mini_ruff)

  x = ctdf[sample(.N)]

  expect_error(.check_ctdf(x))
})


test_that(".check_ctdf errors when required columns missing", {
  ctdf = as_ctdf(mini_ruff)
  x = copy(ctdf)[, .id := NULL]
  expect_error(.check_ctdf(x))
})


# Test as_ctdf

test_that("as_ctdf warns on reserved columns", {
  mini_ruff = copy(mini_ruff)
  mini_ruff[, .id := 1]
  expect_warning(as_ctdf(mini_ruff))
})

# Test as_ctdf_track

test_that("as_ctdf_track creates LINESTRING segments", {
  ctdf = as_ctdf(mini_ruff)
  track = as_ctdf_track(ctdf)
  expect_true(nrow(track) == nrow(ctdf) - 1)
  geom_types = sf::st_geometry_type(track$track)
  expect_true(all(geom_types == "LINESTRING"))
})


# Test plot.ctdf

test_that("plot.ctdf runs without error", {
  ctdf = as_ctdf(mini_ruff)
  expect_silent(plot(ctdf))
})
