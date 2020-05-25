#' ## Calculate yearly sediment suspension

# Sum up to one layer (cumulative time of sediment suspension)
dwml <- stack("data/dwml.grd")
load("data/ln_bathy_int.rda")
ln_bathy_int <- crop(ln_bathy_int, dwml)

dwml[dwml < ln_bathy_int] <- NA
dwml[!is.na(dwml)] <- 1

susp_sed <- calc(dwml, fun=sum, na.rm=TRUE, 
                 filename="data/susp_sed.grd", bandorder="BIL")

#' # Plot map of cumulative suspended sediment areas
susp_sed <- susp_sed/nlayers(dwml)*100
susp_sed <- mask(susp_sed, ln_wb)
susp_sed_df <- data.frame(rasterToPoints(susp_sed))

ggplot() + geom_raster(data=susp_sed_df, aes(x,y, fill = layer)) + 
  scale_fill_gradient(name="% Suspended Sediment", 
                      low = "white", high = "red", 
                      na.value = "transparent", guide = "colourbar", 
                      breaks=seq(0,100,20)) + 
  labs(x=expression(paste("Eastings (m)")), 
       y=expression(paste("Northings (m)"))) + 
  geom_polygon(data=ln_wb, aes(x=long, y=lat, group=group), 
               fill="NA", colour="black") + coord_equal(expand=FALSE)
# Save image to file
ggsave("figures/ln_suspsed.png", dpi=300, width=8, height=8); rm(susp_sed_df)