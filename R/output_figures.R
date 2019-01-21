library(rgdal)
library(RColorBrewer)
library(classInt)

path <- '/gpfs/projects/gavingrp/dongmeic/beetle/output/tables/input/'
out <- '/gpfs/projects/gavingrp/dongmeic/beetle/output/plots/'

year <- 2009
train <- read.csv(paste0(path, 'X_train_', year, '.csv'))
valid <- read.csv(paste0(path, 'X_valid_', year, '.csv'))
test <- read.csv(paste0(path, 'X_test_', year, '.csv'))

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
plot(train.spdf, col='darkgrey', main='Training', pch=19, cex=0.1)
plot(canada.prov, col=rgb(0.7,0.7,0.7,0.7), add=T)
plot(us.states, col=rgb(0.7,0.7,0.7,0.7), add=T)
plot(valid.spdf, col='darkgrey', main='Validation', pch=19, cex=0.1)
plot(canada.prov, col=rgb(0.7,0.7,0.7,0.7), add=T)
plot(us.states, col=rgb(0.7,0.7,0.7,0.7), add=T)
plot(test.spdf, col='darkgrey', main='Test', pch=19, cex=0.1)
plot(canada.prov, col=rgb(0.7,0.7,0.7,0.7), add=T)
plot(us.states, col=rgb(0.7,0.7,0.7,0.7), add=T)
dev.off()

