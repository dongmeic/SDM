#!/usr/bin/env python3

import bz2
import numpy as np
import os
import pandas as pd
import pickle

DATA_DIR = '../../data/cluster/year/'
START_YEAR = 2000
END_YEAR = 2013 # Cannot add next year's data to 2014, so 2013 is last here

def main():
    for year in range(START_YEAR, END_YEAR + 1):
        make_and_save_tensor(DATA_DIR, year)

def make_and_save_tensor(data_path, year, verbose=True):
    print('\nMaking new tensor for %d' % year)
    out_path = data_path + 'tensor20_%d.pkl.bz2' % year
    X, next_Y = load_x_and_following_y(data_path, year, verbose=verbose)
    new_X = add_next_year_beetle_data(X, next_Y)
    print('Saving tensor to %s...' % out_path)
    pickle.dump(new_X, bz2.open(out_path, 'wb'))


def load_x_and_following_y(data_path, year, verbose=True):
    x_path = data_path + 'tensor%d.pkl.bz2' % year
    y_path = data_path + 'y_matrix%d.pkl.bz2' % (year + 1)
    if verbose:
        print('\nLoading X tensor from %s' % x_path)
    X = pickle.load(bz2.open(x_path, 'rb'))
    if verbose:
        print('Loading y tensor from %s' % y_path)
    Y = pickle.load(bz2.open(y_path, 'rb'))
    if verbose:
        print('  X:', X.shape, '(width, height, layers)')
        print('  Y:', Y.shape, '    (width, height)')
    return X, Y


def add_next_year_beetle_data(X, next_Y):
    width, height, layers = X.shape
    X = np.concatenate([X, next_Y.reshape([width, height, 1])], axis=2)
    return X


if __name__ == '__main__':
    main()
