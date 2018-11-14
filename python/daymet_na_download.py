# download netCDF files for daymet North America
import sys, os, traceback, datetime, time, string, glob

years = range(1991, 1995)
types = ['prcp', 'tmax', 'tmin']


try:
    filedir = '/gpfs/projects/gavingrp/dongmeic/daymet/ncfiles_na'
    for year in years:
        print(year)
        yeardir = filedir + os.sep + str(year)
        if not os.path.exists(yeardir):
            os.mkdir(yeardir)
        os.chdir(yeardir)
        for type in types:
            print(type)
            url = 'https://thredds.daac.ornl.gov/thredds/fileServer/ornldaac/1328/%s/daymet_v3_%s_%s_na.nc4' % (str(year), type, str(year))
            print(url)
            netdcffile = os.system('wget %s' % (url))

except:
    tb = sys.exc_info()[2]
    tbinfo = traceback.format_tb(tb)[0]
    pymsg = "PYTHON ERRORS:\nTraceback Info:\n" + tbinfo + "\nError Info:\n " + str(sys.exc_info())
    print(pymsg)