# Created by Dongmei Chen
# Plot and map the impacts of predictors on the beetle probability
# tested on an interactive mode

library(ncdf4)
library(lattice)
library(rgdal)
library(raster)
library(rasterVis)
library(latticeExtra)
library(gridExtra)
library(RColorBrewer)
library(animation)
#install.packages("classInt", repos='http://cran.us.r-project.org')
library(classInt)
years <- 1998:2015

DATA_DIR <- '/gpfs/projects/gavingrp/dongmeic/beetle/output/tables/Xy_internal_split_data'
setwd('/gpfs/projects/gavingrp/dongmeic/beetle/output/plots/glm')
# merge all data tables
merge.files <- function() {
  set=c('train', 'valid', 'test')
  dt <- data.frame()
  for (j in 1:3){
		cat(sprintf('Merging %s data...\n', set[j]))
		all.files <- list.files(DATA_DIR)
		X.files <- sort(all.files[grepl(paste('X', set[j], sep='_'), all.files)])
		y.files <- sort(all.files[grepl(paste('y', set[j], sep='_'), all.files)])
		X <- read.csv(paste(DATA_DIR, X.files[1], sep='/'))
		y <- read.csv(paste(DATA_DIR, y.files[1], sep='/'))
		data <- cbind(y, X)
		if (length(X.files) > 1) {
			for (i in 2:length(X.files)) {
				next.X <- read.csv(paste(DATA_DIR, X.files[i], sep='/'))
				next.y <- read.csv(paste(DATA_DIR, y.files[i], sep='/'))
				next.data <- cbind(next.y, next.X)
				data <- rbind(data, next.data)
			}
		}
		dt <- rbind(dt, data)
  }
  dt
}

# calculate values for predictors
data <- merge.files()
ignore <- c('btl_t', 'x', 'y','year')
predictors <- data[,-which(colnames(data) %in% ignore)]
# predictors in the model
# c('sum9_t1', 'vgt', 'sum9_t2', 'winterTmin_sq', 'btl_t2', 'btl_t1', 'ddAugJul', 'density:TOctSep', 
#	'fallTmean_sq', 'OctTmin', 'fallTmean:summerP1', 'lat:etopo1', 'age', 'PMarAug_sq', 'AugTmax:summerP1',
#	'density:AugTmax', 'lon_sq', 'fallTmean:Tmean', 'density:OctTmin', 'lon', 'JanTmin:PPT', 'MarTmin:TOctSep')

# the selected model
singles <- c('sum9_t1', 'vgt', 'sum9_t2', 'btl_t2', 'btl_t1', 'ddAugJul', 'OctTmin', 'age', 'lon',
					   'winterTmin', 'fallTmean', 'PMarAug', 'density', 'TOctSep', 'summerP1', 'lat', 'etopo1',
					   'AugTmax', 'Tmean', 'OctTmin', 'JanTmin', 'PPT', 'MarTmin')
squares <- c('winterTmin_sq', 'fallTmean_sq', 'PMarAug_sq', 'lon_sq')
interactions <- c('density:TOctSep', 'fallTmean:summerP1', 'lat:etopo1', 'AugTmax:summerP1', 
									'density:AugTmax', 'fallTmean:Tmean', 'density:OctTmin', 'JanTmin:PPT', 'MarTmin:TOctSep')
preds <- predictors[,singles]
preds <- preds[!is.na(preds$density),]
for (i in 1:length(squares)){
	var <- strsplit(squares[i], "_")[[1]][1]
	preds[,squares[i]] <- (preds[,var])^2
	cat(sprintf('Calculated %s ...\n', squares[i]))
}

for( i in 1:length(interactions)){
	var <- gsub(":", "_", interactions[i])
	v1 <- strsplit(interactions[i], ":")[[1]][1]; v2 <- strsplit(interactions[i], ":")[[1]][2]
	preds[,var] <- preds[,v1] * preds[,v2]
	cat(sprintf('Calculated %s ...\n', interactions[i]))
}
selected <- c('sum9_t1','vgt','sum9_t2','winterTmin_sq','btl_t2','btl_t1','ddAugJul','density_TOctSep',
							'fallTmean_sq','OctTmin','fallTmean_summerP1','lat_etopo1','age','PMarAug_sq','AugTmax_summerP1',
							'density_AugTmax','lon_sq','fallTmean_Tmean','density_OctTmin','lon','JanTmin_PPT','MarTmin_TOctSep')
