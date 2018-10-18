# Created by Dongmei Chen
# Writing daily bioclimatic variables

library(ncdf4)
library(parallel)
library(doParallel)
library(foreach)
registerDoParallel(cores=28)

source("/gpfs/projects/gavingrp/dongmeic/climate-space/R/damian/getDailyStatsFromDaily.R")
inpath <- "/gpfs/projects/gavingrp/dongmeic/beetle/output/tables/"
setwd(inpath)
start_year <- 1995; end_year <- 2015; years <- start_year:end_year; nt <- length(years)

print("calculating the biocliamtic variables using daily data")
ptm <- proc.time()
dim1 <- 77369; dim2 <- nt

foreach(i = 1:nt)%dopar%{
	tmax.df.1 <- read.csv(paste0(inpath, "tmax/tmax", years[i],".csv"))
	tmax.df.2 <- read.csv(paste0(inpath, "tmax/tmax", years[i+1],".csv"))
	tmin.df.1 <- read.csv(paste0(inpath, "tmin/tmin", years[i],".csv"))
	tmin.df.2 <- read.csv(paste0(inpath, "tmin/tmin", years[i+1],".csv"))
	tmean.df.1 <- read.csv(paste0(inpath, "tmean/tmean", years[i],".csv"))
	tmean.df.2 <- read.csv(paste0(inpath, "tmean/tmean", years[i+1],".csv"))
	df <- data.frame(winterTmin=double(), Ecs=double(), Ncs=double(), Acs=double(), drop0=double(),
								 drop5=double(), drop10=double(), drop15=double(), drop20=double(), drop20plus=double(),
								 max.drop=double(), ddAugJul=double(), ddAugJun=double(), min20=double(), min22=double(), 
								 min24=double(), min26=double(), min28=double(),min30=double(), min32=double(), 
								 min34=double(), min36=double(), min38=double(), min40=double())
	df.d <- data.frame(tmx=double(), tmp=double(), tmn=double())
	for(j in 1:dim1){
		df.d$tmx <- as.numeric(rbind(tmax.df.1[j,3:367],tmax.df.2[j,3:367]))
		df.d$tmp <- as.numeric(rbind(tmean.df.1[j,3:367],tmean.df.2[j,3:367]))
		df.d$tmn <- as.numeric(rbind(tmin.df.1[j,3:367],tmin.df.2[j,3:367]))
		df[j,] <- get.daily.stats(years[i], df.d$tmx, df.d$tmp, df.d$tmn)
	}
	print(paste("got data from", years[i+1]))
	write.csv(df, paste0("daymet_bioclimatic_variables_",years[i+1],".csv"), row.names = FALSE)  
}
proc.time() - ptm
print("all done!")