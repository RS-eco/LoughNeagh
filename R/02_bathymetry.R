#' ## Bathymetry

# Install required packages not yet in library
packages <- c("raster", "sf", "mapproj", "gstat")
new.packages <- packages[!(packages %in% installed.packages()[,"Package"])]
if(length(new.packages)) install.packages(new.packages); rm(new.packages)

# Specify path of file directory
filedir <- "/media/matt/Data/Documents/Wissenschaft/Data"

#'+shapefile_ln
# Load countries data of Great Britain
data(countriesHigh, package="rworldxtra")
british_isles <- subset(countriesHigh, ne_10m_adm %in% c("IRL", "GBR"))
british_isles@data <- droplevels(british_isles@data)
rm(countriesHigh)

# Load country boundaries of Great Britain
library(raster)
gbr_l1 <- getData("GADM", country = getData("ISO3")[getData("ISO3")$ISO3 == "GBR",2], 
                  level=1, path=paste0(filedir, "/GADM"))
ireland<- getData("GADM", country = getData("ISO3")[getData("ISO3")$ISO3 == "IRL",2], 
                  level=0, path=paste0(filedir, "/GADM"))

northern_ireland <- gbr_l1[gbr_l1$NAME_1 == "Northern Ireland",]

# Load shapefile of all waterbodies of NI
#ni_waterbody <- readOGR(dsn = "extdata/LakeWaterBodiesAUGUST2016.shp", 
#                        layer = "LakeWaterBodiesAUGUST2016", verbose=FALSE)
ni_waterbody <- sf::st_read("extdata/LakeWaterBodiesAUGUST2016.shp")

# Select Lough Neagh
#ln_wb <- ni_waterbody[ni_waterbody@data$namespace == "Lough Neagh",]
ln_wb <- ni_waterbody[ni_waterbody$namespace == "Lough Neagh",]

# Transform projection to WGS84
northern_ireland <- spTransform(northern_ireland, sf::st_crs(ln_wb)$proj4string)
ireland <- spTransform(ireland, sf::st_crs(ln_wb)$proj4string)
british_isles <- spTransform(british_isles, sf::st_crs(ln_wb)$proj4string)

irl_north_irl <- do.call(bind, list(northern_ireland, ireland)) 

#'+bathymetry
# Read bathymetry point data
ln_bathy <- read.table("extdata/LoughNeaghBathy.dat", header=FALSE, sep=" ", dec=".")
colnames(ln_bathy) <- c("x", "y", "depth")

# Set ln_new to SpatialPointsDataFrame
coordinates(ln_bathy) <- ~x+y
projection(ln_bathy) <- CRS("+proj=longlat +datum=WGS84 +no_defs +ellps=WGS84 +towgs84=0,0,0")

# Transform data in Mercator projection
ln_bathy <- spTransform(ln_bathy, crs(ln_wb))
ln_bathy <- as.data.frame(ln_bathy)

# Interpolate a bathymetry map from the contours
if(!file.exists("data/ln_bathy_int.rda")){
  # Create an empty raster with the desired resolution and extent
  r <- raster(resolution=c(100, 100), extent(ln_wb)*1.05,crs=crs(ln_wb))
  
  # Inverse distance weighted
  idw <- gstat::gstat(id = "depth", formula = depth~1, locations = ~x+y, data=ln_bathy, 
                      nmax=7, set=list(idp = .5)); rm(ln_bathy)
  ln_bathy_int <- mask(interpolate(object=r, model=idw), ln_wb); rm(idw, r)
  
  # Crop image by extent of shapefile
  ln_bathy_int <- crop(mask(ln_bathy_int, ln_wb), ln_wb)
  names(ln_bathy_int) <- "depth"
  # Save bathymetry raster map to file
  save(ln_bathy_int, file="data/ln_bathy_int.rda", compress="xz")
} else{
  # Load bathymetry raster file
  load("data/ln_bathy_int.rda")
}

# Define location of weather station
loc_ws <- data.frame(y=54.6637, x=-6.22534)
coordinates(loc_ws) <- ~x+y
projection(loc_ws) <- CRS("+proj=longlat +datum=WGS84 +no_defs +ellps=WGS84 +towgs84=0,0,0")

# Reproject in Mercator projection
loc_ws <- spTransform(loc_ws, crs(ln_wb))

# Turn into dataframe for plotting
loc_ws <- as.data.frame(loc_ws)

# Read sampling locations file
samplingsites <- readxl::read_xlsx("extdata/ZM_presence_sites.xlsx")
samplingsites <- tidyr::separate(samplingsites, `Co-ordinates`, into=c("y","x"), sep=",")
samplingsites <- tidyr::drop_na(samplingsites)
samplingsites$x <- as.numeric(samplingsites$x)
samplingsites$y <- as.numeric(samplingsites$y)
coordinates(samplingsites) <- ~x+y
projection(samplingsites) <- CRS("+proj=longlat +datum=WGS84 +no_defs +ellps=WGS84 +towgs84=0,0,0")
samplingsites <- spTransform(samplingsites, sf::st_crs(ln_wb)$proj4string)
samplingsites <- as.data.frame(samplingsites)

# Plot of British Isles with Northern Ireland highlighted
a <- ggplot() +  
  geom_polygon(data=ireland, aes(x=long, y=lat, group=group), 
               fill="grey40", colour="transparent") + 
  geom_polygon(data=northern_ireland, aes(x=long, y=lat, group=group), 
               fill="grey40", colour="transparent") + 
  geom_sf(data=ln_wb, fill="blue", colour="transparent") + 
  theme_bw() + coord_sf(expand=TRUE, ndiscr=0) + 
  theme(axis.title = element_blank(), axis.line = element_blank(),
        axis.ticks = element_blank(), axis.text = element_blank(),
        panel.grid = element_blank(), panel.background = element_blank())

# Plot bathymetry map and include location of wind station
ln_bathy_int_df <- data.frame(rasterToPoints(ln_bathy_int))
colnames(ln_bathy_int_df) <- c("x", "y", "depth")
b <- ggplot() + geom_tile(data=ln_bathy_int_df, aes(x,y, fill = depth)) + 
  scale_fill_gradient(name="Depth (m)", low = "blue", high = "white", 
                      na.value = "transparent", guide = "colourbar") + 
  geom_sf(data=ln_wb, fill="NA", colour="black") + 
  geom_point(data=loc_ws, aes(x=x,y=y), colour="green3", shape=8, size=2) + 
  geom_point(data=samplingsites, aes(x=x,y=y,shape=Presence), col="red") + 
  scale_x_continuous(limits=c(289500, 315000), expand=c(0,0)) + 
  scale_y_continuous(limits=c(360000, 390500), expand=c(0,0)) + 
  coord_sf(expand=FALSE, ndiscr=0, datum=sf::st_crs(ln_wb)$proj4string) + theme_classic() + 
  theme(axis.title = element_blank(), axis.line = element_blank(),
        axis.ticks = element_blank(), axis.text = element_blank(),
        panel.grid = element_blank(), panel.background = element_blank(), 
        legend.position=c(0.9,0.15))

# Combine the two plots and save to File
png("figures/ln_bathymetry.png", width=7, height=8, 
    units="in", res=600, bg="transparent")
grid::grid.newpage()
print(b, vp = grid::viewport(width = 1, height = 1, x = 0.5, y = 0.5))
print(a, vp = grid::viewport(width = 0.2, height = 0.35, x = 0.15, y = 0.55))
dev.off()
