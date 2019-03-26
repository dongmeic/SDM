library(rgdal)
library(RColorBrewer)
library(classInt)
library(ggplot2)
library(raster)
library(ncdf4)
library(mgcv)

path <- '/gpfs/projects/gavingrp/dongmeic/beetle/output/tables/'
out <- '/gpfs/projects/gavingrp/dongmeic/beetle/output/plots/'

year <- 2009
train <- read.csv(paste0(path, 'input/X_train_', year, '.csv'))
valid <- read.csv(paste0(path, 'input/X_valid_', year, '.csv'))
test <- read.csv(paste0(path, 'input/X_test_', year, '.csv'))

btlprs <- read.csv(paste0(path, "beetle_presence_updated.csv"))
tree <- read.csv(paste0(path, "stand_age_density.csv"))
loc <- read.csv(paste0(path,"location.csv"))
bd <- btlprs[btlprs$allyears==1,]
loc.bd <- loc[loc$lon >= range(bd$lon)[1] & loc$lon <= range(bd$lon)[2] & loc$lat >= range(bd$lat)[1] & loc$lat <= range(bd$lat)[2],]
x.min <- min(loc.bd$x); y.min <- min(loc.bd$y); x.max <- max(loc.bd$x); y.max <- max(loc.bd$y)

var <- 'Acs'
inpath <- "/gpfs/projects/gavingrp/dongmeic/beetle/ncfiles/na10km_v2/ts/var/"
years <- 1996:2015; nyr <- length(years)
ncfile <- paste0("daily/na10km_v2_daymet_na_",var, "_",years[1],".",years[nyr],".3d.nc")

r <- raster(paste0(inpath, ncfile), varname = var)
na10km.nc <- "/gpfs/projects/gavingrp/dongmeic/beetle/ncfiles/na10km_v2/na10km_v2.nc"
ncin <- nc_open(na10km.nc)
na10km.prj <- ncatt_get(ncin,"lambert_azimuthal_equal_area","CRS.PROJ.4")$value
na10km.pts.r <- raster(na10km.nc, varname = "etopo1")
proj4string(r) <- CRS(na10km.prj)
rmean <- calc(r, mean)

dt <- cbind(loc, btlprs[,"allyears"], tree[, c("age", "density")])
colnames(dt)[7] <- "beetle"
ndf <- dt[dt$lon >= range(bd$lon)[1] & dt$lon <= range(bd$lon)[2] & dt$lat >= range(bd$lat)[1] & dt$lat <= range(bd$lat)[2],]

shppath <- "/gpfs/projects/gavingrp/dongmeic/beetle/shapefiles"
canada.prov <- readOGR(dsn = shppath, layer = "na10km_can_prov")
us.states <- readOGR(dsn = shppath, layer = "na10km_us_state")
crs <- proj4string(us.states)
lrglakes <- readOGR(dsn = shppath, layer = "na10km_lrglakes")
proj4string(lrglakes) <- crs

get.spdf <- function(df){
	xy <- data.frame(df[,c(1,2)])
	coordinates(xy) <- c('x', 'y')
	proj4string(xy) <- crs
	spdf <- SpatialPointsDataFrame(coords = xy, data = df, proj4string = crs)
	return(spdf)
}

train.spdf <- get.spdf(train)
valid.spdf <- get.spdf(valid)
test.spdf <- get.spdf(test)

spdf <- get.spdf(ndf)
age <- rasterize(spdf, na10km.pts.r, 'age', fun=mean, na.rm=TRUE)
proj4string(age) <- CRS(na10km.prj)
density <- rasterize(spdf, na10km.pts.r, 'density', fun=mean, na.rm=TRUE)
proj4string(density) <- CRS(na10km.prj)

# Figure 1 - study extent and sampling blocks
png(paste0(out, 'sampling.png'), width=9, height=5, units="in", res=300)
par(mfrow=c(1,3),mar=c(0.5,0.5,1.5,0))
plot(train.spdf, col='darkgrey', main='Training', pch=19, cex=0.1, cex.main=1.5)
plot(canada.prov, col=rgb(0,0,0,0.9), add=T)
plot(us.states, col=rgb(0,0,0,0.9), add=T)
plot(valid.spdf, col='darkgrey', main='Validation', pch=19, cex=0.1, cex.main=1.5)
plot(canada.prov, col=rgb(0.7,0.7,0.7,0.7), add=T)
plot(us.states, col=rgb(0.7,0.7,0.7,0.7), add=T)
plot(test.spdf, col='darkgrey', main='Test', pch=19, cex=0.1, cex.main=1.5)
plot(canada.prov, col=rgb(0.7,0.7,0.7,0.7), add=T)
plot(us.states, col=rgb(0.7,0.7,0.7,0.7), add=T)
dev.off()

