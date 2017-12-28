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
#   -s SPLIT_METHOD: ['random' | 'internal' | 'edge' | 'all'] method used to
#      split data into train, validation, and test sets ('all' by default)
#   Examples:
#     ./prep_data.py "../data/"
#
#===============================================================================

import argparse
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
INFILE = 'climatic_variables_longlat_var.csv'
MASK = 'btl_mat_msk.2'
COORD_TYPE = 'xy'
OUTFILE_PREFIX = ''
SPLIT_METHOD = 'all'
CELL_DIM = 10000 # dimensions of raster cell
PROPORTIONS = [0.7, 0.15, 0.15] # train, valid, split


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
        help=('["random" | "internal" | "edge" | "all"] method used to split '
              'data into train, validation, and test sets ("all" by default)'))
    return p.parse_args()


def main(options):
    start_time = time()

    # Parse args and set up
    (env, data_path, infile, mask,
     coord_type, outfile_prefix, split_method) = parse_args(options)

    print('Loading data from %s%s...' % (data_path, infile))
    data = load_data(data_path, infile)
    data = reduce_data(data, mask, coord_type)

    # Check output directories exist, or create if they do not
    check_or_make_dirs(data_path)
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
    print('Dropping redundant columns...')
    data = manip.drop_redundant_columns(data)
    print('Data shape: ', data.shape)

    print('Getting bounding box for %s' % mask)
    bounding_box = manip.get_bounding_box_by_mask_col(data, mask, coord_type)

    print('Reducing data to region within bounding box...')
    data =  manip.restrict_to_bounding_box(data, bounding_box, coord_type)
    print('Final data shape:', data.shape)
    return data


def check_or_make_dirs(data_path):
    linesep()
    dirs = [
        'random', 'internal', 'edge', 'edge/n', 'edge/s', 'edge/e', 'edge/w']
    
    for d in dirs:
        try:
            print('Creating directory: ', data_path + d)
            os.makedirs(d)
        except FileExistsError as e:
            print('%s exists' % (data_path + d))
        except Exception as e:
            print('Unexpected error in check_or_make_dirs(%s)' % data_path)
            print(e)
            sys.exit(1)
    return True
                

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
