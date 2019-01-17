# use R functions to to compare AIC, adjusted R squared and p values
# model1 - model with only bioclimatic variables
# model2 - model with bioclimatic variables, transformation and interactions
# model3 - model with bioclimatic variables, transformation, interactions and beetle variables

path <- '/gpfs/projects/gavingrp/dongmeic/beetle/output/tables/'
source('/gpfs/projects/gavingrp/dongmeic/sdm/R/model_output_functions.R')

model <- 'model3'
train <- merge.files('train')

summary.model <- function(i){
	model <- paste0('model', i)
	coeff <- read.csv(paste0(path, model,'/coefficients.csv'), stringsAsFactors = FALSE)
	if(i>1){
		squares <- grep('_sq', coeff$predictor, value=TRUE)
		cubes <- grep('_cub', coeff$predictor, value=TRUE)
		interactions <- grep(':', coeff$predictor, value=TRUE)
		singles <- coeff$predictor[!(coeff$predictor %in% c(squares, cubes, interactions))]
		ndf <- get.data.frame(train)	
	}else{
		ndf <- train[,-which(colnames(train) %in% c("x", "y", "x.new", "y.new", "xy"))]
	}
	strings <- get.strings(coeff)
	mod.string <- paste0('glm(btl_t ~ ', strings, ', data=ndf, family=binomial())')
	#n.sample = 100000
	#mod.string <- paste0('glm(btl_t ~ ', strings, ', data=ndf[sample(nrow(ndf), n.sample),], family=binomial())')
	ptm <- proc.time()
	mod <- eval(parse(text=mod.string))
	proc.time() - ptm
	
	sink(paste0(path,model,"_summary.txt"))
	print(summary(mod))
	sink()
}

for(i in 1:4){
	summary.model(i)
	print(paste('printed the summary for', model))
}