# modify Figure 1 with more maps
png(paste0(out, 'sampling_2.png'), width=9, height=10, units="in", res=300)
par(mfrow=c(2,3),mar=c(0.5,0.5,1.5,0))
cutpts <- c(0,2,4,6,8,10,20,40,60,90)
plot(rmean, xlim=c(-2050000,20000), ylim=c(-2000000,1600000), breaks=cutpts, legend = FALSE,
		 main='Average duration of cold snaps', col=brewer.pal(9,"GnBu"), axes = FALSE, box = FALSE)
plot(spdf[spdf$beetle==1,], cex=0.05, pch=19, col=rgb(1, 0, 0, 0.1), add=T)
plot(canada.prov, col=rgb(0,0,0,0.9), add=T)
plot(us.states, col=rgb(0,0,0,0.9), add=T)
cutpts <- c(0,40,80,100,150,200,400,600,705)
plot(age, xlim=c(-2050000,20000), ylim=c(-2000000,1600000), breaks=cutpts, legend = FALSE,
		 main='Stand age', col=brewer.pal(9,"GnBu"), axes = FALSE, box = FALSE)
plot(spdf[spdf$beetle==1,], cex=0.05, pch=19, col=rgb(1, 0, 0, 0.1), add=T)
plot(canada.prov, col=rgb(0,0,0,0.9), add=T)
plot(us.states, col=rgb(0,0,0,0.9), add=T)
cutpts <- c(0,3000,9000,15000,20000,60000,100000,200000,250000)
plot(density, xlim=c(-2050000,20000), ylim=c(-2000000,1600000), breaks=cutpts, legend = FALSE,
		 main='Tree density', col=brewer.pal(9,"GnBu"), axes = FALSE, box = FALSE)
plot(spdf[spdf$beetle==1,], cex=0.05, pch=19, col=rgb(1, 0, 0, 0.1), add=T)
plot(canada.prov, col=rgb(0,0,0,0.9), add=T)
plot(us.states, col=rgb(0,0,0,0.9), add=T)
plot(train.spdf, col='darkgrey', main='Training', pch=19, cex=0.1, cex.main=1.5)
plot(canada.prov, col=rgb(0,0,0,0.9), add=T)
plot(us.states, col=rgb(0,0,0,0.9), add=T)
plot(valid.spdf, col='darkgrey', main='Validation', pch=19, cex=0.1, cex.main=1.5)
plot(canada.prov, col=rgb(0.7,0.7,0.7,0.7), add=T)
plot(us.states, col=rgb(0.7,0.7,0.7,0.7), add=T)
plot(test.spdf, col='darkgrey', main='Test', pch=19, cex=0.1, cex.main=1.5)
plot(canada.prov, col=rgb(0.7,0.7,0.7,0.7), add=T)
plot(us.states, col=rgb(0.7,0.7,0.7,0.7), add=T)
dev.off()

# Figure 2 - ROC curves
roc.m1 <- read.csv(paste0(path, 'model1/roc.csv'))
roc.m2 <- read.csv(paste0(path, 'model2/roc.csv'))
roc.m3 <- read.csv(paste0(path, 'model3/roc.csv'))
roc.m4 <- read.csv(paste0(path, 'model4/roc.csv'))
roc.m5 <- read.csv(paste0(path, 'model5/roc.csv'))
lw = 3
png(paste0(out, 'roc_curve.png'), width=8, height=8, units="in", res=300)
par(mfrow=c(1,1),mar=c(5,5,1,1))
plot(roc.m1$fpr, roc.m1$tpr, lwd=lw, type='l', xlab='False positive rate (1 - Specificity)',
		 ylab='True positive rate (Sensitivity)', , col='blue', cex.lab=1.5, cex.axis=1.5)
