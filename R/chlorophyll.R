#' # Chlorophyll-a
#'+r chlorophyll, eval=FALSE
if(!file.exists(paste0(workdir, "/Results/chlorophyll_lough_neagh_4km.tif"))){
  # Path specification of directory for OceanColor files
  chl_files <- list.files(paste0(filedir, "/OceanColor/MODISA/Annual_4km_Chlorophyll_OCI/"), 
                          pattern="*.L3m_YR_CHL_chlor_a_4km.nc", full.names=T)
  
  # Load nc files as raster
  chlorophyll <- stack(chl_files, varname="chlor_a") #mg m-3
  names(chlorophyll) <- c(2002:2016)
  
  # Transform lake shapefile to wgs84 projection
  ln_wb_wgs <- spTransform(ln_wb, crs.wgs84)
  
  # Mask and Crop Chlorophyll by outline of Lake
  chlorophyll <- crop(mask(chlorophyll, ln_wb_wgs), ln_wb_wgs) 
  
  # Save chlorophyll data of Lough Neagh
  writeRaster(chlorophyll, "Results/chlorophyll_lough_neagh_4km.tif")
} else {
  chlorophyll <- stack("Results/chlorophyll_lough_neagh_4km.tif")
}

# Prepare data for plotting
projection(chlorophyll)  <- crs.wgs84
chlorophyll_df <- data.frame(rasterToPoints(chlorophyll))
years <- 2002:2016
colnames(chlorophyll_df) <- c("x", "y", years)
chlorophyll_long <- tidyr::gather(chlorophyll_df[,c(1:10)], "year", "chl", -c(x,y))
colnames(chlorophyll_long) <- c("x", "y", "year", "chl")

# Plot annual chlorophyll maps
ggplot() + 
  geom_raster(data=chlorophyll_long, aes(x,y,fill=chl)) + 
  scale_fill_gradientn(name="Chl-a", colours=colourtheme, na.value="transparent") + 
  scale_x_continuous(name=expression(paste("Longitude (",degree,")")), 
                     expand=c(0,0)) + 
  scale_y_continuous(name=expression(paste("Latitude (",degree,")")), 
                     expand=c(0,0)) + 
  geom_polygon(data=ln_wb_wgs, aes(long,lat, group=group), 
               fill="transparent", colour="black") + 
  facet_wrap(~year, ncol=2) + coord_equal(expand=FALSE)
ggsave(paste0("Figures/Chl_LoughNeagh_2002_2009_4km.png"), 
       width=6, height=9)

chlorophyll_long <- tidyr::gather(chlorophyll_df[,c(1,2,11:ncol(chlorophyll_df))], "year", "chl", -c(x,y))
colnames(chlorophyll_long) <- c("x", "y", "year", "chl")

# Plot annual chlorophyll maps
ggplot() + 
  geom_raster(data=chlorophyll_long, aes(x,y,fill=chl)) + 
  scale_fill_gradientn(name="Chl-a", colours=colourtheme, na.value="transparent") + 
  scale_x_continuous(name=expression(paste("Longitude (",degree,")")), 
                     expand=c(0,0)) + 
  scale_y_continuous(name=expression(paste("Latitude (",degree,")")), 
                     expand=c(0,0)) + 
  geom_polygon(data=ln_wb_wgs, aes(long,lat, group=group), 
               fill="transparent", colour="black") + 
  facet_wrap(~year, ncol=2) + coord_equal(expand=FALSE)
ggsave(paste0("Figures/Chl_LoughNeagh_2010_2016_4km.png"), 
       width=6, height=9)