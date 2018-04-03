# Created by Dongmei Chen
# To generate ncfiles for long-term historic data and map the historic data

print("load libraries...")
library(ncdf4)
library(ggplot2)
library(lattice)
library(grid)
library(raster)
#install.packages("rgdal", repos='http://cran.us.r-project.org')
library(rgdal)
library(animation)
library(parallel)
library(doParallel)
library(foreach)
registerDoParallel(cores=55)

# path
infile <- "predictions_no_beetle"
csvpath <- "/projects/bonelab/dongmeic/beetle/csvfiles/"
inputfile <- paste0("/projects/bonelab/dongmeic/sdm/data/cluster/historic/",infile,".csv")
out <- "/projects/bonelab/dongmeic/beetle/output/20180330/"
setwd("/projects/bonelab/dongmeic/beetle/output/20180330")

# open points netCDF file to get dimensions, etc.
ncpath <- "/projects/bonelab/dongmeic/beetle/ncfiles/na10km_v2/"
ncin <- nc_open(paste(ncpath,"na10km_v2.nc",sep=""))
x <- ncvar_get(ncin, varid="x"); nx <- length(x)
y <- ncvar_get(ncin, varid="y"); ny <- length(y)
lon <- ncvar_get(ncin, varid="lon")
lat <- ncvar_get(ncin, varid="lat")
nc_close(ncin)

# time
year <- 1904:2015
nt <- length(year)
tunits <- "year"

# define dimensions
xdim <- ncdim_def("x",units="m",longname="x coordinate of projection",as.double(x))
ydim <- ncdim_def("y",units="m",longname="y coordinate of projection",as.double(y))
tdim <- ncdim_def("year",units=tunits,longname="year",as.integer(year))

# define common variables
fillvalue <- 1e32
dlname <- "Longitude of cell center"
lon_def <- ncvar_def("lon","degrees_east",list(xdim,ydim),NULL,dlname,prec="double")
dlname <- "Latitude of cell center"
lat_def <- ncvar_def("lat","degrees_north",list(xdim,ydim),NULL,dlname,prec="double")
projname <- "lambert_azimuthal_equal_area"
proj_def <- ncvar_def(projname,"1",NULL,NULL,longname=dlname,prec="char")
dlname <- "year"
time_def <- ncvar_def(dlname,tunits,list(tdim),NULL,dlname,prec="integer")


# mpb
csvfile <- "na10km_presence_details_all_2.csv"
print("read beetle presence data")
mpb_recent <- read.csv(paste0(csvpath, csvfile))
mpb_recent$xy <- paste0(mpb_recent$x, "-", mpb_recent$y)
mpb_1 <- mpb_recent[,c("xy", "prs_2015", "prs_2014", "prs_2013", "prs_2012", "prs_2011",
                  "prs_2010", "prs_2009", "prs_2008", "prs_2007", "prs_2006", "prs_2005",
                  "prs_2004", "prs_2003", "prs_2002", "prs_2001")]
xydata <- mpb_recent[,c("tlon", "tlat", "telev", "x", "y", "xy")]
mpb_historic <- read.csv(inputfile)
if (names(mpb_historic)[1] == 'X') {
	mpb_historic <- mpb_historic[, -1]
}
mpb_historic$xy <- paste0(mpb_historic$x, "-", mpb_historic$y)
mpb_2 <- mpb_historic[,!(names(mpb_historic) %in% c("x", "y"))]
indata <- merge(mpb_1, mpb_2, by="xy", all=T)
indata <- indata[, -grep("probs", colnames(indata))]
indata <- indata[, rev(seq_len(ncol(indata)))]
indata <- merge(xydata, indata, by="xy", all=T)
indata <- indata[,!(names(indata) %in% c("xy"))]
indata[is.na(indata)] <- 0
str(indata)

print("done!")

ncfname <- paste0(ncpath,"prs/na10km_v2_mpb_",infile,".nc")
dname <- "mpb_prs"
dlname <- "Mountain pine beetle presence"
dunits <- "binary"

