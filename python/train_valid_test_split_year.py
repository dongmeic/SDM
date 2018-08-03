#!/usr/bin/env python3
import os
import re
import sys

import numpy as np
import pandas as pd

#DATA_DIR = '../data'
DATA_DIR = '/gpfs/projects/gavingrp/dongmeic/beetle/output/tables/backcasting'
OUTPUT_DIR = '%s/Xy_year_split_data' % DATA_DIR
INPUT_FILE_FORMAT = r'input_data_[0-9]{4}\.csv$'
years = [yr for yr in range(1996,2011)]
test_years = years[0:3]
valid_years = years[3:6]
train_years = years[6:]
    
def main():
    input_files = [f for f in os.listdir(DATA_DIR)
                   if re.match(INPUT_FILE_FORMAT, f)]
    for file_name in input_files:
        file_path = '%s/%s' % (DATA_DIR, file_name)
        year = file_path.split('_')[-1].replace('.csv', '')
        dat = pd.read_csv(file_path)
        split_data = split_data_year(dat, year, 'btl_t')
        if not save_files(year, split_data):
            print('Error saving files')
            sys.exit(1)
    print('Program completed.')

def split_data_year(dat, year, response):
		data = dat.copy()
		if int(year) in train_years:
			X_train, y_train = split_predictors_response(data, response)
			print_data_split(X_train, y_train, 'train')
			return [[X_train, y_train]]
		else:
		    if int(year) in valid_years:
		        X_valid, y_valid = split_predictors_response(data, response)
		        print_data_split(X_valid, y_valid, 'valid')
		        return [[X_valid, y_valid]]
		    else:
		    		if int(year) in test_years:
		    				X_test,  y_test  = split_predictors_response(data, response)
		    				print_data_split(X_test, y_test, 'test')
		    				return [[X_test, y_test]]

def split_predictors_response(dat, response):
    data = dat.copy()
    y = data.loc[:, response]
    y = pd.DataFrame(y)
    X = data.drop(response, axis=1)
    return X, y
   
def save_files(year, split_data):
    if not os.path.exists(OUTPUT_DIR):
        os.mkdir(OUTPUT_DIR)
    if int(year) in train_years:
    		set_name = 'train'
    else:
    		if int(year) in valid_years:
    				set_name ='valid'
    		else:
    				if int(year) in test_years:
    						set_name ='test'
    xy_names = ['X', 'y']
    for data_set in split_data:
        for xy, xy_name in zip(data_set, xy_names):
            path = '%s/%s_%s_%s.csv' % (OUTPUT_DIR, xy_name, set_name, year)
            print('Writing data to ', path)
            xy.to_csv(path, index=False)
    return True

def print_data_split(X,y,set):
    print('Data split into:\n X: %s  y: %s in the %s data set'
          % (X.shape, y.shape, set))
    print_ranges(X)

    
def print_ranges(data):
        print(' x range: [%s, %s]\ty range: [%s, %s]'
              % (data.x.min(), data.x.max(), data.y.min(), data.y.max()))
              
if __name__ == '__main__':
    main()