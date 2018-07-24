#!/usr/local/bin/Rscript
library(mgcv)


DATA_DIR <- '../../data/Xy_internal_split_data'

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
  ignore <- c('btl_t', 'x', 'y', 'btl_t1', 'btl_t2', 'vgt', 'year', 
              'sum9_t1', 'sum9_t2')
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