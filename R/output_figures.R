library(rgdal)
library(RColorBrewer)
library(classInt)
library(ggplot2)


path <- '/gpfs/projects/gavingrp/dongmeic/beetle/output/tables/'
out <- '/gpfs/projects/gavingrp/dongmeic/beetle/output/plots/'

year <- 2009
train <- read.csv(paste0(path, 'input/X_train_', year, '.csv'))
valid <- read.csv(paste0(path, 'input/X_valid_', year, '.csv'))
test <- read.csv(paste0(path, 'input/X_test_', year, '.csv'))

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

# Figure 1 - study extent and sampling blocks
png(paste0(out, 'sampling.png'), width=9, height=5, units="in", res=300)
par(mfrow=c(1,3),mar=c(0.5,0.5,1.5,0))
plot(train.spdf, col='darkgrey', main='Training', pch=19, cex=0.1, cex.main=1.5)
plot(canada.prov, col=rgb(0.7,0.7,0.7,0.7), add=T)
plot(us.states, col=rgb(0.7,0.7,0.7,0.7), add=T)
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
lw = 3
png(paste0(out, 'roc_curve.png'), width=8, height=8, units="in", res=300)
par(mfrow=c(1,1),mar=c(5,5,1,1))
plot(roc.m1$fpr, roc.m1$tpr, lwd=lw, type='l', xlab='False positive rate (1 - Specificity)',
		 ylab='True positive rate (Sensitivity)', , col='blue', cex.lab=1.5, cex.axis=1.5)
lines(roc.m2$fpr, roc.m2$tpr, lwd=lw, type='l', col='red')
lines(roc.m3$fpr, roc.m3$tpr, lwd=lw, type='l')
lines(roc.m4$fpr, roc.m4$tpr, lwd=lw, type='l', col=rgb(0,1,0,0.5))
lines(c(0,1), c(0,1), col='darkgrey',lwd=lw, type='l')
legend(0.7, 0.3, legend=c('Model 1', 'Model 2', 'Model 3', 'Model 4'), cex=1.5,
			col=c('blue', 'red', 'black', 'green'), box.lty=0, lty=1, lwd=lw)
dev.off()

# Figure 3 - model predictions
