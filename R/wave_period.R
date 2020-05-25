#' Calculate the peak wave period
#'
#' Calculates the peak wave period given the wind speed
#' at 10m, fetch length and (optionally) water depth.
#'
#' The peak wave period is estimated from 
#' the wind speed at 10m (\eqn{U_{10}}) and the fetch length (\emph{F}) as
#' described in Resio et al. (2003):
#' \deqn{\frac{g T}{U_f} = \min (0.651 (\frac{g F}{{U_f}^2})^{1/3}, 239.8)}
#' If the depth (\emph{d}) is specified, it imposes a limit on the peak period:
#' \deqn{T_{max} = 9.78 \sqrt{\frac{d}{g}}} (in seconds)
#'
#' @param wind Wind speed at 10m, in m/s.
#' @param fetch Fetch length, in meters.
#' @param depth Water depth, in meters.
#' @return Peak wave period, in seconds.
#' @references Resio, D.T., Bratos, S.M., and Thompson, E.F. (2003). Meteorology
#'  and Wave Climate, Chapter II-2. Coastal Engineering Manual.
#'  US Army Corps of Engineers, Washington DC, 72pp.
#' @examples
#'  wave_period(wind = 12, fetch = 15000, depth = 10)
#' @export
wave_period <- function(wind = 10, fetch = 1000, depth = 10) {
  # gravitational acceleration (m/s^2)
  g_acc <- 9.80665
  # Friction velocity squared
  uf2 <- 0.001 * (1.1 + 0.035 * wind) * wind^2
  # Non-dimensional fetch, height and period
  fetch_nd <- fetch * g_acc / uf2
  period_nd <- pmin(0.651 * fetch_nd^(1/3), 239.8)
  # Calculate period (with depth limitation, if available)
  period <- period_nd * sqrt(uf2) / g_acc
  return(period)
  if (any(!is.na(depth)))
  pmin(period, 9.78 * sqrt(depth / g_acc))
}

# Define function for calculating the significant wave period (Ts) (secs)
wave_period2 <- function(eff_fetch=1000, wind_speed=10){
  # gravitational acceleration (m/s^2)
  g_acc <- 9.80665
  ((0.46*(((g_acc*eff_fetch)/wind_speed^2)^0.28))*wind_speed)/g_acc
}
