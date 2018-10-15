library(raster)
library(rgdal)
install.packages("tiff", repos='http://cran.us.r-project.org')
library(tiff)

read.tif <- function(vtype, year, doy){
	infolder <- paste0("/gpfs/projects/gavingrp/dongmeic/daymet/", year, "/", vtype, "/")
	file <- paste0(vtype, year %% 100, formatC(doy, width = 3, format = "d", flag = "0"), ".tif")
	indata <- paste0(infolder, file)
	raster(indata)
}

mainDir <- "/gpfs/projects/gavingrp/dongmeic/daymet/"
subDir <- "/tmean"
ptm <- proc.time()
for(year in 1997:2015){ # run 1996 mannually first
	dir.create(file.path(mainDir,year,subDir), showWarnings = FALSE)
	infolder <- paste0("/gpfs/projects/gavingrp/dongmeic/daymet/", year, "/tmean/")
	dir.create(file.path(infolder), showWarnings = FALSE)
	for(doy in 1:365){
		tmax <- read.tif("tmax", year, doy)
		tmin <- read.tif("tmin", year, doy)
		tmean <- (tmax + tmin)/2	
		file <- paste0("tmean", year %% 100, formatC(doy, width = 3, format = "d", flag = "0"), ".tif")
		writeRaster(tmean, filename=paste0(infolder, file), datatype='INT4S', overwrite=TRUE)
		print(doy)
	}
	print(paste("processed",year,"..."))
}
proc.time() - ptm

print("all done!")