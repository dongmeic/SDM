#!/usr/bin/env python3

import bz2
import sys
import pickle
import time

import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
#from sklearn.preprocessing import StandardScaler

import model_utils as util

DATA_DIR = '../../data/cluster/year/'
HISTORIC_DATA_DIR = '../../data/cluster/historic/'
HISTORIC = True
HISTORIC_YEARS = range(1903, 2000)

def main():
    ignore = [
        'year', 'studyArea', 'elev_srtm30', 'x', 'y', 'varPrecip_growingSeason']
    if HISTORIC:
        X_test = pd.read_csv(DATA_DIR + 'X_test.csv')
        x_min = X_test.x.min()
        y_min = X_test.y.min()
        x_max = X_test.x.max()
        y_max = X_test.y.max()
        print('x range: %d - %d' % (x_min, x_max))
        print('y range: %d - %d' % (y_min, y_max))
        t0 = time.time()
        for i in HISTORIC_YEARS:
            t_iter = time.time()
            path = '%sclean_%d.csv' % (HISTORIC_DATA_DIR, i)
            print('Reading data from %s...' % path)
            X = pd.read_csv(path)
            print('Filtering x, y ranges...')
            X = X.loc[((X.x >= x_min)
                       & (X.x <= x_max)
                       & (X.y >= y_min)
                       & (X.y <= y_max)), :]
            fields = [col for col in list(X) if col not in ignore]
            make_and_save_tensor(X, fields, i)
            iter_time = (time.time() - t_iter) / 60
            elapsed = (time.time() - t0) / 60
            print('  Iteration time: %.2fminutes\n  Elapsed time: %.2fminutes'
                  % (iter_time, elapsed))
    else:
        [[X_train, y_train],
         [X_valid, y_valid],
         [X_test, y_test]] = util.load_data(DATA_DIR)
        X_train, y_train = util.drop_nans(
            X_train, y_train, 'varPrecip_growingSeason')
        X_valid, y_valid = util.drop_nans(
            X_valid, y_valid, 'varPrecip_growingSeason')
        X_test,  y_test  = util.drop_nans(
            X_test,  y_test,  'varPrecip_growingSeason')
        fields = [col for col in list(X_test) if col not in ignore]
        for i in range(2006, 2015):
            make_and_save_tensor(X_train,   fields,  i)
            make_and_save_y_matrix(y_train, X_train, i)
        for i in range(2003, 2006):
            make_and_save_tensor(X_valid,   fields,  i)
            make_and_save_y_matrix(y_valid, X_valid, i)
        for i in range(2000, 2003):
            make_and_save_tensor(X_test,   fields, i)
            make_and_save_y_matrix(y_test, X_test, i)


def column2matrix(dataframe, column, year, cell_dim=10000):
    '''   
    Convert a column from DataFrame df into a matrix representation with the
    upper-left cell indexing beginning at [0, 0].
    It is expected that the DataFrame has columns x and y.

    Args:
    df: DataFrame: the source data
    column: string: the column name to extract
    cel_dim: numeric: the dimensions of each grid cell

    Returns: np.ndarray (a 2D list; matrix)
    '''
    df = dataframe.copy()
    df = df.loc[df.year == year, :]
    x_min = df.x.min()
    y_min = df.y.min()
    df.x -= x_min
    df.y -= y_min
    xs = sorted(df.x.unique())
    ys = sorted(df.y.unique())
    #xs = range(int(min(xs)), int(max(xs)) + 1)
    #ys = range(int(min(ys)), int(max(ys)) + 1)
    matrix = np.array([[np.nan for y in range(len(ys))]
                       for x in range(len(xs))])
    for row in df.index:
        x, y, value = df.loc[row, ['x', 'y', column]]
        i = int((x - xs[0]) / cell_dim) 
        j = int((y - ys[0]) / cell_dim)
        try:
            matrix[i, j] = value
        except:
            print('x: %d; xs[0]: %d; xs[-1]: %d; i: %d\n'
                  'y: %d; ys[0]: %d; ys[-1]: %d; j: %d\n'
                  'matrix: %s' 
                  % (x, xs[0], xs[-1], i, y, ys[0], ys[-1], j, matrix.shape))
    return matrix


def df2tensor(dataframe, columns, year, cell_dim=10000, verbose=True):
    matrices = []
    for col in columns:
        if verbose: print('Getting matrix for %s...' % col, end='\r')
        matrices.append(column2matrix(dataframe, col, year, cell_dim))
    tensor = np.stack(matrices, axis=2)
    if verbose: print('Data returned as tensor of shape:', tensor.shape)
    return tensor


def make_and_save_tensor(X, columns, year):
    print('\nMaking tensor for %d' % year)
    tensor = df2tensor(X, columns, year)
    path = DATA_DIR + 'tensor%d.pkl.bz2' % year
    print('Saving tensor to %s...' % path)
    pickle.dump(tensor, bz2.open(path, 'wb'))


def y2matrix(y_dataframe, X_dataframe, year, cell_dim=10000):
    ''' 
    Convert a column from DataFrame df into a matrix representation with the
    upper-left cell indexing beginning at [0, 0].
    It is expected that the DataFrame has columns x and y.
    
    Args:
    df: DataFrame: the source data
    column: string: the column name to extract
    cel_dim: numeric: the dimensions of each grid cell
    
    Returns: np.ndarray (a 2D list; matrix)
    '''
    df = X_dataframe.copy()
    df = df.loc[df.year == year, :]
    x_min = df.x.min()
    y_min = df.y.min()
    df.x -= x_min
    df.y -= y_min
    xs = sorted(df.x.unique())
    ys = sorted(df.y.unique())
    matrix = np.array([[np.nan for y in range(len(ys))]
                       for x in range(len(xs))])
    for row in df.index:
        x, y = df.loc[row, ['x', 'y']]
        value = y_dataframe.loc[row, 'beetle']
        i = int((x - xs[0]) / cell_dim)
        j = int((y - ys[0]) / cell_dim)
        matrix[i, j] = value    
    return matrix

def make_and_save_y_matrix(y, X, year):
    print('\nMaking y matrix for %d' % year)
    tensor = y2matrix(y, X, year)
    path = DATA_DIR + 'y_matrix%d.pkl.bz2' % year
    print('Saving matrix to %s...' % path)
    pickle.dump(tensor, bz2.open(path, 'wb'))



if __name__ == '__main__':
    main()

