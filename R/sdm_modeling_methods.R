library(biomod2)

inpath <- "/gpfs/projects/gavingrp/dongmeic/beetle/output/tables/input"
year <- 1998
df <- read.csv(paste0(inpath, '/input_data_', year, '.csv'))
# for (year in 1999:2015){
#   ndf <- read.csv(paste0(inpath, '/input_data_', year, '.csv'))
#   df <- rbind(df, ndf)
#   print(year)
# }
head(df)

myRespName <- 'btl_t'
myResp <- as.numeric(df[,myRespName])
myRespXY <- df[,c('x','y')]
myExpl <- df[,c('etopo1', 'age', 'density', 'JanTmin', 'MarTmin', 'summerTmean', 'AugTmax', 'vgt',
                'summerP0', 'Tvar', 'PPT', 'wd', 'mi', 'btl_t1', 'btl_t2', 'sum9_t1', 'sum9_t2')]
myBiomodData <- BIOMOD_FormatingData(resp.var = myResp, 
                                     expl.var = myExpl, 
                                     resp.xy = myRespXY,
                                     resp.name = myRespName)
plot(myBiomodData)
myBiomodOption <- BIOMOD_ModelingOptions()
myBiomodModelOut <- BIOMOD_Modeling(myBiomodData,
                                    models=c('SRE', 'CTA', 'RF', 'MARS', 'FDA'),
                                    models.options = myBiomodOption,
                                    NbRunEval = 3,
                                    DataSplit = 80,
                                    Prevalence = 0.5,
                                    VarImport = 3,
                                    models.eval.meth = c('TSS', 'ROC'),
                                    SaveObj = TRUE,
                                    rescal.all.models = TRUE,
                                    do.full.models = FALSE,
                                    modeling.id = paste(myRespName,"FirstModeling",sep=""))
myBiomodModelOut
myBiomodModelEval <- get_evaluations(myBiomodModelOut)
dimnames(myBiomodModelEval)

myBiomodModelEval["TSS", "Testing.data", "RF",,]
myBiomodModelEval["ROC", "Testing.data",,,]
get_variables_importance(myBiomodModelOut)

myBiomodEM <- BIOMOD_EnsembleModeling(
  modeling.output = myBiomodModelOut,
  chosen.models = 'all',
  em.by= 'all',
  eval.metric = c('TSS'),
  eval.metric.quality.threshold = c(0.7),
  prob.mean = T,
  prob.cv = T,
  prob.ci = T,
  prob.ci.alpha = 0.05,
  prob.median = T,
  committee.averaging = T,
  prob.mean.weight = T,
  prob.mean.weight.decay = 'proportional')

myBiomodEM
get_evaluations(myBiomodEM)

myBiomodProj <- BIOMOD_Projection(
  modeling.output = myBiomodModelOut,
  new.env = myExpl,
  proj.name = 'current',
  selected.models = 'all',
  binary.meth = 'TSS',
  compress='xz',
  clamping.mask = F,
  output.format = '.grd')

myBiomodProj

myCurrentProj <- get_predictions(myBiomodProj)
myCurrentProj

myBiomodProjFuture <- BIOMOD_Projection(
  modeling.output = myBiomodModelOut,
  new.env = myExplFuture,
  proj.name = 'future',
  selected.models = 'all',
  binary.meth = 'TSS',
  compress = 'xz',
  clamping.mask = T,
  output.format = '.grd')

plot(myBiomodProjFuture, str.grep ='MARS')

myBiomodEF <- BIOMOD_EnsembleForecasting(
  EM.output = myBiomodEM,
  projection.output = myBiomodProj)

myBiomodEF
plot(myBiomodEF)