# Created by Dongmei Chen
# Daily bioclimatic variables from Daymet

source("/gpfs/projects/gavingrp/dongmeic/climate-space/R/getVarsfromDaymet.R")

inpath <- "/gpfs/projects/gavingrp/dongmeic/beetle/output/tables/"
setwd(inpath)
start_year <- 1995; end_year <- 2015; years <- start_year:end_year; nt <- length(years)

# 1 - run in bash; 0 - run in R
if(1){
	args <- commandArgs(trailingOnly=T)
	print(paste('args:', args))
	print("Starting...")
	i <- as.numeric(args[1])
	print(paste('i:', i))
}

print("calculating the biocliamtic variables using daily data")
dim1 <- 77369; dim2 <- nt

ptm <- proc.time()
tmax.df.1 <- read.csv(paste0(inpath, "tmax/tmax", years[i],".csv"))
tmax.df.2 <- read.csv(paste0(inpath, "tmax/tmax", years[i+1],".csv"))
tmin.df.1 <- read.csv(paste0(inpath, "tmin/tmin", years[i],".csv"))
tmin.df.2 <- read.csv(paste0(inpath, "tmin/tmin", years[i+1],".csv"))
tmean.df.1 <- read.csv(paste0(inpath, "tmean/tmean", years[i],".csv"))
tmean.df.2 <- read.csv(paste0(inpath, "tmean/tmean", years[i+1],".csv"))
df <- data.frame(Oct20=double(), Oct30=double(), Oct40=double(), OctMin=double(), 
								 Jan20=double(), Jan30=double(), Jan40=double(), JanMin=double(),
								 Mar20=double(), Mar30=double(), Mar40=double(), MarMin=double(), 
								 minT=double(), AugMax=double(), maxT=double(), OptTsum=double())
for(j in 1:dim1){
	tmx <- c(as.numeric(tmax.df.1[j,3:367]), as.numeric(tmax.df.2[j,3:367]))
	tmp <- c(as.numeric(tmean.df.1[j,3:367]), as.numeric(tmean.df.2[j,3:367]))
	tmn <- c(as.numeric(tmin.df.1[j,3:367]), as.numeric(tmin.df.2[j,3:367]))
	if(sum(is.na(tmx))==0 && sum(is.na(tmn))==0){
		df[j,] <- get.daily.stats(tmx, tmp, tmn)
	}else{
		if(sum(is.na(tmx))!=730){
			print(paste("at the point of x(", tmax.df.1[j,1], ") and y(", tmax.df.1[j,2], ")..."))
		}	
		df[j,] <- NA
	}
}
print(paste("got data from", years[i+1]))
write.csv(df, paste0("daily_climate/Daymet/dm_bioclm_var_",years[i+1],".csv"), row.names = FALSE)  

proc.time() - ptm
print("all done!")