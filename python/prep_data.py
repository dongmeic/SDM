#!/usr/bin/env python3

#===============================================================================
#
# prep_data.py
#
# Takes raw data (climatic_variables_longlat_var.csv by default) and:
#   - removes redundant columns
#   - restricts data to the bounding box in which  <MASK> variable is present
#     (<MASK> is 'btl_mat_mask.2' by default)
#   - splits the resulting data into training, validation, and test sets
#     according to each of the three regimes (<random>, <internal> and <edge>),
#   - Outputs are written to:
#     <DATA_PATH>/
#       random/
#         X_train.csv, X_valid.csv, X_test.csv,
#         y_train.csv, y_valid.csv, y_test.csv
#       internal/
#         X_train.csv, X_valid.csv, X_test.csv,
#         y_train.csv, y_valid.csv, y_test.csv
#       edge/
#         n/
#           X_train.csv, X_valid.csv, X_test.csv,
#           y_train.csv, y_valid.csv, y_test.csv
#         s/...(as previous)
#         e/...
#         w/..
#       year/
#         X_train.csv, X_valid.csv, X_test.csv,
#         y_train.csv, y_valid.csv, y_test.csv
# Usage:
#   prep_data.py -e ENV -d DATA_PATH [-i INFILE] [-m MASK] [-c COORD_TYPE] \
#     [-o OUTFILE_PREFIX] [-s SPLIT_METHOD]
#
#   -e ENV: ['dev' | 'cluster'] environment to run code in
#   -d DATA_PATH: absolute or relative path to where data files are stored
#   -i INFILE: name of file from which data are to be read
#      (defaults to climatic_variables_longlat_var.csv
#   -m MASK: column to be used as a mask to select the bounding box,
#      'btl_mat_mask.2' by default; returns data within the x, y or lat, lon
#      range of the MASK column.
#   -c COORD_TYPE: ['xy' | 'lon_lat'] columns to use to select range ('xy' by
#      default)
#   -o OUTFILE_PREFIX: (none by default) if specified outputs will be like:
#      prefix_X_train.csv, etc
#   -s SPLIT_METHOD: ['random' | 'internal' | 'edge' | 'year' | 'all'] method
#      used to split data into train, validation, and test sets ('all' by
#      default)
#   Examples:
#     ./prep_data.py "../data/"
#
#===============================================================================

import argparse
import numpy as np
import os
import pandas as pd
import sys
from time import time

# Our modules
import data_manipulations as manip
import split_data as split

# Default args
ENV = 'dev'
DATA_PATH = '../data/'
INFILE = 'climatic_variables_longlat_var_v2.csv'
MASK = 'beetle' #'studyArea'
COORD_TYPE = 'xy'
OUTFILE_PREFIX = ''
SPLIT_METHOD = 'year'
CELL_DIM = 10000 # dimensions of raster cell
PROPORTIONS = [0.7, 0.15, 0.15] # train, valid, split
EARLIEST_YEAR = 2000 #1903 
LATEST_YEAR   = 2014

predictor_name_map = {
    'cpja_slice_msk': 'precip_JunAug',
    'cpos_slice_msk': 'precip_OctSep',
    'gsp_slice_msk':  'precip_growingSeason',
    'map_slice_msk':  'precip_meanAnnual',
    'mat_slice_msk':  'meanTemp_Annual',
    'mta_slice_msk':  'meanTemp_Aug',
    'mtaa_slice_msk': 'meanTemp_AprAug',
    'ntj_slice_msk':  'meanMinTemp_Jan',
    'ntm_slice_msk':  'meanMinTemp_Mar',
    'nto_slice_msk':  'meanMinTemp_Oct',
    'ntw_slice_msk':  'meanMinTemp_DecFeb',
    'pja_slice_msk':  'precipPrevious_JunAug',
    'pos_slice_msk':  'precipPrevious_OctSep',
    'vgp_slice_msk':  'varPrecip_growingSeason',
    'xta_slice_msk':  'meanMaxTemp_Aug',
    'etopo1':         'elev_etopo1',
    'srtm30':         'elev_srtm30',
    'mask':           'studyArea'}


def read_input():
    p = argparse.ArgumentParser(
        description=('Takes raw data, removes extraneous data, and splits into '
                     'training, validataion, and test sets'))
    p.add_argument(
        '-e', '--env',
        dest='env',
        help='["dev" | "cluster"] environment to run code in')
    p.add_argument(
        '-d', '--data_path',
        dest='data_path',
        help='absolute or relative path to where data files are stored')
    p.add_argument(
        '-i', '--infile',
        dest='infile',
        help=('name of file from which data are to be read (defaults to '
              '"climatic_variables_longlat_var.csv")'))
    p.add_argument(
        '-m', '--mask',
        dest='mask',
        help=('column to be used as a mask to select the bounding box, '
              '("btl_mat_mask.2" by default); returns data within the x, y or '
              'lat, lon range of the MASK column'))
    p.add_argument(
        '-c', '--coord_type',
        dest='coord_type',
        help=('["xy" | "lon_lat"] columns to use to select range ("xy" by '
              'default)'))
    p.add_argument(
        '-o', '--outfile_prefix',
        dest='outfile_prefix',
        help='prefix added to each of the output files (none by default)')
    p.add_argument(
        '-s', '--split',
        dest='split_method',
        help=('["random" | "internal" | "edge" | "year" | "all"] method used '
              'to split data into train, validation, and test sets ("all" by '
              'default)'))
    return p.parse_args()


