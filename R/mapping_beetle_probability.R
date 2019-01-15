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

xy <- data.frame(loc[,c(1,2)])
coordinates(xy) <- c('x', 'y')
proj4string(xy) <- crs
loc.spdf <- SpatialPointsDataFrame(coords = xy, data = loc, proj4string = crs)

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

path <- '/gpfs/projects/gavingrp/dongmeic/beetle/output/tables/test/'
prob2 <- read.csv(paste0(path, file))
probmapping_ts(prob2, "model_with_only_bioclm")


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

get.input <- function(year){
	input <- read.csv(paste0('/gpfs/projects/gavingrp/dongmeic/beetle/output/tables/input/input_data_',year,'.csv'))
	predictors <- input[,-which(colnames(input) %in% ignore)]
	preds <- predictors[,singles] 
	# calculate squares
	for (i in 1:length(squares)){
		var <- strsplit(squares[i], "_sq")[[1]][1]
		preds[,squares[i]] <- (preds[,var])^2
		cat(sprintf('Calculated %s ...\n', squares[i]))
	}
	# calculate cubes
	for (i in 1:length(cubes)){
		var <- strsplit(cubes[i], "_cub")[[1]][1]
		preds[,cubes[i]] <- (preds[,var])^3
		cat(sprintf('Calculated %s ...\n', cubes[i]))
	}
	# calculate interactions
	for( i in 1:length(interactions)){
		v1 <- strsplit(interactions[i], ":")[[1]][1]; v2 <- strsplit(interactions[i], ":")[[1]][2]
		preds[,interactions[i]] <- preds[,v1] * preds[,v2]
		cat(sprintf('Calculated %s ...\n', interactions[i]))
	}	
	return(preds)
}

preds <- get.input(1998)

SQUARE = c('Tmin', 'mi', 'lat', 'vpd', 'PcumOctSep', 'summerP0', 'ddAugJul',
					'AugMaxT', 'cwd', 'age', 'maxT', 'PPT', 'Acs', 'wd', 'MarMin',
          'summerP0', 'OctTmin', 'summerP1', 'OctMin', 'ddAugJun', 'JanTmin',
          'summerP2', 'max.drop', 'Pmean', 'PMarAug', 'etopo1', 'POctSep',
          'Mar20', 'sum9_diff')
CUBE = c('MarTmin', 'fallTmean', 'Tvar', 'JanMin', 'age', 'density', 'lon',
        'TOctSep', 'OptTsum', 'minT', 'AugTmax', 'AugTmean', 'lat', 'Tmean',
        'winterMin', 'TMarAug', 'summerTmean', 'Jan20', 'sum9_diff')

#var <- '^Tmean|:Tmean'

get.pred.y <- function(preds, var){
	if(var %in% c('Tmean', 'Tmin', 'mi', 'wd')){
		selected <- grep(paste0('^', var, '|:', var), coeff$predictor, value=TRUE)
		if(var == 'mi'){
			selected <- c('lat:mi', 'mi', 'lon:mi', 'etopo1:mi', 'mi_sq')
		}
	}else{
		selected <- grep(var, coeff$predictor, value=TRUE)
	}
	print(selected)
	
	loc_variables <- grep('^lon|^lat|^etopo1', coeff$predictor, value=TRUE)	
	preds_1 <- scale(preds[,colnames(preds)[!(colnames(preds) %in% selected)]])
	#preds_1 <- scale(preds[,colnames(preds)[!(colnames(preds) %in% c(selected,loc_variables))]])
	preds_2 <- scale(preds[,loc_variables])
	# get the median values for each predictors
	median <- apply(preds_1, 2, median)
	medians <- data.frame(predictor=names(median), median=as.numeric(median), stringsAsFactors = FALSE)
				
	intercept = -4.43337254; cons <- intercept
	for(i in 1:dim(medians)[1]){
		value <- coeff$coef[which(coeff$predictor==medians$predictor[i])] * medians$median[i]
		cons <- cons + value
		cat(sprintf('Calculated constant %s ...\n', medians$predictor[i]))
	}

	selected_coeffs <- coeff$coef[which(coeff$predictor %in% selected)]
	df <- data.frame(var=selected, coeff=selected_coeffs, stringsAsFactors = FALSE)
	lon.cons = df$coeff[grep('lon:', df$var)] * preds_2[,'lon']
	lat.cons = df$coeff[grep('lat:', df$var)] * preds_2[,'lat']
	etopo1.cons = df$coeff[grep('etopo1:', df$var)]  * preds_2[,'etopo1']
	x <- scale(preds[,var])[,1]
	
	if(length(selected)==5 & var %in% SQUARE){
		y <- cons + lon.cons * x + lat.cons * x + etopo1.cons * x + df$coeff[grep('_sq', df$var)] * x * x + df$coeff[which(df$var==var)] * x
	}else if(length(selected)==5 & var %in% CUBE){
		y <- cons + lon.cons * x + lat.cons * x + etopo1.cons * x + df$coeff[grep('_cub', df$var)] * x * x * x + df$coeff[which(df$var==var)] * x	
	}else if(length(selected)==5 & var %in% CUBE & var %in% SQUARE){
		y <- cons + lon.cons * x + lat.cons * x + etopo1.cons * x + df$coeff[grep('_sq', df$var)] * x * x + df$coeff[grep('_cub', df$var)] * x * x * x + df$coeff[which(df$var==var)] * x
	}else if(length(selected)==4){
		y <- cons + lon.cons * x + lat.cons * x + etopo1.cons * x + df$coeff[which(df$var==var)] * x
	}else{
		print('There is some mistake!')
	}
# 	preds_3 <- preds_2[,colSums(is.na(preds_2))<nrow(preds_2)]
# 	for(j in 1:dim(preds_3)[2]){
# 		y <- y + coeff$coef[which(coeff$predictor==colnames(preds_3)[j])] * preds_3[,j]
# 		print(summary(y))
# 		cat(sprintf('Added constant %s ...\n', colnames(preds_3)[j]))
# 	}
	pred.y <- exp(y)/(1+exp(y))
	print(summary(pred.y))
	return(pred.y)
}

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