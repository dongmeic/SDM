# Created by Dongmei Chen
# generate yearly tables for SPLASH

library(ncdf4)
source("/gpfs/projects/gavingrp/dongmeic/climate-space/R/damian/getDailyStats.R")

years <- 1996:2015; nyr <- length(years)
outcsvpath <- "/gpfs/projects/gavingrp/dongmeic/beetle/output/tables/SPLASH/"
csvpath <- "/gpfs/projects/gavingrp/dongmeic/beetle/output/tables/"
ncpath <- "/gpfs/projects/gavingrp/dongmeic/beetle/ncfiles/na10km_v2/ts/"
setwd(outcsvpath)

# 1 - run in bash; 0 - run in R
if(1){
	args <- commandArgs(trailingOnly=T)
	print(paste('args:', args))
	print("Starting...")
	yr <- as.numeric(args[1])
	print(paste('year:', years[yr]))
}

roi.df <- read.csv("/gpfs/projects/gavingrp/dongmeic/beetle/csvfiles/na10km_v2_roi_xy.csv")
d <- dim(roi.df)[1]

vars <- c("sun", "tmean", "prcp")
varnms <- c("sf", "tair", "pn")

get.data <- function(var){
  ncfile <- paste0("na10km_v2_cru_ts4.01.",years[1],".",years[nyr],".",var,".abs4d.nc")
  ncin <- nc_open(paste0(ncpath, ncfile))
  data <- ncvar_get(ncin,var)
  fillvalue <- ncatt_get(ncin,var,"_FillValue")
  data[data==fillvalue$value] <- NA
  return(data)
}

data <- get.data(vars[1])
data.yr <- data[,,,yr]
get.monthly.data <- function(var){
  df <- data.frame(var=numeric())
  for(m in 1:12){
    data_slice <- data.yr[,,m]
    na.values <- data_slice[!is.na(data_slice)]
    nadf <- data.frame(var=na.values)
	  df <- rbind(df, nadf)
	  #print(paste("getting values from",var,"in year", years[yr], "and month", m))
  }	
  colnames(df) <- var
  rows <- roi.df$X
  allrows <- c()
  for(i in 1:12){allrows <- c(allrows, rows+(i-1)*d)}
  df <- data.frame(var=df[allrows,])
  return(df)  
}

get.monthly.vector.by.cell <- function(var,i){
  df <- get.monthly.data(var)
  v <- vector()
  for(m in 1:12){
		v[m] <- df[d*(m-1)+i,]
  } 
  v
}

get.cru.daily.vector.by.cell <- function(var,i){
  v <- get.monthly.vector.by.cell(var,i)
  n.days <- 365
  get.daily.from.monthly(v, n.days)
}

tmean <- read.csv(paste0(csvpath, "tmean/tmean", years[yr],".csv"))
prcp <- read.csv(paste0(csvpath, "prcp/prcp", years[yr],".csv"))
get.daymet.daily.vector.by.cell <- function(var,i){
	if(var=="tmean"){
		as.numeric(tmean[i,3:367])
	}else if(var=="prcp"){
		as.numeric(prcp[i,3:367])
	}	
}

print("writing out data...")
for(i in 1:d){
	col1 <- get.cru.daily.vector.by.cell(vars[1],i)/100
	col2 <- get.daymet.daily.vector.by.cell(vars[2],i)
	if(sum(is.na(col2))!= 0){
		next
	}else{
		col3 <- get.daymet.daily.vector.by.cell(vars[3],i)
		df <- data.frame(cbind(col1, col2, col3))
		colnames(df) <- varnms
		outnm <- paste0("s",roi.df$X[i], "_", roi.df$lat[i], "_", roi.df$etopo1[i], "_", years[yr],".csv")
		write.csv(df, paste0(outcsvpath, outnm), row.names = FALSE)
	}
}
print(paste("...got data from year", years[yr], "..."))

print("all done!")