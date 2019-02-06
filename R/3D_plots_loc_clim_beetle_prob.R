library(plot3D)
library(plot3Drgl)
library(plotly)
library(RColorBrewer)
library(car)

if('gpfs' %in% getwd()){
  path <- '/gpfs/projects/gavingrp/dongmeic/beetle/output/tables/'
  outpath <- '/gpfs/projects/gavingrp/dongmeic/beetle/output/plots/'
  source('/gpfs/projects/gavingrp/dongmeic/sdm/R/model_output_functions.R')
}else{
  path <- '/Users/dongmeichen/Documents/beetle/csvfiles/'
  outpath <- '/Users/dongmeichen/Documents/beetle/output/'
  source('/Users/dongmeichen/GitHub/SDM/R/model_output_functions.R')
}

train <- merge.files('train')

model <- 'model5'
coeff <- read.csv(paste0(path, model,'/coefficients.csv'), stringsAsFactors = FALSE)
squares <- grep('_sq', coeff$predictor, value=TRUE)
cubes <- grep('_cub', coeff$predictor, value=TRUE)
interactions <- grep(':', coeff$predictor, value=TRUE)
singles <- coeff$predictor[!(coeff$predictor %in% c(squares, cubes, interactions))]

ndf <- get.data.frame(train)
drops <- c('sum9_t1', 'summerP2', 'lon:summerP1', 'lat:summerP0', 'etopo1:summerP1', 'density:summerP1')
#strings <- gsub(":", "_", capture.output(var.string(coeff, drops)))
strings <- capture.output(var.string(coeff, drops))
mod.string <- paste0('glm(btl_t ~ ', strings, ', data=ndf, family=binomial())')
ptm <- proc.time()
mod <- eval(parse(text=mod.string))
proc.time() - ptm

n.sample <- 15000
s.df <- ndf[sample(nrow(ndf), n.sample),]
y <- predict(mod, s.df, type="response")

df <- cbind(s.df, data.frame(prob=y))
df <- df[df$prob > 0.543,]
colors <- brewer.pal(n=9, name="YlOrRd")
par(mfrow=c(1,1),mar=c(0.5,2.5,0.5,1.5))
scatter3D(df$lon, df$lat, df$etopo1, xlab='Longitude', ylab='Latitude', zlab='Elevation', 
					colvar = df$prob, phi = 0, bty ="g", pch=19, cex=0.5, col=colors)
					
scatter3d(x = df$lon, y = df$lat, z = df$etopo1, groups = as.factor(df$btl_t),
          grid = FALSE, fit = "smooth")					

plot3D <- function(xvar, yvar, zvar, xlab, ylab, zlab, theta = 60,  phi = 0){
	scatter3D(df[,xvar], df[,yvar], df[,zvar], xlab=xlab, ylab=ylab, zlab=zlab, 
					colvar = df$prob, phi = phi, bty ="g", pch=19, cex=0.5, #type = "h", 
					theta = theta, ticktype = "detailed", colkey = FALSE, col=alpha.col('blue', 0.5))
}

plot3D('age', 'density', 'prob', 'Stand age', 'Tree density', 'Beetle probability')
plot3D('Tmean', 'density', 'prob', 'Aug-Jul mean temperature', 'Tree density', 'Beetle probability')
plot3D('lat', 'TMarAug', 'prob', 'Latitude', 'Mar-Aug mean temperature', 'Beetle probability')
