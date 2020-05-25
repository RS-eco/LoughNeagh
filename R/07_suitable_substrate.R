#' # Bottom substrate type

# Load shapefile of all waterbodies of NI
library(sf)
ni_waterbody <- sf::st_read(dsn = "extdata/LakeWaterBodiesAUGUST2016.shp")

# Select Lough Neagh
library(dplyr)
ln_wb <- ni_waterbody %>% filter(namespace == "Lough Neagh"); rm(ni_waterbody)

# Load manually created shapefile of bottom substrates
# and transform into UTM projection

substrate_type <- sf::st_read("extdata/Substrate_types_projective.shp") %>% 
  st_transform(crs=st_crs(ln_wb))
#substrate_type$Type <- as.factor(substrate_type$Type)

# Turn substrate type into raster layer
#library(raster)
#r <- raster(resolution=c(500, 500), extent(ln_wb)*1.05,crs=crs(ln_wb))
#substrate_type_r <- raster::rasterize(substrate_type, r, "Type")
#levels(substrate_type$Type)

# Plot substrate type
#substrate_type_df <- as.data.frame(rasterToPoints(substrate_type_r))
#substrate_type_df$layer <- factor(substrate_type_df$layer, 
#                                  labels=levels(substrate_type$Type)[c(1,2,3,4,5,6,7,8)])

#ggplot() + geom_raster(data=substrate_type_df, aes(x,y, fill = layer)) + 
#  scale_fill_discrete(name="Substrate Type") + 
#  labs(x=expression(paste("Eastings (m)")), 
#       y=expression(paste("Northings (m)"))) + theme_bw() + 
#  geom_sf(data=ln_wb, fill="NA", colour="black") + 
#  coord_sf(datum=st_crs(ln_wb), expand=FALSE)

library(ggplot2)
ggplot() + geom_sf(data = substrate_type, aes(fill = Type)) + 
  geom_sf(data=ln_wb, fill="NA", colour="black") + 
  coord_sf(expand=FALSE, ndiscr = 0) + theme_classic() + 
  theme(axis.title = element_blank(), axis.line = element_blank(),
        axis.ticks = element_blank(), axis.text = element_blank(),
        panel.grid = element_blank(), panel.background = element_blank(),
        panel.border = element_blank(), legend.position=c(0.92,0.15))
# Save image to file
ggsave("figures/ln_substrate_type.png", dpi=300, width=8, height=8)

# Plot only suitable substrate
suitable_substrate <- substrate_type %>% 
  filter(Type %in% c("Level_Hard_Bottom", "Gravel", "Rocks_Stones"))
ggplot() + geom_sf(data = suitable_substrate, aes(fill = Type)) + 
  geom_sf(data=ln_wb, fill="NA", colour="black") + 
  coord_sf(datum=st_crs(ln_wb), expand=FALSE, ndiscr = 0) + theme_classic() + 
  theme(axis.title = element_blank(), axis.line = element_blank(),
        axis.ticks = element_blank(), axis.text = element_blank(),
        panel.grid = element_blank(), panel.background = element_blank(),
        panel.border = element_blank(), legend.position=c(0.9,0.2))
# Save image to file
ggsave("figures/ln_suitable_substrate.png", dpi=300, width=7, height=8)

#' # Suitable areas

# Calculate overlap of SuspSed and SuitableSubstrate

###
# susp_sed_df needed!!!
###

#suitable_area <- inner_join(susp_sed_df, suitable_substrate, by=c("x","y"))
#ggplot() + geom_raster(data=suitable_area, aes(x,y, fill = layer)) + 
#  scale_fill_discrete(name="Substrate Type") + 
#  labs(x=expression(paste("Eastings (m)")), 
#       y=expression(paste("Northings (m)"))) + 
#  geom_polygon(data=ln_wb, aes(x=long, y=lat, group=group), 
#               fill="NA", colour="black") + coord_equal(expand=FALSE)
