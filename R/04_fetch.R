# Calculate wind fetch

# Install required packages not yet in library
packages <- c("raster", "sf", "fetchR", "spatial.tools")
new.packages <- packages[!(packages %in% installed.packages()[,"Package"])]
if(length(new.packages)) install.packages(new.packages); rm(new.packages)

#'+r wind_fetch
# Effective fetch? - Håkanson and Jansson (1983)

#' Do not run this with the 100x100 m resolution specified in the bathymetry file,
#' as your computer will just crash after a couple of hours.

# Checks if file exists and otherwise creates the file
if(!file.exists("data/ln_fetch_10deg.rda")){
  # We want to calculate wind fetch for each pixel of the lake
  
  # Load shapefile of all waterbodies of NI
  #ni_waterbody <- readOGR(dsn = "extdata/ni_lakewaterbodiesshp", 
  #                        layer = "LakeWaterBodiesAUGUST2016", verbose=FALSE)
  ni_waterbody <- sf::st_read("extdata/ni_lakewaterbodiesshp/LakeWaterBodiesAUGUST2016.shp")
  
  # Select Lough Neagh
  #ln_wb <- ni_waterbody[ni_waterbody@data$namespace == "Lough Neagh",]
  ln_wb <- ni_waterbody[ni_waterbody$namespace == "Lough Neagh",]
  
  # Read lake bathymetry
  load("data/ln_bathy_int.rda")
  
  # Create a points layer by converting pixels into points
  # The points layer represents the locations for which the wind fetch needs to be calculated
  #coordinates(ln_bathy_int) <- ~x+y
  #projection(ln_bathy_int) <- crs(ln_wb)
  ln_bathy_int <- as(ln_bathy_int, "SpatialPointsDataFrame")
  
  # Remove points on land
  sites_within_lake <- over(ln_bathy_int, ln_wb)
  ln_bathy_int <- ln_bathy_int[!is.na(sites_within_lake$OBJECTID),]
  
  # Turn shapefile of lake inside out as otherwise locations lie within the shapefile
  studyarea <- spatial.tools::bbox_to_SpatialPolygons(extent(ln_wb), crs(ln_wb))
  outershape_ln <- gDifference(studyarea, ln_wb)
  
  # Calculate wind fetch in 10 degree steps
  ln_fetch_10deg <- fetchR::fetch(polygon_layer=outershape_ln, 
                          site_layer=ln_bathy_int, max_dist=100, n_directions=9) 
  
  # Save to file
  save(ln_fetch_10deg, file="data/ln_fetch_10deg.rda", compress="xz")
} else{
  load("data/ln_fetch_10deg.rda")
}

# Return a summary of our fetch data
summary(ln_fetch_10deg)

#fetch_ln.df <- data.frame(raster::rasterToPoints(ln_fetch_10deg))

# Convert fetch results into a raster stack
#fetch_t <- lapply(split(fetch_ln.df, f=fetch_ln.df$direction), as.list)
#fetch_ln_stack <- stack(lapply(fetch_t, FUN=function(x){
#  df <- data.frame(x)[,c("x", "y", "fetch")]
#  coordinates(df) <- ~ x+y
#  gridded(df) <- TRUE
#  projection(df) <- proj4string(ln_wb)
#  return(raster(df))
#}))
#names(fetch_ln_stack) <- seq(0, 350, by=10)
#fetch_ln_stack <- crop(mask(fetch_ln_stack, ln_wb), ln_wb)
#writeRaster(fetch_ln_stack, filename="Results/fetch_10deg_stack.tif", 
#            format="GTiff", overwrite=TRUE)

# Outline of Lough Neagh
ni_waterbody <- sf::st_read("extdata/LakeWaterBodiesAUGUST2016.shp")
# Select Lough Neagh
#ln_wb <- ni_waterbody[ni_waterbody@data$namespace == "Lough Neagh",]
ln_wb <- ni_waterbody[ni_waterbody$namespace == "Lough Neagh",]

#' # Plot fetch map of prevailing wind conditions!
ln_fetch_10deg <- as.data.frame(rasterToPoints(ln_fetch_10deg))
ggplot() + geom_raster(data=ln_fetch_10deg, aes(x,y, fill = X180)) + 
  scale_fill_gradientn(name="Fetch (km)", colours=
                         colorRampPalette(c("#00007F", "blue", "#007FFF", "cyan", 
                                            "#7FFF7F", "yellow", "#FF7F00", 
                                            "red", "#7F0000"))(255), 
                       na.value = "transparent", breaks=c(5,10,15,20,25)) + 
  geom_sf(data=ln_wb, fill="NA", colour="black") + 
  coord_sf(expand=FALSE, ndiscr=FALSE) + theme_classic() + 
  theme(axis.title = element_blank(), axis.line = element_blank(),
        axis.ticks = element_blank(), axis.text = element_blank(),
        panel.grid = element_blank(), panel.background = element_blank(), 
        legend.position=c(0.9,0.2))

# Save image to file
ggsave("figures/ln_fetch_180deg.png", dpi=300, width=8, height=8); rm(ln_fetch_10deg)
