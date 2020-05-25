#' Calculate the significant wave height
#'
#' Calculates the wave height given the wind speed
#' at 10m, fetch length and (optionally) water depth.
#'
#' Significant wave height (m) is estimated from 
#' the wind speed at 10m (\eqn{U_{10}}) and the fetch length (\emph{F}) as
#' described in Resio et al. (2003):
#' \deqn{{U_f}^2 = 0.001 (1.1 + 0.035 U_{10}) {U_{10}}^2} (friction velocity)
#' \deqn{\frac{g H}{{U_f}^2} = \min (0.0413 \sqrt{\frac{g F}{{U_f}^2}}, 211.5)}
#'
#' @param wind Wind speed at 10m, in m/s.
#' @param fetch Fetch length, in meters.
#' @return Significant wave height, in meters.
#' @references Resio, D.T., Bratos, S.M., and Thompson, E.F. (2003). Meteorology
#'  and Wave Climate, Chapter II-2. Coastal Engineering Manual.
#'  US Army Corps of Engineers, Washington DC, 72pp.
#' @examples
#'  wave_height(wind = 10, fetch = 15000)
#'  @export
wave_height <- function(wind = 10, fetch = NA) {
  # Friction velocity squared
  uf2 <- 0.001 * (1.1 + 0.035 * wind) * wind^2
  # Non-dimensional fetch and height
  if (any(!is.na(fetch))){
    fetch_nd <- fetch * g_acc / uf2
    height_nd <- pmin(0.0413 * sqrt(fetch_nd), 211.5)
    # Calculate height
    height_nd * uf2 / g_acc
  } else{
    0.27 * wind^2 / g_acc
  }
}

# Significant wave height (Hs) (m)
wave_height2 <- function(eff_fetch, wind_speed){
  # gravitational acceleration (m/s^2)
  g_acc <- 9.80665 
  ((0.0026*(((g_acc*eff_fetch)/wind_speed^2)^0.47))*wind_speed^2)/g_acc
}

