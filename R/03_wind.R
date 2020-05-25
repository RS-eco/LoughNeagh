#'+ global_options
# Install required packages not yet in library
packages <- c("ggplot2", "grid", "raster", "mapproj", "dplyr",
              "rworldxtra", "tidyr")
#new.packages <- packages[!(packages %in% installed.packages()[,"Package"])]
#if(length(new.packages)) install.packages(new.packages); rm(new.packages)

# Load required packages
l <- sapply(packages, require, character.only = TRUE); rm(packages, l)

# Specify path of working directory
#workdir <-  "C:/Users/admin/Documents/GitHub/LoughNeagh"
workdir <- "/home/matt/Documents/LoughNeagh"

# Set working directory 
#setwd(workdir)

# Specify path of file directory
#filedir <- "E:/Data"
filedir <- "/media/matt/Data/Documents/Wissenschaft/Data"

# Define spatial projection
crs.wgs84 <- CRS("+proj=longlat +datum=WGS84 +no_defs +ellps=WGS84 +towgs84=0,0,0")

# Define colour theme for plotting
colourtheme <- colorRampPalette(c("#00007F", "blue", "#007FFF", "cyan", 
                                  "#7FFF7F", "yellow", "#FF7F00", 
                                  "red", "#7F0000"))(255)

#' ## Wind data 

#' Information on wind data, can be found here:
#' http://catalogue.ceda.ac.uk/uuid/a1f65a362c26c9fa667d98c431a1ad38

#' ### Find correct station

#' http://badc.nerc.ac.uk/search/midas_stations/
#' http://badc.nerc.ac.uk/googlemap/midas_googlemap.cgi

#' src_id:	1450, Name:	ALDERGROVE, Area:	ANTRIM, Start date:	01-01-1926, 
#' End date:	Current, Postcode:	BT29 4
#' Latitude (decimal degrees):	54.6636 ( WGS 84 value: 54.6637)
#' Longitude (decimal degrees):	-6.22436 ( WGS 84 value: -6.22534) 

#' # MIDAS: UK Mean Wind Data

#'+wind_data
# See this for column headers
(coln <- read.csv("extdata/WM_Column_Headers.csv", header=FALSE))

# Define column headers
colname <- c("OB_END_TIME", "ID_TYPE", "ID", "OB_HOUR_COUNT", "MET_DOMAIN_NAME", "VERSION_NUM",
             "SRC_ID", "REC_ST_IND", "MEAN_WIND_DIR", "MEAN_WIND_SPEED", "MAX_GUST_DIR", "MAX_GUST_SPEED", 
             "MAX_GUST_CTIME", "MEAN_WIND_DIR_Q", "MEAN_WIND_SPEED_Q", "MAX_GUST_DIR_Q", 
             "MAX_GUST_SPEED_Q", "MAX_GUST_CTIME_Q", "METO_STMP_TIME", "MIDAS_STMP_ETIME", 
             "MEAN_WIND_DIR_J", "MEAN_WIND_SPEED_J", "MAX_GUST_DIR_J", "MAX_GUST_SPEED_J")

# Read csv files of multiple years into R and convert into one file
# Read csv files of multiple years into R and convert into one file
if(!file.exists("data/ln_wind_2003_2017.rda")){
  # Get list of all wind data files
  wind_files <- c("midas_wind_200301-200312", "midas_wind_200401-200412",
                  "midas_wind_200501-200512", "midas_wind_200601-200612",
                  "midas_wind_200701-200712", "midas_wind_200801-200812",
                  "midas_wind_200901-200912", "midas_wind_201001-201012",
                  "midas_wind_201101-201112", "midas_wind_201201-201212",
                  "midas_wind_201301-201312", "midas_wind_201401-201412",
                  "midas_wind_201501-201512", "midas_wind_201601-201612",
                  "midas_wind_201701-201712")
  
  # Run code for every file within the list
  ln_wind_data <- lapply(wind_files, FUN= function(x){
    # Read one file
    wind_oneyear <- read.csv(paste0("extdata/", x, ".txt"), header=FALSE)
    
    # Define column headers
    colnames(wind_oneyear) <- colname
    
    # Subset data by id type = wind, station id = 914401
    wind_oneyear <- wind_oneyear[wind_oneyear$ID_TYPE == " WIND",] # Hourly mean wind data
    wind_oneyear <- wind_oneyear[wind_oneyear$MET_DOMAIN_NAME == " HCM",]
    
    # Subset by station ID, or source id = 1450
    ln_wind_oneyear <- wind_oneyear[wind_oneyear$ID == 914401,]; rm(wind_oneyear)
    
    # Remove time duplicates
    ln_wind_oneyear <- ln_wind_oneyear[!duplicated(ln_wind_oneyear$METO_STMP_TIME),]
    
    # Merge yearly data into one
    return(ln_wind_oneyear)
  }); rm(wind_files)
  
  # Convert list into dataframe
  ln_wind_data <- do.call("rbind", ln_wind_data)
  
  # Turn date/time column into a proper time format
  ln_wind_data$METO_STMP_TIME <- as.POSIXct(ln_wind_data$METO_STMP_TIME, 
                                            format="%Y-%m-%d %H:%M", tz="GMT")
  
  # Create a column with just the year
  ln_wind_data$year <- lubridate::year(ln_wind_data$METO_STMP_TIME)
  
  # Turn NAs into wind speed of previous measurement
  ln_wind_2003_2017 <- ln_wind_data %>% tidyr::fill(MEAN_WIND_DIR, .direction="down") %>% 
    tidyr::fill(MEAN_WIND_SPEED, .direction="down") %>% 
    select(c("METO_STMP_TIME", "MEAN_WIND_DIR", "MEAN_WIND_SPEED", "year"))
  
  # Turn data into daily data
  ln_wind_2003_2017 <- aggregate(ln_wind_2003_2017, 
                                 list(day = cut(ln_wind_2003_2017$METO_STMP_TIME, breaks="day")), 
                                 mean, na.rm = TRUE)
  
  # Save ln_wind_data to file
  save(ln_wind_2003_2017, file="data/ln_wind_2003_2017.rda", compress="xz")
} else{
  load("data/ln_wind_2003_2017.rda")
  # Turn date/time column into a proper time format
  ln_wind_2003_2017$METO_STMP_TIME <- as.POSIXct(ln_wind_2003_2017$METO_STMP_TIME,
                                                 format="%Y-%m-%d %H", tz="GMT")
}

