# Created by Dongmei Chen
# combine SDM input data tables; based on reorganize_data_tables.R

library(parallel)
library(doParallel)
library(foreach)
registerDoParallel(cores=28)
source("/gpfs/projects/gavingrp/dongmeic/climate-space/R/combine_CRU_Daymet.R")

rescale <- function(x, x.min, x.max, n.divs) {
  range <- x.max - x.min + 0.0000001
  dist <- x - x.min
  floor(dist*n.divs / range)
}

split.xy <- function(df, set, year){
	X <- df[,-1]
	y <- df[,1]
	write.csv(X, paste0("input/X_",set,"_",year,".csv"), row.names=FALSE)
	write.csv(y, paste0("input/y_",set,"_",year,".csv"), row.names=FALSE)
}
# input and output path
path <- "/gpfs/projects/gavingrp/dongmeic/beetle/output/tables"
setwd(path)

years <- 1996:2015; nyr <- length(years)
# beetle presence data
#btlprs <- read.csv("beetle_presence.csv")
btlprs <- read.csv("beetle_presence_updated.csv")
btlsum9 <- read.csv("ts_presence_sum9.csv")
# bounding box
bd <- btlprs[btlprs$allyears==1,]
# location data
loc <- read.csv("location.csv")
# vegetation data
tree <- read.csv("stand_age_density.csv")
loc.bd <- loc[loc$lon >= range(bd$lon)[1] & loc$lon <= range(bd$lon)[2] & loc$lat >= range(bd$lat)[1] & loc$lat <= range(bd$lat)[2],]
x.min <- min(loc.bd$x); y.min <- min(loc.bd$y); x.max <- max(loc.bd$x); y.max <- max(loc.bd$y)
x.n.divs <- 30; y.n.divs <- 60

foreach (i=3:nyr)%dopar%{
  df <- cbind(loc[,-6], btlprs[,c(paste0("prs_", years[i]+1), paste0("prs_", years[i]), paste0("prs_", years[i-1]),"vegetation")],
  						tree[,c("age", "density")], btlsum9[,c(paste0("sum9_", years[i]), paste0("sum9_", years[i-1]))])
  colnames(df)[6:9] <- c("btl_t", "btl_t1", "btl_t2", "vgt")
  colnames(df)[12:13] <- c("sum9_t1","sum9_t2")
  df$year <- rep(years[i], dim(df)[1])
  df$vgt <- ifelse(df$btl_t==1 & df$vgt==0, 1, df$vgt)
  bioclm <- combine_CRU_Daymet(i)[,1:62]
  df <- cbind(df[rows$rows,], bioclm)
  df <- cbind(subset(df, select=c("btl_t")), df[ , -which(colnames(df) %in% c("btl_t"))])
  ndf <- df[df$lon >= range(bd$lon)[1] & df$lon <= range(bd$lon)[2] & df$lat >= range(bd$lat)[1] & df$lat <= range(bd$lat)[2],]
  write.csv(ndf, paste0("input/input_data_",years[i],".csv"), row.names=FALSE)
  ndf$x.new <- unlist(lapply(ndf$x, function(x) rescale(x, x.min, x.max, x.n.divs))) + 1
  ndf$y.new <- unlist(lapply(ndf$y, function(x) rescale(x, y.min, y.max, y.n.divs))) + 1
  ndf$xy <- paste0('x', ndf$x.new, 'y', ndf$y.new)
  n <- length(unique(ndf$xy))
  valid.test.idx <- sample(unique(ndf$xy),round(0.2*n))
  valid.idx <- valid.test.idx[1:151]
  test.idx <- valid.test.idx[152:302]
  train.idx <- unique(ndf$xy)[!(unique(ndf$xy) %in% valid.test.idx)]
  test <- ndf[ndf$xy %in% test.idx,]
  valid <- ndf[ndf$xy %in% valid.idx,]
  train <- ndf[ndf$xy %in% train.idx,]
  split.xy(test, "test", years[i])
  split.xy(valid, "valid", years[i])
  split.xy(train, "train", years[i])
  print(paste(years[i], "is done!"))
}
print("all done!")