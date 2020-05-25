#' ## Outline of Lough Neagh

#' +setup, include=FALSE
# Set global chunk setttings
knitr::opts_chunk$set(cache=TRUE, eval=TRUE, warning=FALSE, message=FALSE, comment=NA, echo=FALSE,
                      tidy=TRUE, results="hide", fig.width=8, fig.height=4, 
                      fig.path='Figures/', dev="png")

#' + global_options
# Install required packages not yet in library
packages <- c("ggplot2", "grid", "raster", "mapproj", "dplyr", 
              "rgdal", "rgeos", "rworldxtra", "RStoolbox")
new.packages <- packages[!(packages %in% installed.packages()[,"Package"])]
if(length(new.packages)) install.packages(new.packages); rm(new.packages)

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
colourtheme <- colorRampPalette(c("#00007F", "blue", "#007FFF", "cyan", "#7FFF7F", "yellow", "#FF7F00", "red", "#7F0000"))(255)

# Set plotting theme
theme_set(theme_bw())

#'+shapefile_ln
# Load countries data of Great Britain
data(countriesHigh, package="rworldxtra")
british_isles <- subset(countriesHigh, ne_10m_adm %in% c("IRL", "GBR")); rm(countriesHigh)
plot(british_isles)

# Load country boundaries of Great Britain
gadm_l1 <- getData("GADM", country = getData("ISO3")[
  getData("ISO3")$ISO3 == "GBR",2], 
  level=1, path=paste0(filedir, "/GADM"))

# Extract shape of Northern Ireland
northern_ireland <- gadm_l1[gadm_l1$NAME_1 == "Northern Ireland",]
plot(northern_ireland); rm(gadm_l1)

# Load shapefile of all waterbodies of NI
ni_waterbody <- readOGR(dsn = "extdata/LakeWaterBodiesAUGUST2016.shp", 
                        layer = "LakeWaterBodiesAUGUST2016", verbose=FALSE)
plot(ni_waterbody)

# Select Lough Neagh
ln_wb <- ni_waterbody[ni_waterbody@data$namespace == "Lough Neagh",]; rm(ni_waterbody)
plot(ln_wb)
# Comes in Mercator projection and not in WGS84 

# Transform projection to WGS84
ln_wgs84 <- spTransform(ln_wb, crs.wgs84)

# Plot of British Isles with Northern Ireland highlighted
a <- ggplot() + geom_polygon(data=british_isles, 
                             aes(x=long, y=lat, group=group), 
                             fill="gray", colour=NA) + 
  geom_polygon(data=northern_ireland, aes(x=long, y=lat, group=group), 
               fill="grey40", colour="transparent") + 
  geom_polygon(data=ln_wgs84, aes(x=long, y=lat, group=group), 
               fill="blue", colour="transparent") + 
  theme(axis.ticks = element_blank(), 
        axis.title.x = element_blank(), axis.title.y = element_blank(), 
        axis.text.x = element_blank(), axis.text.y = element_blank(), 
        panel.border = element_rect(fill="transparent", colour = "black"), 
        panel.grid.major=element_blank(),
        panel.grid.minor=element_blank(),
        panel.spacing=unit(0, "lines"),
        plot.background=element_blank(),
        plot.margin=unit(c(1, 1, 0.5, 0.5), "lines")) + labs(x=NULL, y=NULL) + 
  coord_map(); rm(british_isles)

# Plot of Lough Neagh
b <- ggplot() + geom_polygon(data=northern_ireland, aes(x=long, y=lat, group=group), 
                             fill="gray", colour="white", linetype="dashed") + 
  geom_polygon(data=northern_ireland, aes(x=long, y=lat, group=group), 
               fill=NA, colour="black") +
  geom_polygon(data=ln_wgs84, aes(x=long, y=lat, group=group), 
               fill="blue", colour="blue") +
  theme_bw() + theme(legend.position = "none") + 
  labs(x="Longitude (°)", y="Latitude (°)") + coord_map(); rm(northern_ireland)

# Combine the two plots and save to File
png(paste0(workdir, "/figures/ln_map.png"), width=9, height=7, 
    units="in", res=600, bg="transparent")
grid.newpage()
print(b, vp = viewport(width = 1, height = 1, x = 0.5, y = 0.5))
print(a, vp = viewport(width = 0.2, height = 0.5, x = 0.22, y = 0.8))
dev.off()