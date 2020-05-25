# Calculate sedimentation rate from Linear Relationship with DWML

# Load shapefile of all waterbodies of NI
library(sf)
ni_waterbody <- st_read(dsn = "extdata/LakeWaterBodiesAUGUST2016.shp")
ln_wb <- ni_waterbody[ni_waterbody$namespace == "Lough Neagh",]; rm(ni_waterbody)

# Create Linear Model
df <- read.csv("data/dwml_sed_data.csv")
m <- lm(data=df, TotalSed ~ DWML)

## Plot linear models and mean linear model
library(ggplot2)
library(ggpmisc)
ggplot(data=df, aes(x=DWML, y=TotalSed)) + 
  geom_point() + stat_poly_eq(aes(label =  paste(..eq.label.., ..adj.rr.label.., sep = "~~~~")), 
                              formula = y ~ x, parse = TRUE) + 
  geom_smooth(method="lm", se=FALSE) + theme_bw() + 
  labs(x="DWML (m)", y="Total sedimentation rate (g/m2)")
ggsave("figures/ln_dwml_sed_original.png", width=8, height=5, dpi=300)

ggplot(data=df, aes(x=DWML, y=TotalSed)) + facet_wrap(~ Location, ncol=1) + 
  geom_point() + stat_poly_eq(aes(label =  paste(..eq.label.., ..adj.rr.label.., sep = "~~~~")), 
                              formula = y ~ x, parse = TRUE) + 
  geom_smooth(method="lm", se=FALSE) + theme_bw() + 
  labs(x="DWML (m)", y="Total sedimentation rate")
ggsave("figures/lm_split_dwml_sed.png", width=8, height=8)

ggplot(data=df, aes(x=DWML, y=TotalSed)) +
  geom_point() + geom_smooth(method="gam") + theme_bw() + 
  labs(x="DWML (m)", y="Total sedimentation rate")
ggsave("figures/gam_dwml_sed.png", width=7, height=5)

# Read wind data
load("data/ln_wind_2003_2017.rda")

# Turn 0 and 360 degree wind direction into 360.
ln_wind_2003_2017$MEAN_WIND_DIR[ln_wind_2003_2017$MEAN_WIND_DIR == 0] <- 360

# Create dates vector
dates <- as.POSIXct(ln_wind_2003_2017$METO_STMP_TIME, format="%Y-%m-%d %H:%M", tz="GMT")

if(!file.exists(paste0("data/mean_sd_sed_rate.rda"))){
  if(!file.exists(paste0("data/sed_rate.grd"))){
    library(raster)
    dwml <- stack(paste0("data/dwml.grd"))
    
    # y = mx + t
    sed_rate <- m$coefficients[2]*dwml + m$coefficients[1]
    
    writeRaster(sed_rate, filename="data/sed_rate.grd", bandorder="BIL")
  }
  
  sed_rate <- stack(paste0("data/sed_rate.grd"))
  
  # Calculate mean and sd of sedimentation rate
  sd_data <- cellStats(sed_rate, "sd")
  mn_data <- cellStats(sed_rate, "mean")
  
  mean_sd_sed_rate <- as.data.frame(cbind(sd_data, mn_data))
  mean_sd_sed_rate$date <- dates
  
  save(mean_sd_sed_rate, file="data/mean_sd_sed_rate.rda", compress="xz")
}
# Turn sedimentation rate in mg/l


# Create spatial and temporal summary

if(!file.exists(paste0("data/sum_sed_rate_mgl.rda"))){
  # Divide Sedimentation rate by depth!!!
  load("data/ln_bathy_int.rda")
  
  sed_rate <- stack("data/sed_rate.grd")
  ln_bathy <- crop(ln_bathy_int, sed_rate)
  sed_rate_mgl <- sed_rate/ln_bathy
  
  # Calculate mean and sd of sedimentation rate
  sd_data <- cellStats(sed_rate, "sd")
  mn_data <- cellStats(sed_rate, "mean")
  
  mean_sd_sed_rate <- as.data.frame(cbind(sd_data, mn_data))
  mean_sd_sed_rate$date <- dates
  
  save(mean_sd_sed_rate, file="data/sum_sed_rate_mgl.rda", compress="xz")
}

