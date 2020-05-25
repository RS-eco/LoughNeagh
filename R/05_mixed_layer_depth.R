#' # Wave mixed layer depth

# Calculate fetch, wave height and wave period over time

# Read general fetch data
load("data/ln_fetch_10deg.rda")
names(ln_fetch_10deg) <- seq(0,350, by=10)

# Read wind data
load("data/ln_wind_2003_2017.rda")

# Turn 0 and 360 degree wind direction into 360.
ln_wind_2003_2017$MEAN_WIND_DIR <- round(ln_wind_2003_2017$MEAN_WIND_DIR/10)*10
ln_wind_2003_2017$MEAN_WIND_DIR[ln_wind_2003_2017$MEAN_WIND_DIR == 0] <- 360

# Create dates vector
dates <- as.POSIXct(ln_wind_2003_2017$METO_STMP_TIME, format="%Y-%m-%d %H:%M", tz="GMT")

if(!file.exists("data/mean_sd_data.rda")){
  
  # Combine wind direction and correct fetch to an hourly fetch map
  if(!file.exists(paste0("data/fetch_ln.grd"))){
    fetch_ln <- stack(lapply(1:length(ln_wind_2003_2017$MEAN_WIND_DIR),
                             FUN=function(x){
                               ln_fetch_10deg[[(ln_wind_2003_2017$MEAN_WIND_DIR[x]/10)]]}))
    writeRaster(fetch_ln, filename=paste0("data/fetch_ln.grd"), bandorder="BIL")
  } else{
    fetch_ln <- stack(paste0("data/fetch_ln.grd"))
  }
  
  # Create wind speed raster (has the same value for all fields)
  # and convert from knots to m/s
  wind_speed_ln <- ln_wind_2003_2017$MEAN_WIND_SPEED*0.514
  
  # Following Douglas and Rippey 2000
  # The random redistribution of sediment by wind in a lake
  
  # Calculate the wave height for every hour in 2015
  if(!file.exists("data/wave_height.grd")){
    source("R/wave_height.R")
    wave_height <- calc(fetch_ln, fun=function(x) wave_height2(x*1000, wind_speed_ln), 
                        filename="data/wave_height.grd", bandorder="BIL")
  }
  
  # Calculate the wave period for every hour in 2015
  if(!file.exists("data/wave_period.grd")){
    source("R/wave_period.R")
    wave_period <- calc(fetch_ln, fun=function(x) wave_period2(x*1000, wind_speed_ln), 
                        filename="data/wave_period.grd", bandorder="BIL")
  }
  
  # Calculate dwml in parallel!
  if(!file.exists("data/dwml.grd")){
    wave_period <- stack("data/wave_period.grd")
    # Calculate the wave length (lambda) and lambda/2 (Mixed layer depth)
    beginCluster(n=round(0.75*parallel::detectCores()))
    dwml <- clusterR(wave_period, fun=function(period){((9.80665*(period^2))/(2*pi))/2})
    endCluster()
    writeRaster(dwml, filename="data/dwml.grd", bandorder="BIL")
  }
  
  #' # Get average and sd of wave_period, wave_height and dwml over time!
  mean_sd_data <- lapply(list("wave_period", "wave_height", "dwml"), function(var){
    data <- stack(paste0("data/", var, ".grd"))
    sd_data <- cellStats(data, "sd")
    mn_data <- cellStats(data, "mean")
    data <- as.data.frame(cbind(sd_data, mn_data))
    data$var <- var
    data$date <- dates
    return(data)
  })
  mean_sd_data <- do.call("rbind", mean_sd_data)
  save(mean_sd_data, file="data/mean_sd_data.rda", compress="xz")
}

# Plot DWML, wave_height and wave_period over time

# Load Data
library(dplyr)
load("data/mean_sd_data.rda")

# Plot
library(ggplot2)
mean_sd_data$var <- factor(mean_sd_data$var, label=c("DWML", "Wave height", "Wave period"))
ggplot(data=mean_sd_data, aes(x=date)) + 
  geom_ribbon(aes(ymin=mn_data-sd_data, ymax=mn_data+sd_data), colour="lightgrey") + 
  geom_line(aes(y=mn_data), colour="black") + 
  scale_x_datetime(name="Time", date_breaks="1 year", date_labels = "%Y", expand=c(0,0)) + 
  facet_wrap(~ var, ncol=1, scales="free_y", strip.position="left") + theme_bw() + 
  theme(strip.text = element_text(size=12), 
        strip.placement="outside", 
        strip.background = element_blank()) + ylab(NULL)
ggsave("figures/ln_wave_dwml.png", width=8, height=6, dpi=300)
