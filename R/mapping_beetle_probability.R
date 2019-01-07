# Created by Dongmei CHEN
# Modified from sftp://dongmeic:@talapas-ln1.uoregon.edu//gpfs/projects/gavingrp/dongmeic/sdm/R/logistic_model_output.R

library(ncdf4)
library(lattice)
library(rgdal)
library(raster)
library(rasterVis)
library(latticeExtra)
library(gridExtra)
library(RColorBrewer)
library(classInt)

path <- '/gpfs/projects/gavingrp/dongmeic/beetle/output/tables/test5/'
file <- 'predictions.csv'
prob <- read.csv(paste0(path, file))
loc <- read.csv('/gpfs/projects/gavingrp/dongmeic/beetle/output/tables/sdm_roi_loc.csv')
lonlat <- CRS("+proj=longlat +datum=NAD83")
setwd('/gpfs/projects/gavingrp/dongmeic/beetle/output/maps/prob')

shppath <- "/gpfs/projects/gavingrp/dongmeic/beetle/shapefiles"
canada.prov <- readOGR(dsn = shppath, layer = "na10km_can_prov")
us.states <- readOGR(dsn = shppath, layer = "na10km_us_state")
crs <- proj4string(us.states)
lrglakes <- readOGR(dsn = shppath, layer = "na10km_lrglakes")
proj4string(lrglakes) <- crs

get.spdf <- function(prob, year){
	df <- prob[prob$year==year,]
	xy <- data.frame(df[,c(1,2)])
	coordinates(xy) <- c('x', 'y')
	proj4string(xy) <- crs
	spdf <- SpatialPointsDataFrame(coords = xy, data = df, proj4string = crs)
	return(spdf)
}

nclr <- 5
color <- "RdYlGn"
plotclr <- rev(brewer.pal(nclr,color))

probmapping <- function(prob, year){
	spdf <- get.spdf(prob, year)
	plotvar <- spdf$probs
	class <- classIntervals(plotvar, nclr, style="kmeans", dataPrecision=2)
	colcode <- findColours(class, plotclr)
	png(paste0("prob_",year,"_test.png"), width=5, height=5, units="in", res=300)
	par(mfrow=c(1,1),mar=c(0.5,0,1.5,0))
	spdf1 <- spdf[spdf$btl_t==1,]
	plot(spdf, col=colcode, main=paste("Beetle probability predicted in", year), pch=19, cex=0.1)
	plot(spdf1, pch=19, cex=0.1, col=rgb(0,0,1,0.1),add=T)
	plot(canada.prov, col=rgb(0.7,0.7,0.7,0.7), add=T)
	plot(us.states, col=rgb(0.7,0.7,0.7,0.7), add=T)
	plot(lrglakes, border=rgb(0,0,0.3,0.1),add=T)
	legend('left',legend=names(attr(colcode, "table")),
					 fill=attr(colcode, "palette"), cex=1.2, title='Probability', bty="n")
	dev.off()
}

probmapping(prob, 2000)

probmapping_ts <- function(prob, outnm){
	png(paste0(outnm, ".png"), width=18, height=12, units="in", res=300)
	par(mfrow=c(3,6),mar=c(0.5,0.5,1.5,0))
	for (year in 1998:2015){
		spdf <- get.spdf(prob, year)
		plotvar <- spdf$probs
		class <- classIntervals(plotvar, nclr, style="kmeans", dataPrecision=2)
		colcode <- findColours(class, plotclr)
		spdf1 <- spdf[spdf$btl_t==1,]
		plot(spdf, col=colcode, pch=19, cex=0.1)
		title(main=year, adj = 0.5, line = -1, cex.main=2)
		plot(spdf1, pch=19, cex=0.1, col=rgb(0,0,1,0.1),add=T)
		legend(-2700000, 550000,legend=names(attr(colcode, "table")),
						 fill=attr(colcode, "palette"), title='', bty="n")
		print(year)
	}	
	dev.off()
}

probmapping_ts(prob, "model_without_beetle_variables")
path <- '/gpfs/projects/gavingrp/dongmeic/beetle/output/tables/test3/'
prob1 <- read.csv(paste0(path, file))
probmapping_ts(prob1, "model_with_beetle_variables")

year <- 1998
input <- read.csv(paste0('/gpfs/projects/gavingrp/dongmeic/beetle/output/tables/input/input_data_',year,'.csv'))

