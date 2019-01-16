# use R functions to to compare AIC, adjusted R squared and p values
path <- '/gpfs/projects/gavingrp/dongmeic/beetle/output/tables/'
setwd('/gpfs/projects/gavingrp/dongmeic/beetle/output/tables/input')
source('/gpfs/projects/gavingrp/dongmeic/sdm/R/model_output_functions.R')

years = 1998:2015
df1 <- read.csv(paste0("input_data_1998.csv"))
df <- df1
#year = 2009
#i = which(years==year)
for(i in 2:18){
	df2 <- read.csv(paste0("input_data_",years[i],".csv"))
	df <- rbind(df, df2)
	print(years[i])
}

# model1 - model with only bioclimatic variables
coeff <- read.csv(paste0(path, 'model1/coefficients.csv'), stringsAsFactors = FALSE)

# model2 - model with bioclimatic variables, transformation and interactions
coeff <- read.csv(paste0(path, 'model2/coefficients.csv'), stringsAsFactors = FALSE)
squares <- grep('_sq', coeff$predictor, value=TRUE)
cubes <- grep('_cub', coeff$predictor, value=TRUE)
interactions <- grep(':', coeff$predictor, value=TRUE)
singles <- coeff$predictor[!(coeff$predictor %in% c(squares, cubes, interactions))]

# add transformed data
ndf <- get.transformed.data(df)

var.string <- function(){
  for(var in coeff$predictor){
  	if(var == coeff$predictor[length(coeff$predictor)]){
  		cat(sprintf('%s', var))
  	}else{
  		cat(sprintf('%s + ', var))
  	}
  }
}
strings <- capture.output(var.string())
mod.string <- paste0('glm(btl_t ~ ', strings, ', data=ndf, family=binomial())')
#n.sample = 100000
#mod.string <- paste0('glm(btl_t ~ ', strings, ', data=ndf[sample(nrow(ndf), n.sample),], family=binomial())')
mod <- eval(parse(text=mod.string))

# model3 - model with bioclimatic variables, transformation, interactions and beetle variables
coeff <- read.csv(paste0(path, 'model3/coefficients.csv'), stringsAsFactors = FALSE)