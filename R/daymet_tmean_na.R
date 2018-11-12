# cannot write out long vectors

library(ncdf4)
library(lattice)
library(RColorBrewer)

ncpath <- "/gpfs/projects/gavingrp/dongmeic/daymet/ncfiles_na/"
out <- "/gpfs/projects/gavingrp/dongmeic/beetle/output/maps/"
years <- 1996:2015

# 1 - run in bash; 0 - run in R
if(1){
	args <- commandArgs(trailingOnly=T)
	print(paste('args:', args))
	print("Starting...")
	yr <- as.numeric(args[1])
	print(paste('year:', years[yr]))
}

ptm <- proc.time()
ncin <- nc_open(paste0(ncpath, years[yr], "/daymet_v3_tmax_", years[yr], "_na.nc4"))
tmax <- ncvar_get(ncin, "tmax")
ncin <- nc_open(paste0(ncpath, years[yr], "/daymet_v3_tmin_", years[yr], "_na.nc4"))
tmin <- ncvar_get(ncin, "tmin")

# get variables
dname <- "tmin"
fillvalue <- ncatt_get(ncin,dname,"_FillValue")$value
print(fillvalue)
dunits <- ncatt_get(ncin,dname,"units")$value

tmax[tmax==fillvalue] <- NA
tmin[tmin==fillvalue] <- NA

# get dimension variables and attributes
x <- ncvar_get(ncin, varid="x"); nx <- length(x)
x_long_name <- ncatt_get(ncin, "x", "long_name")$value
x_standard_name <- ncatt_get(ncin, "x", "standard_name")$value

y <- ncvar_get(ncin, varid="y"); ny <- length(y)
y_long_name <- ncatt_get(ncin, "x", "long_name")$value
y_standard_name <- ncatt_get(ncin, "x", "standard_name")$value

time <- ncvar_get(ncin, varid="time"); nt <- length(time)
tunits <- ncatt_get(ncin,"time","units")$value

# calculate mean temperature
var3d <- array(NA, dim=c(nx, ny, nt))
var3d <- (tmax+tmin)/2

# quick maps to check absolute data
n <- nt
var_slice_3d <- var3d[,,n]
grid <- expand.grid(x=x, y=y)
cutpts <- c(-50,-40,-30,-20,-10,0,10,20,30,40,50)
png(file=paste0(out,"daily_mean_temperature_daymet","_",years[yr],"_",n,".png"))
levelplot(var_slice_3d ~ x * y, data=grid, at=cutpts, cuts=11, pretty=T, 
          col.regions=(rev(brewer.pal(10,"RdBu"))))
dev.off()

var3d[is.na(var3d)] <- fillvalue

# get longitude and latitude and attributes
lon <- ncvar_get(ncin,"lon"); 
lon_units <- ncatt_get(ncin, "lon", "units")$value
lon_lname <- ncatt_get(ncin, "lon", "long_name")$value
lon_stdname <- ncatt_get(ncin, "lon", "standard_name")$value
lat <- ncvar_get(ncin,"lat"); 
lat_units <- ncatt_get(ncin, "lat", "units")$value
lat_lname <- ncatt_get(ncin, "lat", "long_name")$value
lat_stdname <- ncatt_get(ncin, "lat", "standard_name")$value

# get time variables
yearday <- ncvar_get(ncin, "yearday")
time_bnds <- ncvar_get(ncin, "time_bnds")

# get CRS attributes
crs_grid_mapping_name <- ncatt_get(ncin, projname, "grid_mapping_name")$value
crs_longitude_of_central_meridian <- ncatt_get(ncin, projname, "longitude_of_central_meridian")$value
crs_latitude_of_projection_origin <- ncatt_get(ncin, projname, "latitude_of_projection_origin")$value
crs_false_easting <- ncatt_get(ncin, projname, "false_easting")$value
crs_false_northing <- ncatt_get(ncin, projname, "false_northing")$value
crs_standard_parallel <- ncatt_get(ncin, projname, "standard_parallel")$value
crs_semi_major_axis <- ncatt_get(ncin, projname, "semi_major_axis")$value
crs_inverse_flattening <- ncatt_get(ncin, projname, "inverse_flattening")$value

# close the input file
nc_close(ncin)

