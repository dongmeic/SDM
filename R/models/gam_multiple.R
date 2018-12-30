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
  colnames(y) <- 'btl_t'
  data <- cbind(y, X)
  if (length(X.files) > 1) {
    for (i in 2:length(X.files)) {
      next.X <- read.csv(paste(DATA_DIR, X.files[i], sep='/'))
      next.y <- read.csv(paste(DATA_DIR, y.files[i], sep='/'))
      colnames(next.y) <- 'btl_t'
      next.data <- cbind(next.y, next.X)
      data <- rbind(data, next.data)
    }
  }
  data
}

train <- merge.files('train')
for (j in 1:ncol(train)) {
  cat(sprintf('%11s: %s (%d)\n', 
              names(train)[j], 
              class(train[, j]), 
              length(unique(train[, j]))))
}

cold0 <- c('Jan20','Mar20')
nons <- c(cold0, 'vgt','btl_t1', 'btl_t2', 'sum9_t1', 'sum9_t2')
cold <- c("JanTmin","MarTmin","OctTmin","Tmin","Acs","max.drop","OctMin","JanMin","MarMin","winterMin","minT") 
season <- c("TMarAug","fallTmean","Tmean","Tvar","TOctSep","ddAugJul","ddAugJun")
summerT <- c("summerTmean","AugTmean","AugTmax","maxAugT","OptTsum","AugMaxT","maxT")
drought <- c("PMarAug", "summerP0","summerP1","summerP2","Pmean","POctSep","PcumOctSep","PPT")
drought1 <- c("wd","vpd","mi","cwd")
tree <- c("age", "density")
loc <- c("lon", "lat", "etopo1")
beetle <- c("btl_t1", "btl_t2", "sum9_t1", "sum9_t2")

gam.sample <- function(n.sample,st) {
  random.preds <- c(sample(cold0, 1),sample(cold, 1),sample(season, 1),sample(summerT, 1),
                    sample(drought, 1),sample(drought1, 1))
  preds <- c(random.preds, tree, loc, beetle)
  var.string <- function(st){
    for (p in preds) {
      if(p %in% nons){
        cat(sprintf('+ %s ', p))
      }else{
        cat(sprintf('+ %s(%s) ', st, p))
      }
    } 
  }
  start <- Sys.time()
  mod.string <- paste0('gam(btl_t ~ ', capture.output(var.string(st)),'+ vgt, data=train[sample(nrow(train), n.sample),])')
  mod <- eval(parse(text=mod.string))
  stop <- Sys.time()
  cat('Elapsed time:', stop - start, 's\n')
  mod
}

gam.random <- function(iters){
  for (i in 1:iters) {
    cat(sprintf('Starting interation %d...\n', i))
    mod <- gam.sample(80000,'te')
    par(mfrow=c(3, 3))
    plot(mod)
  }
}

out <- "/gpfs/projects/gavingrp/dongmeic/beetle/output/plots/"
pdf(paste0(out, "GAM_fitting.pdf"))
gam.random(50)
dev.off()