# Plot sedimentation rate over time

# Load Data
load("data/mean_sd_sed_rate.rda")

# Plot
ggplot(data=mean_sd_sed_rate, aes(x=date)) + 
  geom_ribbon(aes(ymin=mn_data-sd_data, ymax=mn_data+sd_data), colour="lightgrey") + 
  geom_line(aes(y=mn_data), colour="black") + 
  scale_x_datetime(name="Time", date_breaks="1 year", date_labels = "%Y", expand=c(0,0)) + 
  theme_bw() + ylab("Sedimentation rate (g/m2)")
ggsave("figures/ln_mn_sed_rate.png", width=12, height=4)

#' # Plot map of min, mean and max sedimentation rate
library(raster)
sed_rate <- stack("data/sum_sed_rate_mgl.tif")
sed_rate <- mask(sed_rate, ln_wb, snap=T)
sed_rate <- data.frame(rasterToPoints(sed_rate))
colnames(sed_rate) <- c("x", "y", "min", "mean", "max")
col_val1 <- scales::rescale(unique(c(seq(min(sed_rate$min), 0, length=5), seq(0, max(sed_rate$min), length=6))))
p1 <- ggplot() + geom_raster(data=sed_rate, aes(x=x,y=y, fill=min)) + 
  scale_fill_gradientn(name="Min", colours=
                         colorRampPalette(c("#00007F", "blue", "#007FFF", "cyan", "white", "#7FFF7F", 
                                            "yellow", "#FF7F00", "red", "#7F0000"))(255), 
                       na.value = "transparent", values=col_val1) + 
  geom_sf(data=ln_wb, fill="NA", colour="black") + 
  coord_sf(expand=FALSE, ndiscr = 0) + theme_classic() + 
  theme(axis.title = element_blank(), axis.line = element_blank(),
        axis.ticks = element_blank(), axis.text = element_blank(),
        panel.grid = element_blank(), panel.background = element_blank(),
        panel.border = element_blank(), legend.position=c(0.95,0.2))
col_val2 <- scales::rescale(unique(c(seq(min(sed_rate$mean), 0, length=5), seq(0, max(sed_rate$mean), length=5))))
p2 <- ggplot() + geom_raster(data=sed_rate, aes(x=x,y=y, fill=mean)) + 
  scale_fill_gradientn(name="Mean", colours=colorRampPalette(c("#00007F", "blue", "#007FFF", "cyan", "white", "#7FFF7F", 
                                                               "yellow", "#FF7F00", "red", "#7F0000"))(255), 
                       na.value = "transparent", values=col_val2) + 
  geom_sf(data=ln_wb, fill="NA", colour="black") + 
  coord_sf(expand=FALSE, ndiscr = 0) + theme_classic() + 
  theme(axis.title = element_blank(), axis.line = element_blank(),
        axis.ticks = element_blank(), axis.text = element_blank(),
        panel.grid = element_blank(), panel.background = element_blank(),
        panel.border = element_blank(), legend.position=c(0.95,0.2))
col_val3 <- scales::rescale(unique(seq(min(sed_rate$max), max(sed_rate$max), length=5)))
p3 <- ggplot() + geom_raster(data=sed_rate, aes(x=x,y=y, fill=max)) + 
  scale_fill_gradientn(name="Max", colours=
                         colorRampPalette(c("#7FFF7F", "yellow", "#FF7F00", "red", "#7F0000"))(255), 
                       na.value = "transparent", values=col_val3) + 
  geom_sf(data=ln_wb, fill="NA", colour="black") + 
  coord_sf(expand=FALSE, ndiscr = 0) + theme_classic() + 
  theme(axis.title = element_blank(), axis.line = element_blank(),
        axis.ticks = element_blank(), axis.text = element_blank(),
        panel.grid = element_blank(), panel.background = element_blank(),
        panel.border = element_blank(), legend.position=c(0.95,0.2))
library(patchwork)
p <- p1 + p2 + p3 + plot_layout(nrow=1)
ggsave("figures/ln_total_sed.png", width=12, height=6)
rm(list=ls()[!grepl(ls(), pattern="ln_wb")]); invisible(gc())