# reshape
print("set j and k index")
j2 <- sapply(indata$x, function(z) which.min(abs(x-z)))
k2 <- sapply(indata$y, function(z) which.min(abs(y-z)))
head(cbind(indata$x,indata$y,j2,k2))
print("done!")

print("create temporary array")
nobs <- dim(indata)[1]
m <- rep(1:nt,each=nobs)
temp_array <- array(fillvalue, dim=c(nx,ny,nt))
temp_array[cbind(j2,k2,m)] <- as.matrix(indata[1:nobs,6:117])
print("done!")

# create netCDF file and put data
print("define the netCDF file")
var_def <- ncvar_def(dname,dunits,list(xdim,ydim,tdim),fillvalue,dlname,prec="float")
ncout <- nc_create(ncfname,list(lon_def,lat_def,var_def,proj_def),force_v4=TRUE, verbose=FALSE)
print("done!")

# put additional attributes into dimension and data variables
print("writing output")
ncatt_put(ncout,"x","axis","X")
ncatt_put(ncout,"x","standard_name","projection_x_coordinate")
ncatt_put(ncout,"x","grid_spacing","10000 m")
ncatt_put(ncout,"x","_CoordinateAxisType","GeoX")
ncatt_put(ncout,"y","axis","Y")
ncatt_put(ncout,"y","standard_name","projection_y_coordinate")
ncatt_put(ncout,"y","grid_spacing","10000 m")
ncatt_put(ncout,"y","_CoordinateAxisType","GeoY")

ncatt_put(ncout,projname,"name",projname)
ncatt_put(ncout,projname,"long_name",projname)
ncatt_put(ncout,projname,"grid_mapping_name",projname)
ncatt_put(ncout,projname,"longitude_of_projection_origin",-100.0)
ncatt_put(ncout,projname,"latitude_of_projection_origin",50.0)
ncatt_put(ncout,projname,"_CoordinateTransformType","Projection")
ncatt_put(ncout,projname,"_CoordinateAxisTypes","GeoX GeoY")
na10km_projstr <- "+proj=laea +lon_0=-100 +lat_0=50 +x_0=0 +y_0=0 +ellps=WGS84 +datum=WGS84 +units=m +no_defs"
ncatt_put(ncout,projname,"CRS.PROJ.4",na10km_projstr)

# put variables
ncvar_put(ncout,lon_def,lon)
ncvar_put(ncout,lat_def,lat)
ncvar_put(ncout,time_def,year)
ncvar_put(ncout,var_def,temp_array)

# add global attributes
ncatt_put(ncout,0,"title","Predicted yearly beetle presence onto the na10km_v2 10-km Grid")
ncatt_put(ncout,0,"institution","Dept. Geography; Univ_ Oregon")
ncatt_put(ncout,0,"source","generated by interplr.f90")
history <- paste("D.Chen", date(), sep=", ")
ncatt_put(ncout,0,"history",history)
ncatt_put(ncout,0,"base_period","1904-2015")

# close the file, writing data to disk
nc_close(ncout)
print("done!")

# create a ncfile for the probability data
print("create a ncfile for beetle probability")
year <- 2000:1904
nt <- length(year)
tdim <- ncdim_def("year",units=tunits,longname="year",as.integer(year))
dlname <- "year"
tunits <- "year"
time_def <- ncvar_def(dlname,tunits,list(tdim),NULL,dlname,prec="integer")

ncfname <- paste0(ncpath,"prs/na10km_v2_mpb_",infile,"_probability.nc")
dname <- "mpb_prs"
dlname <- "Mountain pine beetle presence probability"
dunits <- "decimal between 0 and 1"

indata <- mpb_historic[, -grep("preds_", colnames(mpb_historic))]
indata <- indata[, rev(seq_len(ncol(indata)))]
indata <- indata[,!(names(indata) %in% c("x", "y"))]
indata <- merge(xydata, indata, by="xy", all=T)
indata <- indata[,!(names(indata) %in% c("xy"))]
indata[is.na(indata)] <- fillvalue

print("create temporary array")
temp_array <- array(fillvalue, dim=c(nx,ny,nt))
m <- rep(1:nt,each=nobs)
temp_array[cbind(j2,k2,m)] <- as.matrix(indata[1:nobs,6:102])
print("done!")

