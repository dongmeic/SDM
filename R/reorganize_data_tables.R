# Created by Dongmei Chen
# reorganize SDM input data tables

library(parallel)
library(doParallel)
library(foreach)
registerDoParallel(cores=28)

# input and output path
path <- "/gpfs/projects/gavingrp/dongmeic/beetle/output/tables"
setwd(path)

years <- 1996:2015; nyr <- length(years)
# beetle presence data
btlprs <- read.csv("beetle_presence.csv")
bd <- btlprs[btlprs$allyears==1,]
btlsum9 <- read.csv("ts_presence_sum9.csv")
# location data
loc <- read.csv("location.csv")
# vegetation data
tree <- read.csv("stand_age_density.csv")

foreach (i=3:nyr)%dopar%{
  # bioclimatic varibles, including monthly and daily data
  var <- read.csv(paste0("bioclimatic_values_", years[i],".csv"))
  df <- cbind(loc[,-6], btlprs[,c(paste0("prs_", years[i]+1), paste0("prs_", years[i]), paste0("prs_", years[i-1]),"vegetation")],
  						tree[,c("age", "density")], btlsum9[,c(paste0("sum9_", years[i]), paste0("sum9_", years[i-1]))], 
  						var[, -which(colnames(var) %in% c("min30", "drop0", "drop5"))])
  colnames(df)[6:9] <- c("btl_t", "btl_t1", "btl_t2", "vgt")
  colnames(df)[12:13] <- c("sum9_t1","sum9_t2")
  df$year <- rep(years[i], dim(df)[1])
  df <- cbind(subset(df, select=c("btl_t")), df[ , -which(colnames(df) %in% c("btl_t"))])
  # bounding box
  ndf <- df[df$lon >= range(bd$lon)[1] & df$lon <= range(bd$lon)[2] & df$lat >= range(bd$lat)[1] & df$lat <= range(bd$lat)[2],]
  write.csv(ndf, paste0("input_data_",years[i],".csv"), row.names=FALSE)
  print(paste(years[i], "is done!"))
}

print("all done!")