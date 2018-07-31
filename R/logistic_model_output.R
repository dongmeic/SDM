# Created by Dongmei Chen
# Plot and map the impacts of predictors on the beetle probability
# run on an interactive mode

library(ncdf4)
library(lattice)
library(rgdal)
library(raster)
library(rasterVis)
library(latticeExtra)
library(gridExtra)
library(RColorBrewer)
library(animation)

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
#data1 <- read.csv("/gpfs/projects/gavingrp/dongmeic/beetle/output/tables/input_data_2009.csv", stringsAsFactors = FALSE)
data1 <- data[data$year==2009,]
# test on minimum winter temperature
x <- data1$winterTmin
y <- sum(coeffs$cons)-0.315128553*scale(x^2)-1.72935019-0.1069022594
y1 <- exp(y)/(1+exp(y))
png("winterTmin.png", width=6, height=5, units="in", res=300)
par(mfrow=c(1,1),mar=c(4.5,4.5,1,1))
plot(x, y1, xlab="Minimum winter temperature", ylab="Beetle probability", pch=19, cex=0.05)
dev.off()
# ddAugJul
x <- data1$ddAugJul
y <- sum(coeffs$cons)-0.195761379*scale(x)-1.72935019-0.0595355921
y1 <- exp(y)/(1+exp(y))
png("ddAugJul.png", width=6, height=5, units="in", res=300)
par(mfrow=c(1,1),mar=c(4.5,4.5,1,1))
plot(x, y1, xlab="Day degrees", ylab="Beetle probability", pch=19, cex=0.05)
dev.off()
dt <- cbind(data.frame(btl_t=data$btl_t), predictors[,singles])
hist(dt[dt$btl_t == 1,]$ddAugJul)
# fallTmean
x <- data1$fallTmean
y <- sum(coeffs$cons)-0.104098872*scale(x^2)-0.060015740*scale(x*median(data1$summerP1))-0.014053525*scale(x*median(data1$Tmean))-1.72935019-0.0377606870-0.0141800769-0.0051272637
y1 <- exp(y)/(1+exp(y))
png("fallTmean.png", width=6, height=5, units="in", res=300)
par(mfrow=c(1,1),mar=c(4.5,4.5,1,1))
plot(x, y1, xlab="Mean temperature in the Fall", ylab="Beetle probability", pch=19, cex=0.05)
dev.off()
hist(dt[dt$btl_t == 1,]$fallTmean)
# age
x <- data1$age
y <- sum(coeffs$cons)+0.050150919*scale(x)+0.0342156105-1.72935019
y1 <- exp(y)/(1+exp(y))
png("age.png", width=6, height=5, units="in", res=300)
par(mfrow=c(1,1),mar=c(4.5,4.5,1,1))
plot(x, y1, xlab="Stand age", ylab="Beetle probability", pch=19, cex=0.05)
dev.off()
# density
x <- data1$density
y <- sum(coeffs$cons)+0.114451743*scale(x*median(data1$TOctSep))+0.028270702*scale(x*median(data1$AugTmax))-0.009827704*scale(x*median(data1$OctTmin))+0.0346628659+0.0078639212+0.0018600826-1.72935019
y1 <- exp(y)/(1+exp(y))
png("density.png", width=6, height=5, units="in", res=300)
par(mfrow=c(1,1),mar=c(4.5,4.5,1,1))
plot(x, y1, xlab="Tree density", ylab="Beetle probability", pch=19, cex=0.05)
dev.off()
# summerP1
x <- data1$summerP1
y <- sum(coeffs$cons)-0.060015740*scale(x*median(data1$fallTmean))-0.034204228*scale(x*median(data1$AugTmax))-0.0141800769-0.0005781264-1.72935019
y1 <- exp(y)/(1+exp(y))
png("summerP1.png", width=6, height=5, units="in", res=300)
par(mfrow=c(1,1),mar=c(4.5,4.5,1,1))
plot(x, y1, xlab="Summer precipitation", ylab="Beetle probability", pch=19, cex=0.05)
dev.off()
# AugTmax
x <- data1$AugTmax
y <- sum(coeffs$cons)-0.034204228*scale(x*median(data1$summerP1))+0.028270702*scale(x*median(data1$density, na.rm=T))-0.0005781264+0.0078639212-1.72935019
y1 <- exp(y)/(1+exp(y))
png("AugTmax.png", width=6, height=5, units="in", res=300)
par(mfrow=c(1,1),mar=c(4.5,4.5,1,1))
plot(x, y1, xlab="Maximum August temperature", ylab="Beetle probability", pch=19, cex=0.05)
dev.off()
# OctTmin
x <- data1$OctTmin
y <- sum(coeffs$cons)-0.062630669*scale(x)-0.009827704*scale(x*median(data1$density, na.rm=T))-1.72935019-0.0146391775+0.0018600826
y1 <- exp(y)/(1+exp(y))
png("OctTmin.png", width=6, height=5, units="in", res=300)
par(mfrow=c(1,1),mar=c(4.5,4.5,1,1))
plot(x, y1, xlab="Minimum October temperature", ylab="Beetle probability", pch=19, cex=0.05)
dev.off()
# TOctSep
x <- data1$TOctSep
y <- sum(coeffs$cons)+0.114451743*scale(x*median(data1$density, na.rm=T))+0.0346628659-1.72935019
y1 <- exp(y)/(1+exp(y))
png("TOctSep.png", width=6, height=5, units="in", res=300)
par(mfrow=c(1,1),mar=c(4.5,4.5,1,1))
plot(x, y1, xlab="Water-year temperature", ylab="Beetle probability", pch=19, cex=0.05)
dev.off()
#PMarAug
x <- data1$PMarAug
y <- sum(coeffs$cons)-0.044948108*scale(x^2)-1.72935019-0.0097848475
y1 <- exp(y)/(1+exp(y))
png("PMarAug.png", width=6, height=5, units="in", res=300)
par(mfrow=c(1,1),mar=c(4.5,4.5,1,1))
plot(x, y1, xlab="Precipitation from March to August", ylab="Beetle probability", pch=19, cex=0.05)
dev.off()

lonlat <- CRS("+proj=longlat +datum=NAD83")
crs <- CRS("+proj=laea +lat_0=50 +lon_0=-100 +x_0=0 +y_0=0 +datum=WGS84 +units=m +no_defs +ellps=WGS84 +towgs84=0,0,0")
df <- data1
df$y <- y1
xy <- data.frame(df[,c(4,5)])
coordinates(xy) <- c('lon', 'lat')
proj4string(xy) <- lonlat
spdf <- SpatialPointsDataFrame(coords = xy, data = df, proj4string = lonlat)
spdf <- spTransform(spdf, crs)
install.packages("classInt", repos='http://cran.us.r-project.org')
library(classInt)
plotvar <- y1
nclr <- 5
color <- "RdYlGn"
plotclr <- rev(brewer.pal(nclr,color))
class <- classIntervals(plotvar, nclr, style="kmeans", dataPrecision=2)
colcode <- findColours(class, plotclr)
plot(spdf, col=colcode, pch=19, cex=0.05)
legend.title <- "By summerP"
legend("left", legend=names(attr(colcode, "table")),
         fill=attr(colcode, "palette"), cex=1.2, title=legend.title, bty="n")

