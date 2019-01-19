library(ggplot2)

path <- '/gpfs/projects/gavingrp/dongmeic/beetle/output/tables/'
outpath <- '/gpfs/projects/gavingrp/dongmeic/beetle/output/plots/'
source('/gpfs/projects/gavingrp/dongmeic/sdm/R/model_output_functions.R')
setwd('/gpfs/projects/gavingrp/dongmeic/beetle/output/tables/input')

train <- merge.files('train')

model <- 'model3'
coeff <- read.csv(paste0(path, model,'/coefficients.csv'), stringsAsFactors = FALSE)
squares <- grep('_sq', coeff$predictor, value=TRUE)
cubes <- grep('_cub', coeff$predictor, value=TRUE)
interactions <- grep(':', coeff$predictor, value=TRUE)
singles <- coeff$predictor[!(coeff$predictor %in% c(squares, cubes, interactions))]

ndf <- get.data.frame(train)
#strings <- gsub(":", "_", capture.output(var.string(coeff)))
strings <- capture.output(var.string(coeff))
mod.string <- paste0('glm(btl_t ~ ', strings, ', data=ndf, family=binomial())')
ptm <- proc.time()
mod <- eval(parse(text=mod.string))
proc.time() - ptm

sink(paste0(path,model,"_summary.txt"))
summary(mod)
sink()

vars <- c('wd', 'JanTmin', 'Acs', 'summerTmean', 'ddAugJul', 'maxAugT')
varnms <- c('Water deficit', 'January minimum temperature', 'Average duration of cold snaps', 
						'Mean summer temperature', 'Degree days', 'Frequency of ≥ 18.3 °C temperature in August')

n.sample <- 500
iteration <- 100
modeled.y <- function(var, n.sample, iteration){
	for (i in 1:iteration){
			s.df <- ndf[sample(nrow(ndf), n.sample),]
			y <- predict(mod, s.df, type="response")
			if(i==1){
					df <- data.frame(x=s.df[,var], y=y, run=rep(i, n.sample))
					out <- df
			}else{
					df <- data.frame(x=s.df[,var], y=y, run=rep(i, n.sample))
					out <- rbind(out, df)
			}
			print(i)
	}
	return(out)
}

for(var in vars){
    out <- modeled.y(var, n.sample, iteration)
    png(paste0(outpath, var, '_2Dplot.png'), width=8, height=6, units="in", res=300)
    p <- ggplot(data=out, aes(x=x, y=y, group=factor(run)))+ geom_point(alpha=0.3,size=0.05)+
    geom_smooth(method = glm, se = FALSE) +
    theme(panel.grid.major = element_blank(), 
                panel.grid.minor = element_blank(),
                panel.background = element_blank(), 
                axis.line = element_line(colour = "black"), 
                plot.title = element_text(hjust = 0.5),
                legend.position="none")+
    labs(x='',y='',title=varnms[which(vars==var)])
    print(p)
    dev.off()
    print(paste(var, 'is done!'))
}







