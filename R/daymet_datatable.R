library(raster)
library(rgdal)
library(RColorBrewer)
library(classInt)

setwd("/gpfs/projects/gavingrp/dongmeic/beetle/output/daily/20181017")

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

na10km <- "+proj=laea +lat_0=50 +lon_0=-100 +x_0=0 +y_0=0 +datum=WGS84 +units=m +no_defs +ellps=WGS84 +towgs84=0,0,0"
roi.shp <- readOGR(dsn="/gpfs/projects/gavingrp/dongmeic/beetle/shapefiles", layer = "na10km_roi")
roi.df <- roi.shp@data[,-1]

ptm <- proc.time()
#for(vtype in c("tmean", "tmax", "tmin")){
for(vtype in c("prcp")){
	infolder <- paste0("/gpfs/projects/gavingrp/dongmeic/beetle/output/tables/", vtype)
	dir.create(file.path(infolder), showWarnings = FALSE)
	for(year in c(2002:2015)){
		df <- as.data.frame(matrix(,ncol=0,nrow=77369))
		pdf(paste0(vtype, year, ".pdf"), width=12, height=6)
		for(doy in 1:365){
			if(!file.exists(daymet(vtype, year, doy))){
				next
			}else{
				r <- read.tif(vtype, year, doy)
				r1 <- projectRaster(r, crs = na10km)
				r2 <- aggregate(r1, fact=10, fun=mean)
				par(mfrow=c(1,3),mar=c(2,2,2,2))
				plot(r, main=paste(vtype, doy))
				plot(r1, xlim=c(-2050000,20000), ylim=c(-2000000,2000000), main=paste(vtype, doy, "reprojected"))
				plot(r2, xlim=c(-2050000,20000), ylim=c(-2000000,2000000), main=paste(vtype, doy, "resampled"))
				vals <- extract(r2, roi.shp, df=TRUE)
				df <- cbind(df, vals[,2])
				names(df)[dim(df)[2]] <- names(vals)[2]
			}		
		}
		dev.off()
		df <- cbind(roi.df[,1:2], df)
		if(0){
			plotvar <- df[,dim(df)[2]]
			nclr <- 8
			plotclr <- brewer.pal(nclr,"BuPu")
			class <- classIntervals(plotvar, nclr, style="quantile")
			colcode <- findColours(class, plotclr)
			plot(df$x, df$y, pch=16, cex=0.5, col=colcode)
		}
		write.csv(df, paste0(infolder,"/",vtype, year, ".csv"), row.names = FALSE)
		print(paste("processed",year,"..."))
	}
	print(paste("processed",vtype,"..."))
}
proc.time() - ptm

print("all done!")