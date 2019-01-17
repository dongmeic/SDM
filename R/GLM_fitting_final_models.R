# use R functions to to compare AIC, adjusted R squared and p values
# model1 - model with only bioclimatic variables
# model2 - model with bioclimatic variables, transformation and interactions
# model3 - model with bioclimatic variables, transformation, interactions and beetle variables

path <- '/gpfs/projects/gavingrp/dongmeic/beetle/output/tables/'
setwd('/gpfs/projects/gavingrp/dongmeic/beetle/output/tables/input')
source('/gpfs/projects/gavingrp/dongmeic/sdm/R/model_output_functions.R')

model <- 'model3'
coeff <- read.csv(paste0(path, model,'/coefficients.csv'), stringsAsFactors = FALSE)
squares <- grep('_sq', coeff$predictor, value=TRUE)
cubes <- grep('_cub', coeff$predictor, value=TRUE)
interactions <- grep(':', coeff$predictor, value=TRUE)
singles <- coeff$predictor[!(coeff$predictor %in% c(squares, cubes, interactions))]

train <- merge.files('train')
ndf <- get.data.frame(train)

#colnames(ndf) <- gsub(":", "_", colnames(ndf))
#strings <- gsub(":", "_", capture.output(var.string()))
strings <- capture.output(var.string())

mod.string <- paste0('glm(btl_t ~ ', strings, ', data=ndf, family=binomial())')
#n.sample = 100000
#mod.string <- paste0('glm(btl_t ~ ', strings, ', data=ndf[sample(nrow(ndf), n.sample),], family=binomial())')
mod <- eval(parse(text=mod.string))
