library(raster)
library(rgdal)

# settings
vtype <- "tmax"
year <- 1996
doy <- 365
infolder <- paste0("/gpfs/projects/gavingrp/dongmeic/daymet/", year, "/", vtype, "/")
file <- paste0(vtype, year %% 100, formatC(doy, width = 3, format = "d", flag = "0"), ".tif")
indata <- paste0(infolder, file)
na10km <- "+proj=laea +lat_0=50 +lon_0=-100 +x_0=0 +y_0=0 +datum=WGS84 +units=m +no_defs +ellps=WGS84 +towgs84=0,0,0"

r <- raster(indata)
r1 <- projectRaster(r, crs = na10km)
plot(r1, xlim=c(-2050000,20000), ylim=c(-2000000,2000000))
r2 <- aggregate(r1, fact=10, fun=max)
plot(r2, xlim=c(-2050000,20000), ylim=c(-2000000,2000000))

roi.shp <- readOGR(dsn="/gpfs/projects/gavingrp/dongmeic/beetle/shapefiles", layer = "na10km_roi")
max.vals <- extract(r2, roi.shp, df=TRUE)