library(mgcv)

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

ptm <- proc.time()
train <- merge.files('train')
proc.time() - ptm

select <- c('Acs', 'ddAugJul', 'Tvar', 'maxAugT', 'summerP0', 'wd')
loc <- c('lon', 'lat', 'etopo1')
tree <- c('age', 'density')
preds <- c(select, loc, tree)

var.string <- function(st){
    for (p in preds) {
        cat(sprintf('+ %s(%s) ', st, p))
    } 
}

mod.string <- paste0('gam(btl_t ~ s(sum9_diff)', capture.output(var.string('s')),
                     ', data=train, family=binomial)')
                     
ptm <- proc.time()
mod <- eval(parse(text=mod.string))
proc.time() - ptm

par(mfrow=c(3, 3))
pdf("gam_fitting_plots_s.pdf")
plot(mod)
dev.off()

par(mfrow=c(3, 3))
pdf("gam_fitting_plots_s_3.pdf")
plot(mod, ylim=c(-3, 3))
dev.off()

sink("gam_s.txt")
summary(mod)
sink()