# write out netCDF file
bounds <- c(1,2)
# define dimensions
xdim <- ncdim_def("x",units="m",longname="x coordinate of projection",as.double(x))
ydim <- ncdim_def("y",units="m",longname="y coordinate of projection",as.double(y))
tdim <- ncdim_def("time",units=tunits,longname="time",as.double(time))
bdim <- ncdim_def("nv",units="1",longname=NULL,as.double(bounds))
dlname <- "time_bnds"
bnds_def <- ncvar_def("time_bnds",tunits,list(bdim,tdim),NULL,dlname,prec="double")

# define common variables
dlname <- "Longitude of cell center"
lon_def <- ncvar_def("lon","degrees_east",list(xdim,ydim),NULL,dlname,prec="double")
dlname <- "Latitude of cell center"
lat_def <- ncvar_def("lat","degrees_north",list(xdim,ydim),NULL,dlname,prec="double")
projname <- "lambert_conformal_conic"
dlanme <- "lambert conformal conic"
proj_def <- ncvar_def(projname,"1",NULL,NULL,longname=dlname,prec="char")

# define variable
dlname <- "daily mean temperature"
var_def <- ncvar_def("tmean",dunits,list(xdim,ydim,tdim),fillvalue,dlname,prec="float")

# create netCDF file and put array
ncfname <- paste0(ncpath, years[yr], "/daymet_v3_tmean_", years[yr], "_na.nc4")
ncout <- nc_create(ncfname,list(lon_def,lat_def,var_def,bnds_def,proj_def),force_v4=TRUE,verbose=FALSE)

# put additional attributes into dimension and data variables
ncatt_put(ncout,"x","long_name",x_long_name)
ncatt_put(ncout,"x","standard_name",x_standard_name)
ncatt_put(ncout,"y","long_name",y_long_name)
ncatt_put(ncout,"y","standard_name",y_standard_name)
ncatt_put(ncout,"time","long_name","time")
ncatt_put(ncout,"time","calendar","standard")
ncatt_put(ncout,"time","units",tunits)
ncatt_put(ncout,"time","bounds","time_bnds")

ncatt_put(ncout,"lon","units",lon_units)
ncatt_put(ncout,"lon","long_name",lon_lname)
ncatt_put(ncout,"lon","standard_name",lon_stdname)
ncatt_put(ncout,"lat","units",lat_units)
ncatt_put(ncout,"lat","long_name",lat_lname)
ncatt_put(ncout,"lat","standard_name",lat_stdname)

ncatt_put(ncout,projname,"grid_mapping_name",crs_grid_mapping_name)
ncatt_put(ncout,projname,"longitude_of_central_meridian",crs_longitude_of_central_meridian)
ncatt_put(ncout,projname,"latitude_of_projection_origin",crs_latitude_of_projection_origin)
ncatt_put(ncout,projname,"false_easting",crs_false_easting)
ncatt_put(ncout,projname,"false_northing",crs_false_northing)
ncatt_put(ncout,projname,"standard_parallel",crs_standard_parallel)
ncatt_put(ncout,projname,"semi_major_axis",crs_semi_major_axis)
ncatt_put(ncout,projname,"inverse_flattening",crs_inverse_flattening)

# put variables
ncvar_put(ncout,lon_def,lon)
ncvar_put(ncout,lat_def,lat)
ncvar_put(ncout,tdim,time)
ncvar_put(ncout,bnds_def,time_bnds)
ncvar_put(ncout,var_def,var3d)

# add global attributes
ncatt_put(ncout,0,"start_year",years[yr])
ncatt_put(ncout,0,"source","Daymet Software Version 3.0")
ncatt_put(ncout,0,"Version_software","Daymet Software Version 3.0")
ncatt_put(ncout,0,"Version_data","Daymet Data Version 3.0")
ncatt_put(ncout,0,"Conventions","CF-1.6")
ncatt_put(ncout,0,"citation","Please see http://daymet.ornl.gov/ for current Daymet data citation information")
ncatt_put(ncout,0,"references","Please see http://daymet.ornl.gov/ for current information on Daymet references")
history <- paste("D. Chen", date(), sep=", ")
ncatt_put(ncout,0,"history",history)

# close the file, writing data to disk
nc_close(ncout)
print(paste("processed",year,"..."))

proc.time() - ptm

print("all done!")
save.image(file="/gpfs/projects/gavingrp/dongmeic/beetle/output/RData/daymet_na.RData")
