library(raster)
library(rgdal)

setwd("/gpfs/projects/gavingrp/dongmeic/beetle/output/plots")

# 1 - run in bash; 0 - run in R
if(1){
	args <- commandArgs(trailingOnly=T)
	print(paste('args:', args))
	print("Starting...")
	year <- as.numeric(args[1])
	print(paste('year:', year))
}

substrRight <- function(x, n){
  substr(x, nchar(x)-n+1, nchar(x))
}

daymet <- function(year, doy){
	infolder <- paste0("/gpfs/projects/gavingrp/dongmeic/daymet/", year, "/prcp/")
	file <- paste0("prcp", substrRight(as.character(year), 2), formatC(doy, width = 3, format = "d", flag = "0"), ".tif")
	paste0(infolder, file)
}

read.tif <- function(year, doy){
	if(!file.exists(daymet(year, doy))){
		print(paste(daymet(year, doy), "does not exist!"))
	}else{
		raster(daymet(year, doy))
	}
}

na10km <- "+proj=laea +lat_0=50 +lon_0=-100 +x_0=0 +y_0=0 +datum=WGS84 +units=m +no_defs +ellps=WGS84 +towgs84=0,0,0"
roi.shp <- readOGR(dsn="/gpfs/projects/gavingrp/dongmeic/beetle/shapefiles", layer = "na10km_roi")
roi.df <- roi.shp@data[,-1]
ptm <- proc.time()

infolder <- paste0("/gpfs/projects/gavingrp/dongmeic/beetle/output/tables/prcp")
dir.create(file.path(infolder), showWarnings = FALSE)
df <- as.data.frame(matrix(,ncol=0,nrow=77369))
pdf(paste0("prcp", year, ".pdf"), width=12, height=6)
for(doy in 1:365){
	if(!file.exists(daymet(year, doy))){
		next
		print(paste("file", year, doy, "doesn't exist..."))
	}else{
		r <- read.tif(year, doy)
		r1 <- projectRaster(r, crs = na10km)
		r2 <- aggregate(r1, fact=10, fun=mean)
		par(mfrow=c(1,3),mar=c(2,2,2,2))
		plot(r, main=paste("prcp", doy))
		plot(r1, xlim=c(-2050000,20000), ylim=c(-2000000,2000000), main=paste("prcp", doy, "reprojected"))
		plot(r2, xlim=c(-2050000,20000), ylim=c(-2000000,2000000), main=paste("prcp", doy, "resampled"))
		vals <- extract(r2, roi.shp, df=TRUE)
		if(sum(is.na(is.numeric(vals[,2])))!=0 & sum(is.na(is.numeric(vals[,2])))!=177){
			print(paste("these rows don't have values, and you need to check...", which(is.na(is.numeric(vals)))))
		}
		df <- cbind(df, vals[,2])
		names(df)[dim(df)[2]] <- names(vals)[2]
	}		
}
dev.off()
df <- cbind(roi.df[,1:2], df)
write.csv(df, paste0(infolder,"/prcp", year, ".csv"), row.names = FALSE)
print(paste("processed",year,"..."))

proc.time() - ptm

print("all done!")