# Plot wind speed
ln_wind_2003_2017$METO_STMP_TIME <- as.POSIXct(ln_wind_2003_2017$METO_STMP_TIME, format="%Y-%m-%d %H", tz="GMT")
ln_wind_2003_2017$day <- as.POSIXct(ln_wind_2003_2017$day)
ggplot(data = ln_wind_2003_2017, aes(x=day, y=MEAN_WIND_SPEED*0.514)) + 
  geom_line() + scale_x_datetime(name="Time", date_breaks="1 year", date_labels = "%Y", expand=c(.005,0)) + 
  scale_y_continuous(name="Wind speed (m/s)", limits=c(0,NA), expand=c(0,0.5)) + theme_bw() +
  geom_hline(yintercept = mean(ln_wind_2003_2017$MEAN_WIND_SPEED), colour="red") + 
  theme(axis.text.y = element_text(size = 14), axis.title = element_text(size=20),
        axis.text.x = element_text(size=14, angle=90, vjust=0.5))
ggsave(paste0("figures/ln_windspeed.png"), width=12, height=4)

# Plot wind direction
source("R/plot_windrose.R")
ln_wind_2003_2017$MEAN_WIND_SPEED <- ln_wind_2003_2017$MEAN_WIND_SPEED*0.514
p <- plot_windrose(data = ln_wind_2003_2017,
              spd = "MEAN_WIND_SPEED",
              dir = "MEAN_WIND_DIR")
p + theme_bw() + theme(axis.line.y = element_blank(), axis.ticks.y = element_blank(), 
                     axis.text.y = element_blank(),
                     panel.border = element_rect(fill="transparent", colour = "NA"), 
                     panel.background = element_blank()) + 
  labs(x=NULL, y=NULL)
ggsave(paste0("figures/ln_winddir.png"), width=8, height=6)

# Plot yearly wind speed
ggplot(data = ln_wind_2003_2017, aes(x=METO_STMP_TIME, y=MEAN_WIND_SPEED)) + 
  geom_line() + scale_x_datetime(date_breaks="1 month", date_labels = "%m") + 
  facet_wrap(~ year, ncol=4, scales="free_x") + theme_bw() + 
  theme(strip.background=element_rect(fill="transparent", colour="black")) + 
  labs(x="Month", y="Wind Speed (knots)")
ggsave(paste0("figures/ln_yearly_windspeed.png"), width=6, height=7)
# Wind speed is in knots

# Plot yearly wind direction
ggplot(data = ln_wind_2003_2017, aes(MEAN_WIND_DIR)) + 
  geom_histogram(binwidth=36) + facet_wrap(~ year) + theme_bw() + 
  theme(strip.background=element_rect(fill="transparent", colour="black")) + 
  coord_polar(theta = "x", start=0, direction=1) + labs(x="Direction (°)", y="Frequency")
ggsave(paste0("figures/ln_yearly_winddir.png"), width=4, height=6)

# Plot monthly wind direction
# now generate the faceting
ln_wind_2003_2017$month <- lubridate::month(ln_wind_2003_2017$METO_STMP_TIME, label=T)
plot_windrose(data = ln_wind_2003_2017, spd = "MEAN_WIND_SPEED", dir = "MEAN_WIND_DIR") + 
  facet_wrap(~month, ncol = 4) + theme_bw() + labs(x=NULL, y=NULL) + 
  theme(axis.line.y = element_blank(), axis.ticks.y = element_blank(), axis.text.y = element_blank(), 
        panel.border = element_rect(fill="transparent", colour = "NA"), 
        panel.background = element_blank(), strip.background = element_blank())
ggsave(paste0("figures/ln_monthly_winddir.png"), width=8, height=6)

#' # What is the mean wind speed for every year?
ln_wind_2003_2017 %>% group_by(year) %>% 
  summarise(avg_speed = mean(MEAN_WIND_SPEED, na.rm=TRUE),
            avg_dir = mean(MEAN_WIND_DIR, na.rm=TRUE))