def main(options):
    start_time = time()

    # Parse args and set up
    (env, data_path, infile, mask,
     coord_type, outfile_prefix, split_method) = parse_args(options)

    print('Loading data from %s%s...' % (data_path, infile))
    data = load_data(data_path, infile)
    data = reduce_data(data, mask, coord_type)
    restructured_outfile = data_path + 'climaticVariablesRestructured.csv'

    print('Saving restructured data to %s...' % restructured_outfile)
    data.to_csv(restructured_outfile, index=False)

    # write mini version for testing:
    #mini = data.loc[data.year <= 2002, :]
    #mini_file = data_path + 'climaticVariablesMini.csv'

    #print('Saving mini data set to %s...' % mini_file)
    #mini.to_csv(mini_file, index=False)

    split_and_write_data(data,
                         mask,
                         split_method,
                         CELL_DIM,
                         PROPORTIONS,
                         data_path,
                         outfile_prefix)

    elapsed = time() - start_time
    print('Elapsed time %.3f minutes' % (elapsed / 60))


def parse_args(options):
    env = options.env or ENV
    data_path = options.data_path or DATA_PATH
    data_path += env + '/'
    infile = options.infile or INFILE
    mask = options.mask or MASK
    coord_type = options.coord_type or COORD_TYPE
    outfile_prefix = options.outfile_prefix or OUTFILE_PREFIX
    split_method = options.split_method or SPLIT_METHOD

    if split_method == 'all':
        split_method = ['random', 'internal', 'edge']
    else:
        split_method = [split_method]
        
    linesep()
    print(
        'Running with arguments:\nenv:            %s\ndata_path:      %s'
        '\ninfile:         %s\nmask:           %s\ncoord_type:     %s'
        '\noutfile_prefix: "%s"\nsplit_method:   %s'
        % (env, data_path, infile, mask, coord_type, outfile_prefix,
           split_method))
    linesep()
    return (
        env, data_path, infile, mask, coord_type, outfile_prefix, split_method)


def linesep():
    print('_' * 75 + '\n')
    

def load_data(data_path, infile):
    data = pd.read_csv(data_path + infile)
    if 'Unnamed: 0' in list(data):
        data = data.drop(['Unnamed: 0'], axis=1)
    return data
        

def reduce_data(data, mask, coord_type):
    print('Initial data shape: ', data.shape)
    print('Reducing mask columns...')
    data = manip.reduce_masks(['btl', 'vgt'], data)
    data = manip.reduce_masks(['vgt'], data)
    
    print('Separating static data...')
    static_fields = ['etopo1', 'lat', 'lon', 'mask', 'srtm30', 'x', 'y']
    static_df = data[static_fields]
    data = data.drop(static_fields, axis=1)

    print('Separating data by year...')
    yearly_dfs = []
    source_df = data.copy()

    for year in range(EARLIEST_YEAR + 1, LATEST_YEAR + 1):
        df, source_df = manip.make_single_year_dataframe(
            source_df, year, static_df)
        yearly_dfs.append(df)

    df_out, _ = manip.make_single_year_dataframe(
        source_df, EARLIEST_YEAR, static_df)

    print('Merging data back together...')
    for df in yearly_dfs:
        df_out = df_out.append(df)

    print('Restructured data dimensions:', df_out.shape)
    df_out = df_out.rename(columns=predictor_name_map)
    print('Head:\n', df_out.head())

    print('Reducing to data to bounding box of %s' % mask)
    bbox = manip.get_bounding_box_by_mask_col(
        df_out, mask_column=mask, coord_type='xy')
    df_out = manip.restrict_to_bounding_box(df_out, bbox, coord_type)
    print('Final dimensions:', df_out.shape)
    
    return df_out


def split_and_write_data(
    data, mask, split_method, cell_dim, proportions, data_path, outfile_prefix):
    
    for method in split_method:
        if method == 'edge':
            sides = ['n', 's', 'e', 'w']
            for side in sides:
                data_split = split.split_data(
                    data, mask, method, cell_dim, proportions, side)
                write_data(data_split, method, data_path, outfile_prefix, side)
        else:
            data_split = split.split_data(
                data, mask, method, cell_dim, proportions)
            write_data(data_split, method, data_path, outfile_prefix)


def write_data(data_split, method, data_path, outfile_prefix, side=''):
    linesep()
    file_names = [['X_train', 'y_train'],
                  ['X_valid', 'y_valid'],
                  ['X_test', 'y_test']]
    side = side + '/' if side else side
    
    for data_set in range(len(data_split)):
        for xy in range(len(data_split[data_set])):
            outpath = ('%s%s/%s%s%s.csv'
                       % (data_path, method, side, outfile_prefix,
                          file_names[data_set][xy]))
            print('Writing file to %s...' % outpath)
            data_split[data_set][xy].to_csv(outpath, index=False)
                        
                       
                        
    
            

        


if __name__ == '__main__':
    options = read_input()
    main(options)
