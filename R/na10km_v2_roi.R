# Get a table for latitude, longitude and elevation for ROI
library(rgdal)

na10km.df <- read.csv("/gpfs/projects/gavingrp/dongmeic/beetle/csvfiles/na10km_v2.csv")
roi.shp <- readOGR(dsn="/gpfs/projects/gavingrp/dongmeic/beetle/shapefiles", layer = "na10km_roi")
rows <- roi.shp@data[,"seq_1_leng"]

df <- na10km.df[rows,]
write.csv(df, "/gpfs/projects/gavingrp/dongmeic/beetle/csvfiles/na10km_v2_roi_xy.csv")
df <- cbind(df, roi.shp@data[,-3:-1])
write.csv(df, "/gpfs/projects/gavingrp/dongmeic/beetle/csvfiles/na10km_v2_roi.csv")
df <- read.csv("/gpfs/projects/gavingrp/dongmeic/beetle/csvfiles/na10km_v2_roi.csv")