preds_1 <- preds[,selected]
renames <- c('sum9_t1','vgt','sum9_t2','winterTmin_sq','btl_t2','btl_t1','ddAugJul','density:TOctSep',
							'fallTmean_sq','OctTmin','fallTmean:summerP1','lat:etopo1','age','PMarAug_sq','AugTmax:summerP1',
							'density:AugTmax','lon_sq','fallTmean:Tmean','density:OctTmin','lon','JanTmin:PPT','MarTmin:TOctSep')
colnames(preds_1) <- renames; head(preds_1)
# rescale the data
preds_1 <- scale(preds_1);head(preds_1)
# get the median values for each predictors
median <- apply(preds_1, 2, median)
medians <- data.frame(predictor=names(median), median=as.numeric(median), stringsAsFactors = FALSE)
coefficients <- read.csv("/gpfs/projects/gavingrp/dongmeic/beetle/output/tables/coefficients.csv", stringsAsFactors = FALSE)
coeffs <- coefficients[abs(coefficients$coef) > 0,]
# double check the predictor matches
all(coeffs$predictor == medians$predictor)
coeffs$cons <- coeffs$coef * medians$median; coeffs$cons
# use one year data
#data2 <- read.csv("/gpfs/projects/gavingrp/dongmeic/beetle/output/tables/input_data_2009.csv", stringsAsFactors = FALSE)
#data1 <- data[data$year==2008,]

shppath <- "/gpfs/projects/gavingrp/dongmeic/beetle/shapefiles"
canada.prov <- readOGR(dsn = shppath, layer = "na10km_can_prov")
us.states <- readOGR(dsn = shppath, layer = "na10km_us_state")
crs <- proj4string(us.states)
lrglakes <- readOGR(dsn = shppath, layer = "na10km_lrglakes")
proj4string(lrglakes) <- crs
lonlat <- CRS("+proj=longlat +datum=NAD83")

nclr <- 5
color <- "RdYlGn"
plotclr <- rev(brewer.pal(nclr,color))
vars <- c('winterTmin', 'ddAugJul', 'fallTmean', 'age', 'density', 'summerP1', 'AugTmax', 'OctTmin', 'TOctSep', 'PMarAug')
varnames <- c('Minimum winter temperature', 'Day degrees', 'Mean temperature in the Fall', 'Stand age', 'Tree density',
							'Summer precipitation', 'Maximum August temperature', 'Minimum October temperature', 
							'Water-year mean temperature', 'Precipitation from March to August')
							
probmapping <- function(var,year){
	plotvar <- prob.df2[,var]
	class <- classIntervals(plotvar, nclr, style="kmeans", dataPrecision=2)
	colcode <- findColours(class, plotclr)
	png(paste0(var,"_",year,"_map.png"), width=7, height=5, units="in", res=300)
	par(mfrow=c(1,1),mar=c(0.5,8,1.5,0))
	plot(spdf, col=colcode, main=paste("Beetle probability predicted in", year), pch=19, cex=0.1)
	plot(spdf1, pch=19, cex=0.1, col=rgb(0,0,1,0.1),add=T)
	#plot(canada.prov, col=rgb(0.7,0.7,0.7,0.7), add=T)
	#plot(us.states, col=rgb(0.7,0.7,0.7,0.7), add=T)
	#plot(lrglakes, border=rgb(0,0,0.3,0.1),add=T)
	legend.title <- paste("By", var)
	legend(-3500000, 1050000,legend=names(attr(colcode, "table")),
					 fill=attr(colcode, "palette"), cex=1.2, title=legend.title, bty="n")
	dev.off()
}

probplotting <- function(var){
		x <- data1[,var]
		y1 <- prob.df[,var]
		png(paste0(var,"_plot.png"), width=6, height=5, units="in", res=300)
		par(mfrow=c(1,1),mar=c(4.5,4.5,1,1))
		plot(x, y1, xlab=varnames[which(vars==var)], ylab="Beetle probability", pch=19, cex=0.5)
		dev.off()
}

