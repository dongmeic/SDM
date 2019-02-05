library(plot3D)
library(plot3Drgl)
library(plotly)
library(RColorBrewer)


path <- '/gpfs/projects/gavingrp/dongmeic/beetle/output/tables/'
outpath <- '/gpfs/projects/gavingrp/dongmeic/beetle/output/plots/'
source('/gpfs/projects/gavingrp/dongmeic/sdm/R/model_output_functions.R')
setwd('/gpfs/projects/gavingrp/dongmeic/beetle/output/tables/input')

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
scatter3D(df$lon, df$lat, df$etopo1, xlab='Longitude', ylab='Latitude', zlab='Elevation', 
					colvar = df$prob, phi = 0, bty ="g", pch=19, cex=0.5, col=colors)
					
scatter3d(x = df$lon, y = df$lat, z = df$etopo1, groups = as.factor(df$btl_t),
          grid = FALSE, fit = "smooth")					

plot3D <- function(xvar, yvar, zvar, xlab, ylab, zlab){
	scatter3D(df[,xvar], df[,yvar], df[,zvar], xlab=xlab, ylab=ylab, zlab=zlab, 
					colvar = df$prob, phi = 0, bty ="g", pch=19, cex=0.5, col=colors)
}

plotf3D('age', 'density', 'sum9_diff', )


