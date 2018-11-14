# Created by Dongmei Chen
# generate yearly tables for SPLASH

library(ncdf4)
source("/gpfs/projects/gavingrp/dongmeic/climate-space/R/damian/getDailyStats.R")

rows <- read.csv("/gpfs/projects/gavingrp/dongmeic/beetle/csvfiles/daymet_na10km.csv")
d <- dim(rows)[1]
years <- 1991:2015; nyr <- length(years)
outcsvpath <- "/gpfs/projects/gavingrp/dongmeic/daymet/evapo_na/input"
csvpath <- "/gpfs/projects/gavingrp/dongmeic/daymet/datatable_na/"
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

ifelse(!dir.exists(file.path(outcsvpath, years[yr])), dir.create(file.path(outcsvpath, years[yr])), FALSE)

vars <- c("sun", "tmean", "prcp")
varnms <- c("sf", "tair", "pn")

get.data <- function(var){
  ncfile <- paste0("na10km_v2_cru_ts4.01.1901.2016.",var,".abs4d.nc")
  ncin <- nc_open(paste0(ncpath, ncfile))
  data <- ncvar_get(ncin,var, start=c(x=1,y=1,month=1,year=91),count=c(x=1078,y=900,month=12,year=nyr))
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

tmean <- read.csv(paste0(csvpath, "tmean/tmean_", years[yr],".csv"))
prcp <- read.csv(paste0(csvpath, "prcp/prcp_", years[yr],".csv"))
get.daymet.daily.vector.by.cell <- function(var,i){
	if(var=="tmean"){
		as.numeric(tmean[i,])
	}else if(var=="prcp"){
		as.numeric(prcp[i,])
	}	
}

print("writing out data...")

for(i in 1:d){
	col1 <- get.cru.daily.vector.by.cell(vars[1],rows$rows[i])/100
	col2 <- get.daymet.daily.vector.by.cell(vars[2],i)
	if(sum(is.na(col2))!= 0){
		next
	}else{
		col3 <- get.daymet.daily.vector.by.cell(vars[3],i)
		df <- data.frame(cbind(col1, col2, col3))
		colnames(df) <- varnms
		outnm <- paste0("s",i, "_", rows$lat[i], "_", rows$etopo1[i], "_", years[yr],".csv")
		write.csv(df, file.path(outcsvpath,years[yr],outnm), row.names = FALSE)
	}
}
print(paste("...got data from year", years[yr], "..."))

print("all done!")