library(raster)
library(rgdal)

substrRight <- function(x, n){
  substr(x, nchar(x)-n+1, nchar(x))
}

daymet <- function(vtype, year, doy){
	infolder <- paste0("/gpfs/projects/gavingrp/dongmeic/daymet/", year, "/", vtype, "/")
	file <- paste0(vtype, substrRight(as.character(year), 2), formatC(doy, width = 3, format = "d", flag = "0"), ".tif")
	paste0(infolder, file)
}

na10km <- "+proj=laea +lat_0=50 +lon_0=-100 +x_0=0 +y_0=0 +datum=WGS84 +units=m +no_defs +ellps=WGS84 +towgs84=0,0,0"

ptm <- proc.time()
for(vtype in c("prcp", "tmean", "tmax", "tmin")){
	for(year in c(1990:2015)){
		infolder <- paste0("/gpfs/projects/gavingrp/dongmeic/daymet/", year, "/", vtype, "/", "na10km/")
		dir.create(file.path(infolder), showWarnings = FALSE)
		for(doy in 1:365){
			if(!file.exists(daymet(vtype, year, doy))){
				next
			}else{
				indata <- read.tif(vtype, year, doy)
				r1 <- projectRaster(r, crs = na10km)
				plot(r1, xlim=c(-2050000,20000), ylim=c(-2000000,2000000))
				r2 <- aggregate(r1, fact=10, fun=mean)
				plot(r2, xlim=c(-2050000,20000), ylim=c(-2000000,2000000))
				roi.shp <- readOGR(dsn="/gpfs/projects/gavingrp/dongmeic/beetle/shapefiles", layer = "na10km_roi")
				max.vals <- extract(r2, roi.shp, df=TRUE)
			}		
		}
		print(paste("processed",year,"..."))
	}
	print(paste("processed",vtype,"..."))
}
proc.time() - ptm

print("all done!")