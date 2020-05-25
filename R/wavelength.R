#' Calculate the wavelength
#'
#' Calculate the wavelength given the wave period and water depth.
#' 
#' The wave length is estimated from 
#' the wind speed at 10m (\eqn{U_{10}}) and the fetch length (\emph{F}) as
#' described in Resio et al. (2003):
#' \deqn{\frac{g T}{U_f} = \min (0.651 (\frac{g F}{{U_f}^2})^{1/3}, 239.8)}
#' If the depth (\emph{d}) is specified, it imposes a limit on the peak period:
#' \deqn{T_{max} = 9.78 \sqrt{\frac{d}{g}}} (in seconds)
#'
#' @param period Peak wave period, in seconds.
#' @param depth Water depth, in meters.
#' @return wavelength in m
#' @references
#' \url{http://planetcalc.com/4406/}
#' @examples
#'  wavelength(wind = 12, depth = 10)
#' @export
wavelength <- function(period = 2, depth = 100, rel_depth="deep") {
  # gravitational acceleration (m/s^2)
  g_acc <- 9.80665 
  
  # Angular frequency (rad/s)
  w <- 2*pi/period
  
  if(rel_depth == "shallow"){
    # Shallow water
    
    # wave number
    k <- (w^2)/(g_acc*depth)
    
    # Phase velocity
    c <- sqrt(g_acc*depth)
    
    # Group velocity
    cg <- c
    
    # wavelength
    lambda <- period*(sqrt(g_acc*depth))
    return(lambda)
    
  } else if(rel_depth == "deep"){
    # Deep water
    
    # wave number
    k <- (w^2)/g_acc
    
    # Phase velocity
    c <- (g_acc*period)/(2*pi)
    
    # Group velocity
    cg <- (g_acc*period)/(4*pi)
    
    # wavelength
    lambda <- (g_acc*(period^2))/(2*pi)
    return(lambda)
  }
}