#' # Plot map of min, mean and max sedimentation rate
sed_rate <- stack("data/sed_rate_sum.tif")
sed_rate <- mask(sed_rate, ln_wb)
sed_rate <- data.frame(rasterToPoints(sed_rate))
colnames(sed_rate) <- c("x", "y", "min", "mean", "max")

p1 <- ggplot() + geom_raster(data=sed_rate, aes(x=x,y=y, fill=min)) + 
  scale_fill_gradientn(name="Min", colours=
                         colorRampPalette(c("#00007F", "blue", "#007FFF", "cyan", 
                                            "#7FFF7F", "yellow", "#FF7F00", 
                                            "red", "#7F0000"))(255), 
                       na.value = "transparent") + 
  geom_sf(data=ln_wb, fill="NA", colour="black") + 
  coord_sf(expand=FALSE, ndiscr = 0) + theme_classic() + 
  theme(axis.title = element_blank(), axis.line = element_blank(),
        axis.ticks = element_blank(), axis.text = element_blank(),
        panel.grid = element_blank(), panel.background = element_blank(),
        panel.border = element_blank(), legend.position=c(0.95,0.2))
p2 <- ggplot() + geom_raster(data=sed_rate, aes(x=x,y=y, fill=mean)) + 
  scale_fill_gradientn(name="Mean", colours=
                         colorRampPalette(c("#00007F", "blue", "#007FFF", "cyan", 
                                            "#7FFF7F", "yellow", "#FF7F00", 
                                            "red", "#7F0000"))(255), 
                       na.value = "transparent") + 
  geom_sf(data=ln_wb, fill="NA", colour="black") + 
  coord_sf(expand=FALSE, ndiscr = 0) + theme_classic() + 
  theme(axis.title = element_blank(), axis.line = element_blank(),
        axis.ticks = element_blank(), axis.text = element_blank(),
        panel.grid = element_blank(), panel.background = element_blank(),
        panel.border = element_blank(), legend.position=c(0.95,0.2))
p3 <- ggplot() + geom_raster(data=sed_rate, aes(x=x,y=y, fill=max)) + 
  scale_fill_gradientn(name="Max", colours=
                         colorRampPalette(c("#00007F", "blue", "#007FFF", "cyan", 
                                            "#7FFF7F", "yellow", "#FF7F00", 
                                            "red", "#7F0000"))(255), 
                       na.value = "transparent") + 
  geom_sf(data=ln_wb, fill="NA", colour="black") + 
  coord_sf(expand=FALSE, ndiscr = 0) + theme_classic() + 
  theme(axis.title = element_blank(), axis.line = element_blank(),
        axis.ticks = element_blank(), axis.text = element_blank(),
        panel.grid = element_blank(), panel.background = element_blank(),
        panel.border = element_blank(), legend.position=c(0.95,0.2))
p <- p1 + p2 + p3 + plot_layout(nrow=1)
ggsave("figures/ln_sed_rate.png", width=12, height=6)

# Load Data
load("data/mean_sed_rate_mgl.rda")

mean_sd_sed_rate$day <- as.Date(mean_sd_sed_rate$date)
mean_sd_sed_rate$mn_data[mean_sd_sed_rate$mn_data <= 0] <- 0
ggplot(data=mean_sd_sed_rate, aes(x=day, y=mn_data)) + 
  geom_line(colour="black") + 
  geom_hline(yintercept=mean(mean_sd_sed_rate$mn_data, na.rm=T), colour="red") +
  scale_x_date(name="", date_breaks="1 year", date_labels = "%Y", expand=c(0.005,0)) + 
  scale_y_continuous(name="Total sedimentation (mg/l)") + 
  theme_bw() + theme(axis.text.y = element_text(size = 14), 
                     axis.title = element_text(size=18),
                     axis.text.x = element_text(size=14, angle=90, vjust=0.5))
ggsave("figures/ln_mn_total_sed.png", width=12, height=4)

## Sedimentation rate for Kinnegon Bay