lines(roc.m2$fpr, roc.m2$tpr, lwd=lw, type='l', col='red')
lines(roc.m3$fpr, roc.m3$tpr, lwd=lw, type='l')
lines(roc.m4$fpr, roc.m4$tpr, lwd=lw, type='l', col=rgb(0,1,0,0.5))
#lines(roc.m5$fpr, roc.m5$tpr, lwd=lw, type='l', col=rgb(0,0.5,0,0.5))
lines(c(0,1), c(0,1), col='darkgrey',lwd=lw, type='l')
legend(0.7, 0.3, legend=c('Model 1', 'Model 2', 'Model 3', 'Model 4'), cex=1.5,
			col=c('blue', 'red', 'black', 'green'), box.lty=0, lty=1, lwd=lw)
dev.off()

# Figure 3 - model predictions
path <- '/gpfs/projects/gavingrp/dongmeic/beetle/output/tables/'
setwd('/gpfs/projects/gavingrp/dongmeic/beetle/output/maps/prob')
file <- 'predictions.csv'
shppath <- "/gpfs/projects/gavingrp/dongmeic/beetle/shapefiles"
canada.prov <- readOGR(dsn = shppath, layer = "na10km_can_prov")
us.states <- readOGR(dsn = shppath, layer = "na10km_us_state")
crs <- proj4string(us.states)
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
nclr <- 5
color <- "GnBu"
plotclr <- brewer.pal(nclr,color)
png('beelte_probability.png', width=15, height=16, units="in", res=300)
par(mfrow=c(4,5),mar=c(0.5,0,1.5,0))
for(i in c(1:3,5)){
	for (year in seq(1998,2015,4)){
		spdf <- get.spdf(i, year)
		plotvar <- spdf$probs
		class <- classIntervals(plotvar, nclr, style="fixed", fixedBreaks=c(0.01, 0.08, 0.22, 0.38, 0.56, 0.99))
		colcode <- findColours(class, plotclr)
		spdf1 <- spdf[spdf$btl_t==1,]
		plot(spdf, col=colcode, pch=19, cex=0.1)
		if(i==5){
			title(main=paste0('Model ', i-1, ': ' ,year), adj = 0.5, line = -1, cex.main=2)
		}else{
			title(main=paste0('Model ', i, ': ' ,year), adj = 0.5, line = -1, cex.main=2)
		}
		plot(spdf1, pch=19, cex=0.05, col=rgb(1,0,0,0.25),add=T)
		if(i==5 & year==2014){
			legend(-2700000, 550000,legend=names(attr(colcode, "table")),
						 fill=attr(colcode, "palette"), title='', bty="n")		
		}
		print(year)
	}
	print(i)
}
dev.off()

# Figure 4 - bioclimatic variables and beetle probability
# variables - TMarAug, AugTmean, Tmean, JanTmin, vpd, Jan20, maxAugT, cwd, minT, 
# JanMin, fallTmean, summerTmean, Acs, mi, OctMin, PMarAug, OctTmin, Tvar
source('/gpfs/projects/gavingrp/dongmeic/sdm/R/model_output_functions.R')
train <- merge.files('train')

i <- 5
model <- paste0('model', i)

coeff <- read.csv(paste0(path, model,'/coefficients.csv'), stringsAsFactors = FALSE)
if(i==1){
	ndf <- train[,-which(colnames(train) %in% c("x", "y", "x.new", "y.new", "xy"))]
}else{		
	squares <- grep('_sq', coeff$predictor, value=TRUE)
	cubes <- grep('_cub', coeff$predictor, value=TRUE)
	interactions <- grep(':', coeff$predictor, value=TRUE)
	singles <- coeff$predictor[!(coeff$predictor %in% c(squares, cubes, interactions))]
	ndf <- get.data.frame(train)	
}

#ndf <- get.data.frame(train)
if(i==1){
	drops <- c('summerP2')
}else if(i==2){
	drops <- c('summerP1', 'lat:summerP1', 'lon:summerP1', 'etopo1:summerP2')
}else if(i==3){
	drops <- c('sum9_t1', 'summerP2', 'lon:summerP1', 'lat:summerP0', 'etopo1:summerP2')
}else{
	drops <- c('sum9_t1', 'summerP2', 'lon:summerP1', 'lat:summerP0', 'etopo1:summerP1', 'density:summerP1')
}
#strings <- gsub(":", "_", capture.output(var.string(coeff, drops)))
strings <- capture.output(var.string(coeff, drops))
mod.string <- paste0('glm(btl_t ~ ', strings, ', data=ndf, family=binomial())')
ptm <- proc.time()
mod <- eval(parse(text=mod.string))
proc.time() - ptm

