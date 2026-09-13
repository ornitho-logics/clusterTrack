.ctdf_sf_data <- function() {
  data.frame(
    longitude = c(11, 10, 12),
    latitude = c(51, 50, 52),
    time = as.POSIXct("2026-01-01", tz = "UTC") + c(3600, 0, 7200),
    value = c("second", "first", "third")
  )
}


test_that("sf conversion uses the source geometry and CRS without modifying input", {
  points <- .ctdf_sf_data()
  x <- sf::st_as_sf(points, coords = c("longitude", "latitude"), crs = 4326)
  x <- sf::st_transform(x, 3857)
  sf::st_geometry(x) <- "fixes"
  names(x)[names(x) == "time"] <- "observed"
  original <- data.table::copy(x)

  out <- as_ctdf(x, time = "observed", t_srs = 3035)
  expected <- as_ctdf(points, t_srs = 3035)

  expect_s3_class(out, "ctdf")
  expect_s3_class(out, "sf")
  expect_s3_class(out, "data.table")
  expect_identical(attr(out, "sf_column"), "location")
  expect_identical(names(out), names(expected))
  expect_equal(sf::st_crs(out), sf::st_crs(3035))
  expect_equal(sf::st_coordinates(out), sf::st_coordinates(expected))
  expect_equal(sf::st_drop_geometry(out), sf::st_drop_geometry(expected))
  expect_equal(out$value, c("first", "second", "third"))
  expect_identical(data.table::key(out), ".id")
  expect_identical(x, original)
  expect_false("s_srs" %in% names(formals(as_ctdf.sf)))
})


test_that("sf conversion requires POINT geometries, a time column, and a CRS", {
  x <- sf::st_as_sf(
    .ctdf_sf_data(),
    coords = c("longitude", "latitude"),
    crs = 4326
  )
  mixed <- sf::st_sf(
    time = x$time[1:2],
    geometry = sf::st_sfc(
      sf::st_point(c(10, 50)),
      sf::st_multipoint(matrix(c(10, 50, 11, 51), ncol = 2, byrow = TRUE)),
      crs = 4326
    )
  )

  expect_error(as_ctdf(mixed), "POINT")
  expect_error(as_ctdf(x, time = "absent"), "absent")
  expect_error(as_ctdf(sf::st_set_crs(x, NA)), "CRS")
})


test_that("both input methods warn about and initialize reserved columns", {
  points <- .ctdf_sf_data()
  points$.id <- 77
  points$cluster <- 88
  points$lof <- 99
  x <- sf::st_as_sf(points, coords = c("longitude", "latitude"), crs = 4326)

  for (input in list(points, x)) {
    expect_warning(out <- as_ctdf(input), "reserved column names")

    expect_identical(out$.id, seq_len(nrow(out)))
    expect_identical(
      tail(names(out), length(reserved_ctdf_nams)),
      reserved_ctdf_nams
    )
    for (column in c(".seg_id", ".move_seg", ".putative_cluster", "cluster")) {
      expect_identical(out[[column]], rep(NA_integer_, nrow(out)))
    }
    expect_identical(out$lof, rep(NA_real_, nrow(out)))
  }
})


test_that("sf conversion checks duplicates after sorting timestamps", {
  points <- .ctdf_sf_data()[c(1, 2, 2), ]
  names(points)[names(points) == "time"] <- "timestamp"
  x <- sf::st_as_sf(points, coords = c("longitude", "latitude"), crs = 4326)

  expect_warning(
    out <- as_ctdf(x, time = "timestamp"),
    "Found 1 duplicated point.*at ctdf row: 2\\. Input may contain multiple individuals\\.$"
  )
  expect_equal(out$value, c("first", "first", "second"))
})


test_that("sf conversion checks the configured temporal gap threshold", {
  old_options <- options(clusterTrack.max_gap = 48)
  on.exit(options(old_options), add = TRUE)
  points <- .ctdf_sf_data()[1:2, ]
  points$time <- points$time[1] + as.difftime(c(0, 49), units = "hours")
  x <- sf::st_as_sf(points, coords = c("longitude", "latitude"), crs = 4326)

  expect_warning(as_ctdf(x), "greater than 48 h")
})
