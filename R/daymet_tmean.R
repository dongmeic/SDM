library(raster)
library(rgdal)
library(tiff)

substrRight <- function(x, n){
  substr(x, nchar(x)-n+1, nchar(x))
}

daymet <- function(vtype, year, doy){
	infolder <- paste0("/gpfs/projects/gavingrp/dongmeic/daymet/", year, "/", vtype, "/")
	file <- paste0(vtype, substrRight(as.character(year), 2), formatC(doy, width = 3, format = "d", flag = "0"), ".tif")
	paste0(infolder, file)
}

read.tif <- function(vtype, year, doy){
	if(!file.exists(daymet(vtype, year, doy))){
		print(paste(daymet(vtype, year, doy), "does not exist!"))
	}else{
		raster(daymet(vtype, year, doy))
	}
}

ptm <- proc.time()
for(year in c(2000:2009)){
	infolder <- paste0("/gpfs/projects/gavingrp/dongmeic/daymet/", year, "/tmean/")
	dir.create(file.path(infolder), showWarnings = FALSE)
	for(doy in 1:365){
		if(!file.exists(daymet("tmax", year, doy)) | !file.exists(daymet("tmin", year, doy))){
			if(!file.exists(daymet("tmax", year, doy))){
				print(paste(daymet("tmax", year, doy), "does not exist!"))
			}else{
				print(paste(daymet("tmin", year, doy), "does not exist!"))
			}
			next
		}else{
		  tmax <- read.tif("tmax", year, doy)
			tmin <- read.tif("tmin", year, doy)
			if(extent(tmax) == extent(tmin)){
				tmean <- (tmax + tmin)/2
				file <- paste0("tmean", year %% 100, formatC(doy, width = 3, format = "d", flag = "0"), ".tif")
				writeRaster(tmean, filename=paste0(infolder, file), datatype='INT4S', overwrite=TRUE)
				print(doy)
			}else{
				print(paste("the extents do not match! Year", year, "DoY", doy))
				next
			}
		}		
	}
	print(paste("processed",year,"..."))
}
proc.time() - ptm

print("all done!")