vars <- c('TMarAug','Tmean','Tvar','ddAugJul','AugTmean','maxAugT','summerTmean','OptTsum',
					'JanTmin', 'Jan20', 'Acs', 'minT','summerP0', 'vpd', 'cwd', 'wd')
varnms <- c('Growing season (Mar - Aug) temperature', 'Annual mean temperature', 'Seasonal temperature variation',
						'Degree days from Aug to Jul', 'Mean August temperature', 'Frequency of ≥ 18.3 °C temperature in Aug',
						'Mean summer temperature', 'Days with optimum summer temperatures', 
						'January minimum temperature', 'Days with a ≤-20 °C temperature in Jan','Average duration of cold snaps', 
						'Minimum daily temperature (Aug-Jul)', 'Summer precipitation', 'Vapor pressure deficit', 
						'Cumulative climatic water deficit', 'Water deficit')

n.sample <- 15000
s.df <- ndf[sample(nrow(ndf), n.sample),]
s.df <- s.df[complete.cases(s.df), ]
y <- predict(mod, s.df, type="response")
fs <- c(0.4, rep(0.3, 14), 0.1)

png(paste0(out,'variable_2Dplot_',i,'.png'), width=14, height=12, units="in", res=300)
par(mfrow=c(4,4),mar=c(3.5,3.5,2,1))
for(var in vars){
	df <- data.frame(x=s.df[,var], y=y)
	df <- df[order(df$x),]
	#add.CI.lines(df$x, df$y, f=fs[which(vars==var)])
	plot(df$x, df$y, pch=16, cex=0.35, col=rgb(0,0,0,0.5), main=varnms[which(vars==var)],
							xlab='',ylab='', cex.lab=1.5, cex.axis=1.5)
	lowessFit <-data.frame(lowess(df,f=fs[which(vars==var)],iter=1))
	lines(lowessFit,lwd=3, col=rgb(1,0,0,0.8))
	#lines(lowess(df$y ~ df$x), lwd=3, col=rgb(1,0,0,0.8))
	print(paste(var, 'is done!'))
}
dev.off()

add.CI.lines <- function(x, y, segments=50, f){
	x.ranges <- seq(min(x), max(x), length=segments + 1)
	x.no.lower.out <- c()
	x.no.upper.out <- c()
	y.no.lower.out <- c()
	y.no.upper.out <- c()
	for (seg in 1:segments) {
		xs <- x[x >= x.ranges[seg] & x < x.ranges[seg + 1]]
		ys <- y[x >= x.ranges[seg] & x < x.ranges[seg + 1]]
		upper <- quantile(ys, probs=0.9)
		lower <- quantile(ys, probs=0.1)
		y.no.upper <- ys[ys < upper]
		x.no.upper <- xs[ys < upper]
		y.no.lower <- ys[ys > lower]
		x.no.lower <- xs[ys > lower]
		#cat(length(x.no.lower), length(y.no.lower), '\n')
		x.no.lower.out <- c(x.no.lower.out, x.no.lower)
		x.no.upper.out <- c(x.no.upper.out, x.no.upper)
		y.no.lower.out <- c(y.no.lower.out, y.no.lower)
		y.no.upper.out <- c(y.no.upper.out, y.no.upper)
	}
	plot(y ~ x, pch=16, cex=0.35, col=rgb(0, 0, 0, 0.3))
	lines(lowess(y ~ x, f=f), col=2)
	lines(lowess(y.no.upper.out ~ x.no.upper.out), lwd=1.5, col=4, lty='dashed')
	lines(lowess(y.no.lower.out ~ x.no.lower.out), lwd=1.5, col=4, lty='dashed')
}

vars <- c('lon', 'lat', 'etopo1', 'age', 'density', 'age:density','density:Tmean', 
					'density:vpd', 'density:TMarAug', 'sum9_diff', 'age:sum9_diff', 'density:sum9_diff')