# create netCDF file and put data
print("define the netCDF file")
var_def <- ncvar_def(dname,dunits,list(xdim,ydim,tdim),fillvalue,dlname,prec="float")
ncout <- nc_create(ncfname,list(lon_def,lat_def,var_def,proj_def),force_v4=TRUE, verbose=FALSE)
print("done!")

# put additional attributes into dimension and data variables
print("writing output")
ncatt_put(ncout,"x","axis","X")
ncatt_put(ncout,"x","standard_name","projection_x_coordinate")
ncatt_put(ncout,"x","grid_spacing","10000 m")
ncatt_put(ncout,"x","_CoordinateAxisType","GeoX")
ncatt_put(ncout,"y","axis","Y")
ncatt_put(ncout,"y","standard_name","projection_y_coordinate")
ncatt_put(ncout,"y","grid_spacing","10000 m")
ncatt_put(ncout,"y","_CoordinateAxisType","GeoY")

ncatt_put(ncout,projname,"name",projname)
ncatt_put(ncout,projname,"long_name",projname)
ncatt_put(ncout,projname,"grid_mapping_name",projname)
ncatt_put(ncout,projname,"longitude_of_projection_origin",-100.0)
ncatt_put(ncout,projname,"latitude_of_projection_origin",50.0)
ncatt_put(ncout,projname,"_CoordinateTransformType","Projection")
ncatt_put(ncout,projname,"_CoordinateAxisTypes","GeoX GeoY")
na10km_projstr <- "+proj=laea +lon_0=-100 +lat_0=50 +x_0=0 +y_0=0 +ellps=WGS84 +datum=WGS84 +units=m +no_defs"
ncatt_put(ncout,projname,"CRS.PROJ.4",na10km_projstr)

# put variables
ncvar_put(ncout,lon_def,lon)
ncvar_put(ncout,lat_def,lat)
ncvar_put(ncout,time_def,year)
ncvar_put(ncout,var_def,temp_array)

# add global attributes
ncatt_put(ncout,0,"title","Predicted yearly beetle presence probability onto the na10km_v2 10-km Grid")
ncatt_put(ncout,0,"institution","Dept. Geography; Univ_ Oregon")
ncatt_put(ncout,0,"source","generated by interplr.f90")
history <- paste("D.Chen", date(), sep=", ")
ncatt_put(ncout,0,"history",history)
ncatt_put(ncout,0,"base_period","1904-2000")

# close the file, writing data to disk
nc_close(ncout)
print("done!")

# map the predicted beetle presence
print("read the predicted presence data")
btl_ncfile <- paste0(ncpath,"prs/na10km_v2_mpb_",infile,".nc")
ncin_btl <- nc_open(btl_ncfile)
print(ncin_btl)
btl <- ncvar_get(ncin_btl,"mpb_prs")
nc_close(ncin_btl)
print("done!")

print("export time-series beetle grid")
years = 1904:2015; nyr <- length(years)
df <- data.frame(time=years)
value <- vector()
for (yr in 1:nyr){
	btl_slice <- btl[,,yr]
	btl.l <- length(btl_slice[which(btl_slice==1)])
	value <- c(value, btl.l)
	print(years[yr])
}
df <- cbind(df, value)
write.csv(df, paste0(out, "beetle_",infile,".csv"), row.names=FALSE)
print("done!")

df <- read.csv(paste0(out, "beetle_",infile,".csv"))
print("plot time-series beetle grids")
rect <- data.frame(xmin=2005, xmax=2011, ymin=-Inf, ymax=Inf)
png(paste0(out,"beetle_",infile,".png"), width=10, height=4, units="in", res=300)
ggplot(data = df, aes(x = time, y = value/1000)) + geom_line(size=1.2)+ 
  labs(x="Year", y=substitute(paste("Number of grids (",10^3,")")))+ geom_point(size=2) +
  geom_rect(data=rect, aes(xmin=xmin, xmax=xmax, ymin=ymin, ymax=ymax),color="pink",alpha=0.2,inherit.aes = FALSE)
dev.off()
print("done!")

