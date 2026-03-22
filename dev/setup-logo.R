m = magick::image_read_svg("dev/logo.svg", width = 300) |>
  magick::image_trim()

magick::image_write(m, 'man/figures/logo.png', format = "png")


pkgdown::build_favicons(overwrite = TRUE)