png(paste0(out,'density_2Dplot_',i,'.png'), width=15, height=16, units="in", res=300)
par(mfrow=c(4,3),mar=c(3.5,3.5,2,2))
for(var in vars){
	if(grepl(':', var)){
		split <- unlist(strsplit(var, ':'))
		x = s.df[,split[1]]*s.df[,split[2]]
		df <- data.frame(x=x, y=y)
	}else{
		df <- data.frame(x=s.df[,var], y=y)
	}
	df <- df[order(df$x),]
	lowessFit <-data.frame(lowess(df,f=0.5,iter=1))
	plot(df$x, df$y, pch=16, cex=0.35, col=rgb(0,0,0,0.5), main=var, cex.main=1.5,
				xlab='',ylab='', cex.lab=1.5, cex.axis=1.5)
	lines(lowessFit,lwd=3, col=rgb(1,0,0,0.8))
	print(paste(var, 'is done!'))
}
dev.off()

# Appendix Figure 1 - GAM plots
DATA_DIR <- '/gpfs/projects/gavingrp/dongmeic/beetle/output/tables/input'
setwd("/gpfs/projects/gavingrp/dongmeic/beetle/output/plots/gam")

merge.files <- function(set=c('train', 'valid', 'test')) {
  cat(sprintf('Merging %s data...\n', set))
  all.files <- list.files(DATA_DIR)
  X.files <- sort(all.files[grepl(paste('X', set, sep='_'), all.files)])
  y.files <- sort(all.files[grepl(paste('y', set, sep='_'), all.files)])
  X <- read.csv(paste(DATA_DIR, X.files[1], sep='/'))
  y <- read.csv(paste(DATA_DIR, y.files[1], sep='/'))
  colnames(y) <- 'btl_t'
  data <- cbind(y, X)
  if (length(X.files) > 1) {
    for (i in 2:length(X.files)) {
      next.X <- read.csv(paste(DATA_DIR, X.files[i], sep='/'))
      next.y <- read.csv(paste(DATA_DIR, y.files[i], sep='/'))
      colnames(next.y) <- 'btl_t'
      next.data <- cbind(next.y, next.X)
      data <- rbind(data, next.data)
    }
  }
  data
}

train <- merge.files('train')

cold0 <- c('Jan20','Mar20','Acs','max.drop')
nons <- c('vgt', 'btl_t1', 'btl_t2', 'sum9_t1', 'sum9_t2')
cold <- c('JanTmin', 'MarTmin', 'OctTmin', 'Tmin', 'OctMin', 'JanMin', 'MarMin', 'winterMin', 'minT') 
season <- c('TMarAug', 'fallTmean', 'Tmean', 'Tvar', 'TOctSep', 'ddAugJul', 'ddAugJun')
summerT <- c('summerTmean', 'AugTmean', 'AugTmax', 'maxAugT', 'OptTsum', 'AugMaxT', 'maxT')
drought <- c('PMarAug', 'summerP0', 'summerP1', 'summerP2', 'Pmean', 'POctSep', 'PcumOctSep', 'PPT')
drought1 <- c('wd', 'vpd', 'mi', 'cwd')
tree <- c('age', 'density')
loc <- c('lon', 'lat', 'etopo1')
beetle <- c('btl_t1', 'btl_t2', 'sum9_t1', 'sum9_t2', 'sum9_diff')

gam.sample <- function(n.sample,st) {
  random.preds <- c(sample(cold0, 1),sample(cold, 1),sample(season, 1),sample(summerT, 1),
                    sample(drought, 1),sample(drought1, 1))
  preds <- c(random.preds, tree, loc, beetle)
  var.string <- function(st){
    for (p in preds) {
      if(p %in% nons){
        cat(sprintf('+ %s ', p))
      }else{
        cat(sprintf('+ %s(%s) ', st, p))
      }
    } 
  }
  start <- Sys.time()
  mod.string <- paste0('gam(btl_t ~ ', capture.output(var.string(st)),'+ vgt, data=train[sample(nrow(train), n.sample),])')
  mod <- eval(parse(text=mod.string))
  stop <- Sys.time()
  cat('Elapsed time:', stop - start, 's\n')
  mod
}

gam.random <- function(iters){
  for (i in 1:iters) {
    cat(sprintf('Starting interation %d...\n', i))
    mod <- gam.sample(80000,'te')
    png(paste0('GAM_plot_', i,'.png'), width=12, height=16, units="in", res=300)
    par(mfrow=c(4, 3), mar=c(5,5,2,1))
    plot(mod, cex.lab=1.5, cex.axis=1.5,lwd=3) #rug=T, residuals = T
    dev.off()
  }
}

gam.random(50)