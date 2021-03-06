# Created by Dongmei CHEN
# Modified from sftp://dongmeic:@talapas-ln1.uoregon.edu//gpfs/projects/gavingrp/dongmeic/sdm/R/logistic_model_output.R
# Run in interactive mode

library(ncdf4)
library(lattice)
library(rgdal)
library(raster)
library(rasterVis)
library(latticeExtra)
library(gridExtra)
library(RColorBrewer)
library(classInt)

source('/gpfs/projects/gavingrp/dongmeic/sdm/R/model_output_functions.R')
path <- '/gpfs/projects/gavingrp/dongmeic/beetle/output/tables/'
file <- 'predictions.csv'
loc <- read.csv('/gpfs/projects/gavingrp/dongmeic/beetle/output/tables/sdm_roi_loc.csv')
lonlat <- CRS("+proj=longlat +datum=NAD83")
setwd('/gpfs/projects/gavingrp/dongmeic/beetle/output/maps/prob')

shppath <- "/gpfs/projects/gavingrp/dongmeic/beetle/shapefiles"
canada.prov <- readOGR(dsn = shppath, layer = "na10km_can_prov")
us.states <- readOGR(dsn = shppath, layer = "na10km_us_state")
crs <- proj4string(us.states)
lrglakes <- readOGR(dsn = shppath, layer = "na10km_lrglakes")
proj4string(lrglakes) <- crs

get.spdf <- function(i, year){
	model <- paste0('model', i)
	prob <- read.csv(paste0(path, model, '/', file))
	df <- prob[prob$year==year,]
	xy <- data.frame(df[,c(1,2)])
	coordinates(xy) <- c('x', 'y')
	proj4string(xy) <- crs
	spdf <- SpatialPointsDataFrame(coords = xy, data = df, proj4string = crs)
	return(spdf)
}

xy <- data.frame(loc[,c(1,2)])
coordinates(xy) <- c('x', 'y')
proj4string(xy) <- crs
loc.spdf <- SpatialPointsDataFrame(coords = xy, data = loc, proj4string = crs)

nclr <- 5
color <- "GnBu"
plotclr <- brewer.pal(nclr,color)

probmapping <- function(i, year){
	spdf <- get.spdf(i, year)
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

probmapping_ts <- function(i, outnm){
	png(paste0(outnm, ".png"), width=18, height=12, units="in", res=300)
	par(mfrow=c(3,6),mar=c(0.5,0.5,1.5,0))
	for (year in 1998:2015){
		spdf <- get.spdf(i, year)
		plotvar <- spdf$probs
		#class <- classIntervals(plotvar, nclr, style="kmeans", dataPrecision=2)
		if(i==1){
			class <- classIntervals(plotvar, nclr, style="fixed", fixedBreaks=c(0.01, 0.08, 0.21, 0.37, 0.55, 0.92))
		}else if(i==2){
			class <- classIntervals(plotvar, nclr, style="fixed", fixedBreaks=c(0.01, 0.08, 0.23, 0.40, 0.58, 0.99))
		}else{
			class <- classIntervals(plotvar, nclr, style="fixed", fixedBreaks=c(0.01, 0.08, 0.27, 0.50, 0.75, 0.99))
		}
		colcode <- findColours(class, plotclr)
		spdf1 <- spdf[spdf$btl_t==1,]
		plot(spdf, col=colcode, pch=19, cex=0.1)
		title(main=year, adj = 0.5, line = -1, cex.main=2)
		plot(spdf1, pch=19, cex=0.05, col=rgb(1,0,0,0.25),add=T)
		plot(canada.prov, col=rgb(0.7,0.7,0.7,0.7), cex=0.3, add=T)
		plot(us.states, col=rgb(0.7,0.7,0.7,0.7), cex=0.3, add=T)
		if(year==2015){
			legend(-2700000, 550000,legend=names(attr(colcode, "table")),
						 fill=attr(colcode, "palette"), title='', bty="n")		
		}
		print(year)
	}	
	dev.off()
}

probmapping_ts(2, "model_without_beetle_variables")
probmapping_ts(3, "model_with_beetle_variables")
probmapping_ts(1, "model_with_only_bioclm")
probmapping_ts(4, "model_with_age_density")
probmapping_ts(5, "model_with_age_density_more")

year <- 1998

get.spdf.btl <- function(year){
	input <- read.csv(paste0('/gpfs/projects/gavingrp/dongmeic/beetle/output/tables/input/input_data_',year,'.csv'))
	df <- input[,c('btl_t', 'x', 'y')]
	xy <- data.frame(df[,c(2,3)])
	coordinates(xy) <- c('x', 'y')
	proj4string(xy) <- crs
	spdf <- SpatialPointsDataFrame(coords = xy, data = df, proj4string = crs)
	return(spdf)
}

path <- '/gpfs/projects/gavingrp/dongmeic/beetle/output/tables/test5/'
file <- 'coefficients.csv'
coeff <- read.csv(paste0(path, file), stringsAsFactors=FALSE)
squares <- grep('_sq', coeff$predictor, value=TRUE)
cubes <- grep('_cub', coeff$predictor, value=TRUE)
interactions <- grep(':', coeff$predictor, value=TRUE)
singles <- coeff$predictor[!(coeff$predictor %in% c(squares, cubes, interactions))]
ignore <- c('btl_t', 'x', 'y','year')

preds <- get.input(1998)

#var <- '^Tmean|:Tmean'

pred.y <- get.pred.y(preds, 'wd')

probmapping.var <- function(pred.y){
	plotvar <- pred.y
	class <- classIntervals(plotvar, nclr, style="kmeans", dataPrecision=3)
	colcode <- findColours(class, plotclr)
	png(paste0("prob_",var,'_',year,"_test.png"), width=6, height=5, units="in", res=300)
	par(mfrow=c(1,1),mar=c(0.5,0,1.5,0))
	plot(loc.spdf, col=colcode, main=paste("Beetle probability predicted in", year, 'by variable', var), pch=19, cex=0.1)
	plot(canada.prov, col=rgb(0.7,0.7,0.7,0.7), add=T)
	plot(us.states, col=rgb(0.7,0.7,0.7,0.7), add=T)
	plot(lrglakes, border=rgb(0,0,0.3,0.1),add=T)
	legend('left',legend=names(attr(colcode, "table")),
					 fill=attr(colcode, "palette"), cex=1.2, title='Probability', bty="n")
	dev.off()
}

probmapping.var(pred.y)

probmapping.var.ts <- function(var){
	png(paste0('beelte_probability_predicted_by_',var,".png"), width=18, height=12, units="in", res=300)
	par(mfrow=c(3,6),mar=c(0.5,0,1.5,0))
	for (year in 1998:2015){
		preds <- get.input(year)
		pred.y <- get.pred.y(preds, var)
		plotvar <- pred.y
		class <- classIntervals(plotvar, nclr, style="kmeans", dataPrecision=3)
		colcode <- findColours(class, plotclr)
		spdf <- get.spdf.btl(year)
		spdf1 <- spdf[spdf$btl_t==1,]
		plot(loc.spdf, col=colcode, pch=19, cex=0.1)
		title(main=year, adj = 0.5, line = -1, cex.main=2)
		plot(spdf1, pch=19, cex=0.1, col=rgb(0,0,1,0.1),add=T)
		legend(-2750000, 550000,legend=names(attr(colcode, "table")),
						 fill=attr(colcode, "palette"), title='', bty="n", cex=0.8)
		print(year)
	}	
	dev.off()
}

probmapping.var.ts('ddAugJun')