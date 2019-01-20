library(ggplot2)

path <- '/gpfs/projects/gavingrp/dongmeic/beetle/output/tables/'
outpath <- '/gpfs/projects/gavingrp/dongmeic/beetle/output/plots/'
source('/gpfs/projects/gavingrp/dongmeic/sdm/R/model_output_functions.R')
setwd('/gpfs/projects/gavingrp/dongmeic/beetle/output/tables/input')

train <- merge.files('train')

model <- 'model3'
coeff <- read.csv(paste0(path, model,'/coefficients.csv'), stringsAsFactors = FALSE)
squares <- grep('_sq', coeff$predictor, value=TRUE)
cubes <- grep('_cub', coeff$predictor, value=TRUE)
interactions <- grep(':', coeff$predictor, value=TRUE)
singles <- coeff$predictor[!(coeff$predictor %in% c(squares, cubes, interactions))]

ndf <- get.data.frame(train)
#strings <- gsub(":", "_", capture.output(var.string(coeff)))
strings <- capture.output(var.string(coeff))
mod.string <- paste0('glm(btl_t ~ ', strings, ', data=ndf, family=binomial())')
ptm <- proc.time()
mod <- eval(parse(text=mod.string))
proc.time() - ptm

vars <- c('wd', 'JanTmin', 'Acs', 'summerTmean', 'ddAugJul', 'maxAugT')
varnms <- c('Water deficit', 'January minimum temperature', 'Average duration of cold snaps', 
						'Mean summer temperature', 'Degree days', 'Frequency of ≥ 18.3 °C temperature in August')

n.sample <- 15000
s.df <- ndf[sample(nrow(ndf), n.sample),]
y <- predict(mod, s.df, type="response")
fs <- c(0.1, 0.3, 0.3, 0.3, 0.3, 0.3)

for(var in vars){
	df <- data.frame(x=s.df[,var], y=y)
	df <- df[order(df$x),]
	lowessFit <-data.frame(lowess(df,f = .3,iter=1))
	png(paste0(outpath, var, '_2Dplot.png'), width=6, height=6, units="in", res=300)
	par(mfrow=c(1,1),xpd=FALSE,mar=c(2.5,2.5,2,1))
	plot(df$x, df$y, pch=16, cex=0.25, col=rgb(0,0,0,0.5), main=varnms[which(vars==var)],xlab='',ylab='')
	#lines(loessFit,lwd=2, col='blue')
	lines(lowessFit,lwd=2, col='blue')
	dev.off()
	print(paste(var, 'is done!'))
}






