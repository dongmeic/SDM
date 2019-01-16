# plot the response curve using median values for other variables
# based on /gpfs/projects/gavingrp/dongmeic/sdm/R/mapping_beetle_probability.R
# and /gpfs/projects/gavingrp/dongmeic/sdm/R/GLM_fitting_final_models.R

path <- '/gpfs/projects/gavingrp/dongmeic/beetle/output/tables/'
setwd('/gpfs/projects/gavingrp/dongmeic/beetle/output/tables/input')
source('/gpfs/projects/gavingrp/dongmeic/sdm/R/model_output_functions.R')

years = 1998:2015
df1 <- read.csv(paste0("input_data_1998.csv"))
df <- df1
for(i in 2:18){
	df2 <- read.csv(paste0("input_data_",years[i],".csv"))
	df <- rbind(df, df2)
	print(years[i])
}

coeff <- read.csv(paste0(path, 'model3/coefficients.csv'), stringsAsFactors = FALSE)
squares <- grep('_sq', coeff$predictor, value=TRUE)
cubes <- grep('_cub', coeff$predictor, value=TRUE)
interactions <- grep(':', coeff$predictor, value=TRUE)
singles <- coeff$predictor[!(coeff$predictor %in% c(squares, cubes, interactions))]

ndf <- get.more.data(df)
# test: var - 'wd', model3

n.sample = 100000
#xy.df <- get.x.y(ndf[sample(nrow(ndf), n.sample),], 'wd', -4.27790192)
xy.df <- get.x.y(ndf, 'wd', -4.27790192)
plot(xy.df$x, xy.df$y)