prob.plt.scaled <- function(var){
		x <- xdf[,var]
		y1 <- prob.df[,var]
		png(paste0(var,"_x-scaled.png"), width=6, height=5, units="in", res=300)
		par(mfrow=c(1,1),mar=c(4.5,4.5,1,1))
		plot(x, y1, xlab=varnames[which(vars==var)], ylab="Beetle probability", pch=19, cex=0.5)
		dev.off()
}

predicted <- function(
  sum9_t1=coeffs$cons[1],vgt=coeffs$cons[2],sum9_t2=coeffs$cons[3],winterTmin_sq=coeffs$cons[4],
  btl_t2=coeffs$cons[5],btl_t1=coeffs$cons[6],ddAugJul=coeffs$cons[7],density_TOctSep=coeffs$cons[8],
	fallTmean_sq=coeffs$cons[9],OctTmin=coeffs$cons[10],fallTmean_summerP1=coeffs$cons[11],
	lat_etopo1=coeffs$cons[12],age=coeffs$cons[13],PMarAug_sq=coeffs$cons[14],AugTmax_summerP1=coeffs$cons[15],
	density_AugTmax=coeffs$cons[16],lon_sq=coeffs$cons[17],fallTmean_Tmean=coeffs$cons[18],
	density_OctTmin=coeffs$cons[19],lon=coeffs$cons[20],JanTmin_PPT=coeffs$cons[21],MarTmin_TOctSep=coeffs$cons[22]){
  intercept <- -1.72935019
  pred.y <- intercept+sum9_t1+vgt+sum9_t2+winterTmin_sq+btl_t2+btl_t1+ddAugJul+density_TOctSep+fallTmean_sq+OctTmin+
  					fallTmean_summerP1+lat_etopo1+age+PMarAug_sq+AugTmax_summerP1+density_AugTmax+lon_sq+fallTmean_Tmean+
  					density_OctTmin+lon+JanTmin_PPT+MarTmin_TOctSep
  return(pred.y)	   
 }

# get y dataframe by year
get.y <- function(){
	# test on minimum winter temperature
	x <- data1$winterTmin
	y <- predicted(winterTmin_sq=coeffs$coef[4]*scale(x^2))
	y1 <- exp(y)/(1+exp(y))
	# ddAugJul
	x <- data1$ddAugJul
	y <- predicted(ddAugJul=coeffs$coef[7]*scale(x))
	y2 <- exp(y)/(1+exp(y))
	#hist(dt[dt$btl_t == 1,]$ddAugJul)
	# fallTmean
	x <- data1$fallTmean
	y <- predicted(fallTmean_sq=coeffs$coef[9]*scale(x^2),
								 fallTmean_summerP1=coeffs$coef[11]*scale(x*median(data1$summerP1,na.rm=T)),
								 fallTmean_Tmean=coeffs$coef[18]*scale(x*median(data1$Tmean,na.rm=T)))
	y3 <- exp(y)/(1+exp(y))
	#hist(dt[dt$btl_t == 1,]$fallTmean)
	# age
	x <- data1$age
	y <- predicted(age=coeffs$coef[13]*scale(x))
	y4 <- exp(y)/(1+exp(y))
	# density
	x <- data1$density
	y <- predicted(density_TOctSep=coeffs$coef[8]*scale(x*median(data1$TOctSep,na.rm=T)),
								 density_AugTmax=coeffs$coef[16]*scale(x*median(data1$AugTmax,na.rm=T)),
								 density_OctTmin=coeffs$coef[19]*scale(x*median(data1$OctTmin,na.rm=T)))
	y5 <- exp(y)/(1+exp(y))
	# summerP1
	x <- data1$summerP1
	y <- predicted(fallTmean_summerP1=coeffs$coef[11]*scale(x*median(data1$fallTmean,na.rm=T)),
								 AugTmax_summerP1=coeffs$coef[15]*scale(x*median(data1$AugTmax,na.rm=T)))
	y6 <- exp(y)/(1+exp(y))
	# AugTmax
	x <- data1$AugTmax
	y <- predicted(density_AugTmax=coeffs$coef[16]*scale(x*median(data1$density,na.rm=T)),
								 AugTmax_summerP1=coeffs$coef[15]*scale(x*median(data1$summerP1,na.rm=T)))
	y7 <- exp(y)/(1+exp(y))
	# OctTmin
	x <- data1$OctTmin
	y <- predicted(OctTmin=coeffs$coef[10]*scale(x),
								 density_OctTmin=coeffs$coef[19]*scale(x*median(data1$density,na.rm=T)))
	y8 <- exp(y)/(1+exp(y))
	# TOctSep
	x <- data1$TOctSep
	y <- predicted(density_TOctSep=coeffs$coef[8]*scale(x*median(data1$density,na.rm=T)),
								 MarTmin_TOctSep=coeffs$coef[22]*scale(x*median(data1$MarTmin,na.rm=T)))
	y9 <- exp(y)/(1+exp(y))
	#PMarAug
	x <- data1$PMarAug
	y <- predicted(PMarAug_sq=coeffs$coef[14]*scale(x^2))
	y10 <- exp(y)/(1+exp(y))
	prob.df <- data.frame(cbind(y1,y2,y3,y4,y5,y6,y7,y8,y9,y10))
	colnames(prob.df) <- vars
	return(prob.df)
}

