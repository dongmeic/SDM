SQUARE = c('Tmin', 'mi', 'lat', 'vpd', 'PcumOctSep', 'summerP0', 'ddAugJul',
					'AugMaxT', 'cwd', 'age', 'maxT', 'PPT', 'Acs', 'wd', 'MarMin',
          'summerP0', 'OctTmin', 'summerP1', 'OctMin', 'ddAugJun', 'JanTmin',
          'summerP2', 'max.drop', 'Pmean', 'PMarAug', 'etopo1', 'POctSep',
          'Mar20', 'sum9_diff')
CUBE = c('MarTmin', 'fallTmean', 'Tvar', 'JanMin', 'age', 'density', 'lon',
        'TOctSep', 'OptTsum', 'minT', 'AugTmax', 'AugTmean', 'lat', 'Tmean',
        'winterMin', 'TMarAug', 'summerTmean', 'Jan20', 'sum9_diff')
        
DATA_DIR <- '/gpfs/projects/gavingrp/dongmeic/beetle/output/tables/input'
# functions for checking final models and 2D plots

merge.files <- function(set=c('train', 'valid', 'test')) {
  cat(sprintf('Merging %s data...\n', set))
  all.files <- list.files(DATA_DIR)
  X.files <- sort(all.files[grepl(paste('X', set, sep='_'), all.files)])
  y.files <- sort(all.files[grepl(paste('y', set, sep='_'), all.files)])
  X <- read.csv(paste(DATA_DIR, X.files[1], sep='/'))
  y <- read.csv(paste(DATA_DIR, y.files[1], sep='/'))
  colnames(y) <- 'btl_t'
  data <- cbind(y, X)
  if (length(X.files) > 1) {
    for (i in 2:length(X.files)) {
      next.X <- read.csv(paste(DATA_DIR, X.files[i], sep='/'))
      next.y <- read.csv(paste(DATA_DIR, y.files[i], sep='/'))
      colnames(next.y) <- 'btl_t'
      next.data <- cbind(next.y, next.X)
      data <- rbind(data, next.data)
    }
  }
  data
}

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

get.data.frame <- function(df, scale=FALSE){
	y <- df[,'btl_t']
	df <- df[,singles] 
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
	if(scale){
		# calculate interactions
		for( i in 1:length(interactions)){
			v1 <- strsplit(interactions[i], ":")[[1]][1]; v2 <- strsplit(interactions[i], ":")[[1]][2]
			df[,interactions[i]] <- df[,v1] * df[,v2]
			cat(sprintf('Calculated %s ...\n', interactions[i]))
		}
		print('scaling X data...')
		df <- scale(df)
		colnames(df) <- gsub(":", "_", colnames(df))
	}	
	print('adding y data...')
	ndf <- cbind(data.frame(btl_t=y), df)	
	return(ndf)
}

get.more.data <- function(df){
	df <- df[,singles] 
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
	# calculate interactions
	for( i in 1:length(interactions)){
		v1 <- strsplit(interactions[i], ":")[[1]][1]; v2 <- strsplit(interactions[i], ":")[[1]][2]
		df[,interactions[i]] <- df[,v1] * df[,v2]
		cat(sprintf('Calculated %s ...\n', interactions[i]))
	}	
	return(df)
}

get.x.y <- function(df, var, intercept){
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
	df_1 <- scale(df[,colnames(df)[!(colnames(df) %in% selected)]])
	# get the median values for each predictors
	median <- apply(df_1, 2, median)
	medians <- data.frame(predictor=names(median), median=as.numeric(median), stringsAsFactors = FALSE)
				
	cons <- intercept
	for(i in 1:dim(medians)[1]){
		value <- coeff$coef[which(coeff$predictor==medians$predictor[i])] * medians$median[i]
		cons <- cons + value
		cat(sprintf('Calculated constant %s ...\n', medians$predictor[i]))
	}

	selected_coeffs <- coeff$coef[which(coeff$predictor %in% selected)]
	df_2 <- data.frame(var=selected, coeff=selected_coeffs, stringsAsFactors = FALSE)
	lon.cons = df_2$coeff[grep('lon:', df_2$var)] * medians$median[which(medians$predictor == 'lon')]
	lat.cons = df_2$coeff[grep('lat:', df_2$var)] * medians$median[which(medians$predictor == 'lat')]
	etopo1.cons = df_2$coeff[grep('etopo1:', df_2$var)]  * medians$median[which(medians$predictor =='etopo1')]
	x <- scale(df[,var])[,1]
	
	if(length(selected)==5 & var %in% SQUARE){
		y <- cons + lon.cons * x + lat.cons * x + etopo1.cons * x + df_2$coeff[grep('_sq', df_2$var)] * x * x + df_2$coeff[which(df_2$var==var)] * x
	}else if(length(selected)==5 & var %in% CUBE){
		y <- cons + lon.cons * x + lat.cons * x + etopo1.cons * x + df_2$coeff[grep('_cub', df_2$var)] * x * x * x + df_2$coeff[which(df_2$var==var)] * x	
	}else if(length(selected)==5 & var %in% CUBE & var %in% SQUARE){
		y <- cons + lon.cons * x + lat.cons * x + etopo1.cons * x + df_2$coeff[grep('_sq', df_2$var)] * x * x + df_2$coeff[grep('_cub', df_2$var)] * x * x * x + df_2$coeff[which(df_2$var==var)] * x
	}else if(length(selected)==4){
		y <- cons + lon.cons * x + lat.cons * x + etopo1.cons * x + df_2$coeff[which(df_2$var==var)] * x
	}else{
		print('There is some mistake!')
	}
	pred.y <- exp(y)/(1+exp(y))
	df_3 <- data.frame(x=df[,var], y=pred.y)
	print(summary(pred.y))
	return(df_3)
}

var.string <- function(coeff){
  for(var in coeff$predictor){
  	if(var == coeff$predictor[length(coeff$predictor)]){
  		cat(sprintf('%s', var))
  	}else{
  		cat(sprintf('%s + ', var))
  	}
  }
}

get.strings <- function(coeff,scale=FALSE){
	if(scale){
		strings <- gsub(":", "_", capture.output(var.string(coeff)))
	}else{
		strings <- capture.output(var.string(coeff))
	}
	return(strings)
}

# functions for mapping probability
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

selected.var <- function(var){
	if(var %in% c('Tmean', 'Tmin', 'mi', 'wd')){
		selected <- grep(paste0('^', var, '|:', var), coeff$predictor, value=TRUE)
		if(var == 'mi'){
			selected <- c('lat:mi', 'mi', 'lon:mi', 'etopo1:mi', 'mi_sq')
		}
	}else{
		selected <- grep(var, coeff$predictor, value=TRUE)
	}
	print(selected)
	return(selected)
}
get.pred.y <- function(preds, var){
	selected <- selected.var(var)
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