# Get sed_rate for Kinnegon Bay
if(!file.exists(paste0("data/sed_rate_mgl_kinnego.rda"))){
  library(raster)
  sed_rate <- stack("data/sed_rate_mgl.grd")
  plot(sed_rate[[1]])
  kinnegon <- data.frame(x=-6.35, y=54.51)
  coordinates(kinnegon) <- ~x+y
  projection(kinnegon) <- crs.wgs84 <- CRS("+proj=longlat +datum=WGS84 +no_defs +ellps=WGS84 +towgs84=0,0,0")
  kinnegon <- spTransform(kinnegon, crs("+proj=tmerc +lat_0=53.5 +lon_0=-8 +k=1.000035 +x_0=200000 +y_0=250000
+datum=ire65 +units=m +no_defs +ellps=mod_airy
+towgs84=482.530,-130.596,564.557,-1.042,-0.214,-0.631,8.15"))
  plot(kinnegon, add=T)
  
  sed_kin <- extract(sed_rate, kinnegon, df=T)
  sed_kin <- data.frame(t(sed_kin))
  head(sed_kin)
  sed_kin$date <- as.Date(mean_sd_sed_rate$date)
  save(sed_kin, file="data/sed_rate_mgl_kinnego.rda", compress="xz")
}

load("data/sed_rate_mgl_kinnego.rda")
sed_kin$date <- as.Date(sed_kin$date)
sed_kin$sed_kin[sed_kin$sed_kin <= 0] <- 0
ggplot(data=sed_kin, aes(x=date, y=sed_kin)) + 
  geom_line(colour="black") + 
  geom_hline(yintercept=mean(sed_kin$sed_kin, na.rm=T), colour="red") + 
  scale_x_date(name="", date_breaks="1 year", date_labels = "%Y", expand=c(0.005,0)) + 
  scale_y_continuous(name="Total sedimentation (mg/l)") + 
  theme_bw() + theme(axis.text.y = element_text(size = 14), 
                     axis.title = element_text(size=18),
                     axis.text.x = element_text(size=14, angle=90, vjust=0.5))
ggsave("figures/total_sed_kinnego.png", dpi=600, width=12, height=4)

# Load Lough Neagh data
load("data/mean_sed_rate_mgl.rda")
mean_sd_sed_rate$day <- as.Date(mean_sd_sed_rate$date)
mean_sd_sed_rate$year <- lubridate::year(mean_sd_sed_rate$day)
mean_sd_sed_rate$mn_data[mean_sd_sed_rate$mn_data <= 0] <- 0
mean_sd_sed_rate$loc <- "Lough Neagh"
colnames(mean_sd_sed_rate)

# Lough Kinnegon data
load("data/sed_rate_mgl_kinnego.rda")
sed_kin$day <- as.Date(sed_kin$date)
sed_kin$year <- lubridate::year(sed_kin$day)
sed_kin$sed_kin[sed_kin$sed_kin <= 0] <- 0
sed_kin$loc <- "Kinnego Bay"
colnames(sed_kin) <- c("mn_data", "date", "day", "year", "loc")

# Merge data
library(dplyr)
mean_sd_sed_rate <- mean_sd_sed_rate %>% dplyr::select("mn_data", "year", "loc")
sed_kin <- sed_kin %>% dplyr::select("mn_data", "year", "loc")
sed_rate <- dplyr::bind_rows(mean_sd_sed_rate, sed_kin)

# Create plot
sed_rate %>% group_by(loc, year) %>% 
  ggplot(aes(x=as.factor(year), y=mn_data, fill=loc)) + 
  scale_fill_discrete(name="") + 
  geom_boxplot() + labs(x="Year", y="Total sedimentation (mg/l)") + 
  theme_bw() + theme(axis.text.y = element_text(size = 14), 
                     axis.title = element_text(size=18),
                     axis.text.x = element_text(size=14, angle=90, vjust=0.5),
                     legend.text = element_text(size=14),
                     legend.position="bottom")
ggsave("figures/sed_rate_year_comp.png", width=8, height=6)

sed_rate %>% group_by(loc) %>% 
  ggplot(aes(x=loc, y=mn_data)) + 
  geom_boxplot() + labs(x="Location", y="Total sedimentation (mg/l)") + 
  theme_bw() + theme(axis.text.y = element_text(size = 14), 
                     axis.title = element_text(size=18),
                     axis.text.x = element_text(size=14, angle=0, vjust=0.5))
ggsave("figures/sed_rate_all_comp.png", width=8, height=6)
