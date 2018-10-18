# Created by Dongmei Chen
# Writing daily bioclimatic variables

library(parallel)
library(doParallel)
library(foreach)
registerDoParallel(cores=28)

source("/gpfs/projects/gavingrp/dongmeic/climate-space/R/damian/getStatsFromDaily.R")
inpath <- "/gpfs/projects/gavingrp/dongmeic/beetle/output/tables/"
setwd(inpath)
start_year <- 1995; end_year <- 2015; years <- start_year:end_year; nt <- length(years)

print("calculating the biocliamtic variables using daily data")
dim1 <- 77369; dim2 <- nt

ptm <- proc.time()
foreach(i = 1:nt)%dopar%{
	tmax.df.1 <- read.csv(paste0(inpath, "tmax/tmax", years[i],".csv"))
	tmax.df.2 <- read.csv(paste0(inpath, "tmax/tmax", years[i+1],".csv"))
	tmin.df.1 <- read.csv(paste0(inpath, "tmin/tmin", years[i],".csv"))
	tmin.df.2 <- read.csv(paste0(inpath, "tmin/tmin", years[i+1],".csv"))
	tmean.df.1 <- read.csv(paste0(inpath, "tmean/tmean", years[i],".csv"))
	tmean.df.2 <- read.csv(paste0(inpath, "tmean/tmean", years[i+1],".csv"))
	df <- data.frame(Lcs=double(), maxAugT=double(), summerT40=double(), winterTmin=double(), Ecs=double(), Ncs=double(), Acs=double(), drop0=double(),
									 drop5=double(), drop10=double(), drop15=double(), drop20=double(), drop20plus=double(),
									 max.drop=double(), ddAugJul=double(), ddAugJun=double(), min20=double(), min22=double(), 
									 min24=double(), min26=double(), min28=double(),min30=double(), min32=double(), 
									 min34=double(), min36=double(), min38=double(), min40=double())
	for(j in 1:dim1){
		tmx <- c(as.numeric(tmax.df.1[j,3:367]), as.numeric(tmax.df.2[j,3:367]))
		tmp <- c(as.numeric(tmean.df.1[j,3:367]), as.numeric(tmean.df.2[j,3:367]))
		tmn <- c(as.numeric(tmin.df.1[j,3:367]), as.numeric(tmin.df.2[j,3:367]))
		df[j,] <- get.daily.stats(years[i], tmx, tmp, tmn)
	}
	print(paste("got data from", years[i+1]))
	write.csv(df, paste0("daily_climate/Daymet/daymet_bioclimatic_variables_",years[i+1],".csv"), row.names = FALSE)  
}
proc.time() - pt
print("all done!")