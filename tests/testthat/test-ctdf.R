test_that(".check_ctdf errors on non-ctdf input", {
  expect_error(.check_ctdf(mini_ruff))
})


test_that(".check_ctdf errors on unsorted timestamp", {
  ctdf <- as_ctdf(mini_ruff)

  x <- ctdf[sample(.N)]

  expect_error(.check_ctdf(x))
})


test_that(".check_ctdf errors when required columns missing", {
  ctdf <- as_ctdf(mini_ruff)
  x <- copy(ctdf)[, .id := NULL]
  expect_error(.check_ctdf(x))
})


test_that(".check_ctdf errors on missing timestamps", {
  x <- as_ctdf(mini_ruff)
  x$timestamp[1] <- NA

  expect_error(.check_ctdf(x), "contains missing values")
})


test_that(".check_ctdf errors when timestamp is not POSIXt", {
  x <- as_ctdf(mini_ruff)
  x$timestamp <- as.numeric(x$timestamp)

  expect_error(.check_ctdf(x), "must inherit from 'POSIXt'")
})


test_that(".check_ctdf warns about duplicates introduced after conversion", {
  x <- as_ctdf(mini_ruff[1:2])
  x <- x[c(1, 1, 2, 2)]

  expect_warning(
    .check_ctdf(x),
    "Found 2 duplicated points.*at ctdf rows: 2, 4"
  )
})


test_that("duplicate checks require both location and timestamp to match", {
  x <- data.frame(
    longitude = c(10, 11, 10),
    latitude = c(50, 51, 50),
    time = as.POSIXct("2026-01-01", tz = "UTC") + c(0, 0, 3600)
  )

  expect_silent(as_ctdf(x))
})


test_that(".check_ctdf warns about temporal gaps greater than 24 hours", {
  old_options <- options(clusterTrack.max_gap = 24)
  on.exit(options(old_options), add = TRUE)
  x <- as_ctdf(mini_ruff[1:4])
  x$timestamp <- x$timestamp[1] + as.difftime(c(0, 1, 26, 52), units = "hours")

  expect_warning(
    .check_ctdf(x),
    "Found 2 temporal gaps.*smallest: 25 h.*largest: 26 h.*Split the file manually"
  )
})


test_that(".check_ctdf does not warn for gaps of exactly 24 hours", {
  old_options <- options(clusterTrack.max_gap = 24)
  on.exit(options(old_options), add = TRUE)
  x <- as_ctdf(mini_ruff[1:2])
  x$timestamp[2] <- x$timestamp[1] + as.difftime(24, units = "hours")

  expect_silent(.check_ctdf(x))
})


test_that(".check_ctdf uses the configured temporal gap threshold", {
  old_options <- options(clusterTrack.max_gap = 48)
  on.exit(options(old_options), add = TRUE)
  x <- as_ctdf(mini_ruff[1:2])
  x$timestamp[2] <- x$timestamp[1] + as.difftime(49, units = "hours")

  expect_warning(.check_ctdf(x), "greater than 48 h")
})


test_that(".check_ctdf silently disables gap checks for invalid options", {
  old_options <- options(clusterTrack.max_gap = "invalid")
  on.exit(options(old_options), add = TRUE)
  x <- as_ctdf(mini_ruff[1:2])
  x$timestamp[2] <- x$timestamp[1] + as.difftime(49, units = "hours")

  expect_silent(.check_ctdf(x))
})


test_that("as_ctdf warns on reserved columns", {
  mini_ruff <- copy(mini_ruff)
  mini_ruff[, .id := 1]
  expect_warning(as_ctdf(mini_ruff))
})


test_that("as_ctdf checks duplicates and reports sorted row positions", {
  x <- data.frame(
    lon = c(11, 10, 10),
    lat = c(51, 50, 50),
    observed = as.POSIXct("2026-01-01", tz = "UTC") + c(3600, 0, 0),
    value = 1:3
  )

  expect_warning(
    out <- as_ctdf(x, coords = c("lon", "lat"), time = "observed"),
    "Found 1 duplicated point.*at ctdf row: 2\\. Input may contain multiple individuals\\.$"
  )
  expect_equal(out$value, c(2, 3, 1))
})


test_that("as_ctdf checks the configured temporal gap threshold", {
  old_options <- options(clusterTrack.max_gap = 48)
  on.exit(options(old_options), add = TRUE)
  x <- copy(mini_ruff[1:2])
  x[, let(time = time[1] + as.difftime(c(0, 49), units = "hours"))]

  expect_warning(as_ctdf(x), "greater than 48 h")
})


test_that("as_ctdf_track creates LINESTRING segments", {
  ctdf <- as_ctdf(mini_ruff)
  track <- as_ctdf_track(ctdf)
  expect_true(nrow(track) == nrow(ctdf) - 1)
  geom_types <- sf::st_geometry_type(track$track)
  expect_true(all(geom_types == "LINESTRING"))
})


test_that("plot.ctdf runs without error", {
  ctdf <- as_ctdf(mini_ruff)
  expect_silent(plot(ctdf))
})