get.yy <- function(){
	# test on minimum winter temperature
	x <- data1$winterTmin
	y <- predicted(vgt=coeffs$coef[2]*scale(data1$vgt),
								lat_etopo1=coeffs$coef[12]*scale(data1$lat*data1$etopo1),
								lon_sq=coeffs$coef[17]*scale(data1$lon^2),
								lon=coeffs$coef[20]*scale(data1$lon),
								winterTmin_sq=coeffs$coef[4]*scale(x^2))
	y1 <- exp(y)/(1+exp(y))
	# ddAugJul
	x <- data1$ddAugJul
	y <- predicted(vgt=coeffs$coef[2]*scale(data1$vgt),
								lat_etopo1=coeffs$coef[12]*scale(data1$lat*data1$etopo1),
								lon_sq=coeffs$coef[17]*scale(data1$lon^2),
								lon=coeffs$coef[20]*scale(data1$lon),
								ddAugJul=coeffs$coef[7]*scale(x))
	y2 <- exp(y)/(1+exp(y))
	#hist(dt[dt$btl_t == 1,]$ddAugJul)
	# fallTmean
	x <- data1$fallTmean
	y <- predicted(vgt=coeffs$coef[2]*scale(data1$vgt),
								lat_etopo1=coeffs$coef[12]*scale(data1$lat*data1$etopo1),
								lon_sq=coeffs$coef[17]*scale(data1$lon^2),
								lon=coeffs$coef[20]*scale(data1$lon),
								fallTmean_sq=coeffs$coef[9]*scale(x^2),
								fallTmean_summerP1=coeffs$coef[11]*scale(x*median(data1$summerP1,na.rm=T)),
								fallTmean_Tmean=coeffs$coef[18]*scale(x*median(data1$Tmean,na.rm=T)))
	y3 <- exp(y)/(1+exp(y))
	#hist(dt[dt$btl_t == 1,]$fallTmean)
	# age
	x <- data1$age
	y <- predicted(vgt=coeffs$coef[2]*scale(data1$vgt),
								lat_etopo1=coeffs$coef[12]*scale(data1$lat*data1$etopo1),
								lon_sq=coeffs$coef[17]*scale(data1$lon^2),
								lon=coeffs$coef[20]*scale(data1$lon),
								age=coeffs$coef[13]*scale(x))
	y4 <- exp(y)/(1+exp(y))
	# density
	x <- data1$density
	y <- predicted(vgt=coeffs$coef[2]*scale(data1$vgt),
								lat_etopo1=coeffs$coef[12]*scale(data1$lat*data1$etopo1),
								lon_sq=coeffs$coef[17]*scale(data1$lon^2),
								lon=coeffs$coef[20]*scale(data1$lon),
								density_TOctSep=coeffs$coef[8]*scale(x*median(data1$TOctSep,na.rm=T)),
								density_AugTmax=coeffs$coef[16]*scale(x*median(data1$AugTmax,na.rm=T)),
								density_OctTmin=coeffs$coef[19]*scale(x*median(data1$OctTmin,na.rm=T)))
	y5 <- exp(y)/(1+exp(y))
	# summerP1
	x <- data1$summerP1
	y <- predicted(vgt=coeffs$coef[2]*scale(data1$vgt),
								lat_etopo1=coeffs$coef[12]*scale(data1$lat*data1$etopo1),
								lon_sq=coeffs$coef[17]*scale(data1$lon^2),
								lon=coeffs$coef[20]*scale(data1$lon),
								fallTmean_summerP1=coeffs$coef[11]*scale(x*median(data1$fallTmean,na.rm=T)),
								AugTmax_summerP1=coeffs$coef[15]*scale(x*median(data1$AugTmax,na.rm=T)))
	y6 <- exp(y)/(1+exp(y))
	# AugTmax
	x <- data1$AugTmax
	y <- predicted(vgt=coeffs$coef[2]*scale(data1$vgt),
								lat_etopo1=coeffs$coef[12]*scale(data1$lat*data1$etopo1),
								lon_sq=coeffs$coef[17]*scale(data1$lon^2),
								lon=coeffs$coef[20]*scale(data1$lon),
								density_AugTmax=coeffs$coef[16]*scale(x*median(data1$density,na.rm=T)),
								AugTmax_summerP1=coeffs$coef[15]*scale(x*median(data1$summerP1,na.rm=T)))
	y7 <- exp(y)/(1+exp(y))
	# OctTmin
	x <- data1$OctTmin
	y <- predicted(vgt=coeffs$coef[2]*scale(data1$vgt),
								lat_etopo1=coeffs$coef[12]*scale(data1$lat*data1$etopo1),
								lon_sq=coeffs$coef[17]*scale(data1$lon^2),
								lon=coeffs$coef[20]*scale(data1$lon),
								OctTmin=coeffs$coef[10]*scale(x),
								density_OctTmin=coeffs$coef[19]*scale(x*median(data1$density,na.rm=T)))
	y8 <- exp(y)/(1+exp(y))
	# TOctSep
	x <- data1$TOctSep
	y <- predicted(vgt=coeffs$coef[2]*scale(data1$vgt),
								lat_etopo1=coeffs$coef[12]*scale(data1$lat*data1$etopo1),
								lon_sq=coeffs$coef[17]*scale(data1$lon^2),
								lon=coeffs$coef[20]*scale(data1$lon),
								density_TOctSep=coeffs$coef[8]*scale(x*median(data1$density,na.rm=T)),
								MarTmin_TOctSep=coeffs$coef[22]*scale(x*median(data1$MarTmin,na.rm=T)))
	y9 <- exp(y)/(1+exp(y))
	#PMarAug
	x <- data1$PMarAug
	y <- predicted(vgt=coeffs$coef[2]*scale(data1$vgt),
								lat_etopo1=coeffs$coef[12]*scale(data1$lat*data1$etopo1),
								lon_sq=coeffs$coef[17]*scale(data1$lon^2),
								lon=coeffs$coef[20]*scale(data1$lon),
								PMarAug_sq=coeffs$coef[14]*scale(x^2))
	y10 <- exp(y)/(1+exp(y))
	prob.df <- data.frame(cbind(y1,y2,y3,y4,y5,y6,y7,y8,y9,y10))
	colnames(prob.df) <- vars
	return(prob.df)
}

get.spdf <- function(){
		df <- data1
		xy <- data.frame(df[,c(4,5)])
		coordinates(xy) <- c('lon', 'lat')
		proj4string(xy) <- lonlat
		spdf <- SpatialPointsDataFrame(coords = xy, data = df, proj4string = lonlat)
		spdf <- spTransform(spdf, crs)
		return(spdf)
}

# make plots and maps
for (yr in 1:length(years)){
	data1 <- data[data$year==years[yr],]
	prob.df <- get.y()
	prob.df2 <- get.yy()
	spdf <- get.spdf()
	spdf1 <- spdf[spdf$btl_t==1,]
	xdf <- scale(data1[,vars])
	for(i in 1:length(vars)){
		if (yr==which(years==2008)){
			probplotting(vars[i])
			prob.plt.scaled(vars[i])	
		}
		probmapping(vars[i], years[yr])		
		cat(sprintf('Completed %s in %s...\n', vars[i], years[yr]))
	}
	print(paste("Year", years[yr], "is done!"))
}

for(i in 1:length(vars)){
	im.convert(paste0(vars[i],"_*_map.png"),output=paste0(vars[i],"_maps.gif"))
}
print("all done!")
