#!/usr/bin/env python3

import os
from netCDF4 import Dataset

DATA = '../../data/cluster/ncfiles/'
nc_files  = os.listdir(DATA)
print(nc_files)


'''
data = Dataset(DATA + nc_files[0])
print(nc_files)
print(data.file_format)

print(data.dimensions.keys())
for key in data.dimensions.keys():
    print('%s:' % key)
    print(data.dimensions[key])

print(data.variables.keys())
for key in data.variables.keys():
    print('%s:' % key)
    print(data.variables[key])
'''

