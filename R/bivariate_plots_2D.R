source('/gpfs/projects/gavingrp/dongmeic/sdm/R/model_output_functions.R')
train <- merge.files('train')
path <- '/gpfs/projects/gavingrp/dongmeic/beetle/output/tables/'
out <- '/gpfs/projects/gavingrp/dongmeic/beetle/output/plots/'

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

med.df <- data.frame(t(apply(ndf, 2, median, na.rm=T)))
n.steps <- 100
med.df <- med.df[rep(1, n.steps), ]

png(paste0(out,'biovariate_plot_',i,'.png'), width=14, height=12, units="in", res=300)
par(mfrow=c(4,4),mar=c(3.5,3.5,3,1))
for (field in vars) {
	test.df <- med.df
	xmin <- quantile(ndf[, field], probs=0.025)
	xmax <- quantile(ndf[, field], probs=0.975)
	test.df[, field] <- seq(xmin, xmax, length=100)
	preds <- predict(mod, newdata=test.df, type="response")
	plot(preds ~ test.df[, field], 
			 type='l',
			 main=varnms[which(vars==field)],
			 xlab='', 
			 ylab='')
}
dev.off()