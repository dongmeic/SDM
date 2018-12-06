#!/usr/local/bin/Rscript
library(mgcv)


#DATA_DIR <- '/gpfs/projects/gavingrp/dongmeic/beetle/output/tables/Xy_internal_split_data'
#DATA_DIR <- '/gpfs/projects/gavingrp/dongmeic/beetle/output/tables/backcasting/Xy_year_split_data'
DATA_DIR <- '/gpfs/projects/gavingrp/dongmeic/beetle/output/tables/input'
setwd("/gpfs/projects/gavingrp/dongmeic/beetle/output/plots/gam")

merge.files <- function(set=c('train', 'valid', 'test')) {
  cat(sprintf('Merging %s data...\n', set))
  all.files <- list.files(DATA_DIR)
  X.files <- sort(all.files[grepl(paste('X', set, sep='_'), all.files)])
  y.files <- sort(all.files[grepl(paste('y', set, sep='_'), all.files)])
  X <- read.csv(paste(DATA_DIR, X.files[1], sep='/'))
  y <- read.csv(paste(DATA_DIR, y.files[1], sep='/'))
  data <- cbind(y, X)
  if (length(X.files) > 1) {
    for (i in 2:length(X.files)) {
      next.X <- read.csv(paste(DATA_DIR, X.files[i], sep='/'))
      next.y <- read.csv(paste(DATA_DIR, y.files[i], sep='/'))
      next.data <- cbind(next.y, next.X)
      data <- rbind(data, next.data)
    }
  }
  data
}

main <- function(iters) {
  train <- merge.files('train')
  ignore <- c('btl_t', 'x', 'y', 'btl_t1', 'btl_t2', 'btl_t3', 'btl_t4', 'btl_t5', 'vgt', 'year', 
              'sum9_t1', 'sum9_t2', 'sum9_t3', 'sum9_t4', 'sum9_t5', 'x.new', 'y.new', 'xy')
  plot.gam.sample <- function(sample.size=32000) {
    par(mfrow=c(3, 3))
    for (field in names(train)) {
      if (!(field %in% ignore)) {
      	cat(sprintf('modeling %s...\r', field))
        n <- sample.size
        s <- sample(nrow(train), n)
        gam.mod <- gam(train$btl_t[s] ~ s(train[s, field]), family='binomial')
        plot(gam.mod, xlab=field, ylab=paste('s(', field, ')', sep=''))  
      }
    }
  }
  
  for (i in 1:iters) {
  	cat(sprintf('Starting interation %d...\n', i))
    plot.gam.sample()
  }
}

main(10)