print("read shapefiles for mapping")
csvpath <- "/projects/bonelab/dongmeic/beetle/shapefiles"
canada.prov <- readOGR(dsn = csvpath, layer = "na10km_can_prov")
us.states <- readOGR(dsn = csvpath, layer = "na10km_us_state")
crs <- proj4string(us.states)
lrglakes <- readOGR(dsn = csvpath, layer = "na10km_lrglakes")
proj4string(lrglakes) <- crs
print("done!")

print("mapping historical data")
myColors <- c('grey', 'red')
myKey <- list(text=list(lab=c("North America","Beetle affected"), cex=c(1.2,1.2)), 
              rectangles=list(col = myColors), space="inside", width = 0.5, columns=1)
foreach(yr=1:length(years)) %dopar%{
	print(paste("processing", years[i]))
	png(paste0("beetle_expansion_",years[i],".png"), width=4, height=8, units="in", res=300)
	par(mfrow=c(1,1),xpd=FALSE,mar=c(0.2,0.2,0.2,0.2))
	btl_slice <- btl[,,i]
	levelplot(btl_slice ~ x * y, data=grid, xlim=c(-2050000,20000), ylim=c(-2000000,2000000),
          par.settings = list(axis.line = list(col = "transparent")), scales = list(draw = FALSE), margin=F, 
          col.regions=myColors, main=list(label=paste("Beetle range in ", toString(years[i]), sep=""), cex=1.5), 
          xlab="",ylab="", colorkey = FALSE, key=myKey)+
          layer(sp.polygons(canada.prov, lwd=0.8, col='dimgray'))+
          layer(sp.polygons(us.states, lwd=0.8, col='dimgray'))+
          layer(sp.polygons(lrglakes, lwd=0.8, col='lightblue'))        
	dev.off()
}
print("done!")
print("make an animation")
im.convert("beetle_expansion_*.png",output="beetle_expansion.gif")
print("all done!")

# time-series climate variables with beetle grids
# climate variables selected: 
# 1: annual mean monthly average of daily mean temperature in the past water year - mat
# 2: mean of monthly average of daily mean temperature from April to August - mtaa
# 3: monthly average of daily mean temperature in August - mta
# 4: minimum of monthly average of daily minimum temperature between Dec and Feb - ntw
# 5: monthly average of daily minimum temperature in October - nto
# 6: monthly average of daily minimum temperature in January - ntj
# 7: monthly average of daily minimum temperature in March - ntm
# 8: monthly average of daily maximum temperature in August - xta
# 9: mean annual precipitation - map; use precipitation data from January to December in the past water year
# 10: cumulative precipitation from June to August in current and previous year - cpja; use precipitation data in the previous and current year
# 11: precipitation from June to August in previous year - pja;
# 12: cumulative precipitation from October to September in current and previous year - cpos;
# 13: precipitation from October to September in previous year - pos;
# 14: growing season precipitation in current year - gsp;
# 15: variability of growing season precipitation - vgp

varpath <- "/projects/bonelab/dongmeic/beetle/ncfiles/na10km_v2/ts/var/"
vars <- c("mat", "mtaa", "xta", "mta", "ntw", "nto", "ntj", "ntm", "map", "cpja", "pja","gsp", "pos", "cpos")

years = 1904:2015; nyr <- length(years)
df <- data.frame(time=years)

for (i in 1:length(vars)){
	varnm <- vars[i]
	print(paste("processing variable", varnm))
	ncfile <- paste0(varpath, "na10km_v2_", varnm, "_1903.2014.3d.nc")
	ncin <- nc_open(ncfile)
	print(ncin)
	var <- ncvar_get(ncin,varnm)
	nc_close(ncin)
	value <- vector()
	for (yr in 1:nyr){
		var_slice <- var[,,yr]
		btl_slice <- btl[,,yr]
		val <- mean(var_slice[which(btl_slice==1)])
		value <- c(value, val)
		print(years[yr])
	}
	df <- cbind(df, value)
	names(df)[i+1] <- varnm
}
write.csv(df, paste0(out, "time_series_climate.csv"), row.names=FALSE)


