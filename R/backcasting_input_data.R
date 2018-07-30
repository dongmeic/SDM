# Created by Dongmei Chen
# reorganize SDM input data tables

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

for (i in 1:(nyr-5)){
  # bioclimatic varibles, including monthly and daily data
  var <- read.csv(paste0("bioclimatic_values_", years[i],".csv"))
  df <- cbind(loc[,-6], btlprs[,c(paste0("prs_", years[i+1]), paste0("prs_", years[i+2]), paste0("prs_", (years[i]+3)),
  						paste0("prs_", years[i+4]), paste0("prs_", years[i+5]), paste0("prs_", (years[i]+6)), "vegetation")],
  						btlsum9[,c(paste0("sum9_", years[i+2]), paste0("sum9_", (years[i]+3)), 
  						paste0("sum9_", years[i+4]), paste0("sum9_", (years[i]+5)), paste0("sum9_", (years[i]+6)))],
  						var[, -which(colnames(var) %in% c("min30", "drop0", "drop5"))])
  colnames(df)[6:12] <- c("btl_t", "btl_t1", "btl_t2", "btl_t3", "btl_t4", "btl_t5", "vgt")
  colnames(df)[13:17] <- c("sum9_t1","sum9_t2","sum9_t3","sum9_t4","sum9_t5")
  df$year <- rep(years[i], dim(df)[1])
  df <- cbind(subset(df, select=c("btl_t")), df[ , -which(colnames(df) %in% c("btl_t"))])
  # bounding box
  ndf <- df[df$lon >= range(bd$lon)[1] & df$lon <= range(bd$lon)[2] & df$lat >= range(bd$lat)[1] & df$lat <= range(bd$lat)[2],]
  # plot to check the data
  plot(ndf$x, ndf$y, pch=19, col="blue", cex=0.01, main=ndf$year[1])
  points(ndf[ndf$btl_t==1,]$x, ndf[ndf$btl_t==1,]$y, pch=19, col="red", cex=0.01)
  write.csv(ndf, paste0("backcasting/input_data_",years[i],".csv"), row.names=FALSE)
  print(paste(years[i], "is done!"))
}

print("all done!")