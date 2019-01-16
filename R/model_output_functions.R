
get.transformed.data <- function(df){
	# calculate squares
	for (i in 1:length(squares)){
		var <- strsplit(squares[i], "_sq")[[1]][1]
		df[,squares[i]] <- (df[,var])^2
		cat(sprintf('Calculated %s ...\n', squares[i]))
	}
	# calculate cubes
	for (i in 1:length(cubes)){
		var <- strsplit(cubes[i], "_cub")[[1]][1]
		df[,cubes[i]] <- (df[,var])^3
		cat(sprintf('Calculated %s ...\n', cubes[i]))
	}
	return(df)
}

get.input <- function(year){
	input <- read.csv(paste0('/gpfs/projects/gavingrp/dongmeic/beetle/output/tables/input/input_data_',year,'.csv'))
	predictors <- input[,-which(colnames(input) %in% ignore)]
	preds <- predictors[,singles] 
	# calculate squares
	for (i in 1:length(squares)){
		var <- strsplit(squares[i], "_sq")[[1]][1]
		preds[,squares[i]] <- (preds[,var])^2
		cat(sprintf('Calculated %s ...\n', squares[i]))
	}
	# calculate cubes
	for (i in 1:length(cubes)){
		var <- strsplit(cubes[i], "_cub")[[1]][1]
		preds[,cubes[i]] <- (preds[,var])^3
		cat(sprintf('Calculated %s ...\n', cubes[i]))
	}
	# calculate interactions
	for( i in 1:length(interactions)){
		v1 <- strsplit(interactions[i], ":")[[1]][1]; v2 <- strsplit(interactions[i], ":")[[1]][2]
		preds[,interactions[i]] <- preds[,v1] * preds[,v2]
		cat(sprintf('Calculated %s ...\n', interactions[i]))
	}	
	return(preds)
}

get.pred.y <- function(preds, var){
	if(var %in% c('Tmean', 'Tmin', 'mi', 'wd')){
		selected <- grep(paste0('^', var, '|:', var), coeff$predictor, value=TRUE)
		if(var == 'mi'){
			selected <- c('lat:mi', 'mi', 'lon:mi', 'etopo1:mi', 'mi_sq')
		}
	}else{
		selected <- grep(var, coeff$predictor, value=TRUE)
	}
	print(selected)
	
	loc_variables <- grep('^lon|^lat|^etopo1', coeff$predictor, value=TRUE)	
	preds_1 <- scale(preds[,colnames(preds)[!(colnames(preds) %in% selected)]])
	#preds_1 <- scale(preds[,colnames(preds)[!(colnames(preds) %in% c(selected,loc_variables))]])
	preds_2 <- scale(preds[,loc_variables])
	# get the median values for each predictors
	median <- apply(preds_1, 2, median)
	medians <- data.frame(predictor=names(median), median=as.numeric(median), stringsAsFactors = FALSE)
				
	intercept = -4.43337254; cons <- intercept
	for(i in 1:dim(medians)[1]){
		value <- coeff$coef[which(coeff$predictor==medians$predictor[i])] * medians$median[i]
		cons <- cons + value
		cat(sprintf('Calculated constant %s ...\n', medians$predictor[i]))
	}

	selected_coeffs <- coeff$coef[which(coeff$predictor %in% selected)]
	df <- data.frame(var=selected, coeff=selected_coeffs, stringsAsFactors = FALSE)
	lon.cons = df$coeff[grep('lon:', df$var)] * preds_2[,'lon']
	lat.cons = df$coeff[grep('lat:', df$var)] * preds_2[,'lat']
	etopo1.cons = df$coeff[grep('etopo1:', df$var)]  * preds_2[,'etopo1']
	x <- scale(preds[,var])[,1]
	
	if(length(selected)==5 & var %in% SQUARE){
		y <- cons + lon.cons * x + lat.cons * x + etopo1.cons * x + df$coeff[grep('_sq', df$var)] * x * x + df$coeff[which(df$var==var)] * x
	}else if(length(selected)==5 & var %in% CUBE){
		y <- cons + lon.cons * x + lat.cons * x + etopo1.cons * x + df$coeff[grep('_cub', df$var)] * x * x * x + df$coeff[which(df$var==var)] * x	
	}else if(length(selected)==5 & var %in% CUBE & var %in% SQUARE){
		y <- cons + lon.cons * x + lat.cons * x + etopo1.cons * x + df$coeff[grep('_sq', df$var)] * x * x + df$coeff[grep('_cub', df$var)] * x * x * x + df$coeff[which(df$var==var)] * x
	}else if(length(selected)==4){
		y <- cons + lon.cons * x + lat.cons * x + etopo1.cons * x + df$coeff[which(df$var==var)] * x
	}else{
		print('There is some mistake!')
	}
# 	preds_3 <- preds_2[,colSums(is.na(preds_2))<nrow(preds_2)]
# 	for(j in 1:dim(preds_3)[2]){
# 		y <- y + coeff$coef[which(coeff$predictor==colnames(preds_3)[j])] * preds_3[,j]
# 		print(summary(y))
# 		cat(sprintf('Added constant %s ...\n', colnames(preds_3)[j]))
# 	}
	pred.y <- exp(y)/(1+exp(y))
	print(summary(pred.y))
	return(pred.y)
}