# Created by Dongmei Chen
# combine SDM input data tables; based on reorganize_data_tables.R

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



rescale <- function(x, x.min, x.max, n.divs) {
  range <- x.max - x.min + 0.0000001
  dist <- x - x.min
  floor(dist*n.divs / range)
}

# Example
x.min <- min(your.x.values)
x.max <- max(your.x.values)
n.divs <- 30 # number of divisions (blocks) you want in the x-coordinate
x.new <- lapply(your.x.vector, function(x) rescale(x, x.min, x.max, n.cells))