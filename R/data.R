#' ARGOS satellite tracking data for an individual Pectoral Sandpiper
#'
#' A dataset containing ARGOS locations for an individual male Pectoral Sandpiper
#'
#' @format A data.table with 882 rows and 4 columns:
#' \describe{
#'   \item{latitude}{Numeric. Latitude in decimal degrees (WGS84).}
#'   \item{longitude}{Numeric. Longitude in decimal degrees (WGS84).}
#'   \item{locationDate}{POSIXct. Timestamp of location fix (UTC).}
#'   \item{locationClass}{Character. ARGOS location quality class (e.g., B, 0, A).}
#' }
#'
#' @source  Kempenaers, Bart, and Mihai Valcu. "Breeding site sampling across the Arctic
#'          by individual males of a polygynous shorebird." Nature 541.7638 (2017): 528-531.
#'
#' @examples
#' data(pesa56511)
#' head(pesa56511)
"pesa56511"

#' ARGOS satellite tracking data for an individual Long-billed dowitcher
#'
#' A dataset containing ARGOS locations for an individual male Long-billed dowitcher.
#'
#' @format A data.table with 2501 rows and 4 columns:
#' \describe{
#'   \item{latitude}{Numeric. Latitude in decimal degrees (WGS84).}
#'   \item{longitude}{Numeric. Longitude in decimal degrees (WGS84).}
#'   \item{locationDate}{POSIXct. Timestamp of location fix (UTC).}
#'   \item{locationClass}{Character. ARGOS location quality class (e.g., B, 0, A).}
#' }
#'
#' @source  Kwon, Eunbi, Mihai Valcu, and Bart Kempenaers. “Strong Wintering Site Fidelity Contrasts
#'          with Exploratory Breeding Site Sampling in a Socially Monogamous Shorebird.”
#'          Movement Ecology, vol. 13, no. 1, 2025, p. 49, https://doi.org/10.1186/s40462-025-00580-3.
#'
#' @examples
#' data(lbdo66862)
#' head(lbdo66862)
"lbdo66862"

#' ARGOS satellite tracking data for an individual Ruff
#'
#' A dataset containing ARGOS locations for an individual male Ruff.
#'
#' `ruff143789` is the full dataset; `mini_ruff` is a reduced subset used for examples and tests.
#'
#' @format For `ruff143789`: a data.table with 2834 rows and 4 columns.
#'
#' @source  Kempenaers, Bart, et al. "Large-scale sampling of potential breeding sites in male ruffs."
#'          Proceedings B 292.2038 (2025): 20242225.
#'          https://royalsocietypublishing.org/doi/full/10.1098/rspb.2024.2225.
#'
#' @examples
#' data(ruff143789)
"ruff143789"

#' Reduced ARGOS satellite tracking data for an individual Ruff
#'
#' `mini_ruff` is a reduced subset of `ruff143789` used in examples and tests.
#'
#' @format A data.table with 276 rows and 4 columns:
#' \describe{
#'   \item{latitude}{Numeric. Latitude in decimal degrees (WGS84).}
#'   \item{longitude}{Numeric. Longitude in decimal degrees (WGS84).}
#'   \item{locationDate}{POSIXct. Timestamp of location fix (UTC).}
#'   \item{locationClass}{Character. ARGOS location quality class.}
#' }
#'
#' @source See `ruff143789`.
#'
#' @examples
#' data(mini_ruff)
#' head(mini_ruff)
"mini_ruff"


#' GNSS tracking data for an individual ruff.
#'
#' A dataset containing GNSS locations for an individual male ruff.
#'
#' @format A data.table with 2772 rows and 3 columns:
#' \describe{
#'   \item{timestamp}{POSIXct. Timestamp of location fix (UTC).}
#'   \item{latitude}{Numeric. Latitude in decimal degrees (WGS84).}
#'   \item{longitude}{Numeric. Longitude in decimal degrees (WGS84).}

#' }
#'
#' @source  Unpublished data.
#'
#' @examples
#' data(ruff07b5)
#' head(ruff07b5)
"ruff07b5"

#'
#' GNSS tracking data for an individual northern lapwing.
#'
#' A dataset containing GNSS locations for an individual female northern lapwing.
#'
#' @format A data.table with 2484 rows and 3 columns:
#' \describe{
#'   \item{timestamp}{POSIXct. Timestamp of location fix (UTC).}
#'   \item{latitude}{Numeric. Latitude in decimal degrees (WGS84).}
#'   \item{longitude}{Numeric. Longitude in decimal degrees (WGS84).}

#' }
#'
#' @source  Unpublished data.
#'
#' @examples
#' data(nola125a)
#' head(nola125a)
"nola125a"
