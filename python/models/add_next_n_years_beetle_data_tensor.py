import bz2
import os
import pickle

import numpy as np
import pandas as pd


DATA_DIR = '../../data/cluster/year/'
N_YEARS_AHEAD = 3
YEAR_RANGE = range(1903, 2012) 


def main():
    for year in YEAR_RANGE:
        make_and_save_tensor(DATA_DIR, year)


def make_and_save_tensor(data_path, year, verbose=True):
    print('\nMaking new tensor for %d' % year)
    out_path = (data_path + 'tensor%dyrs_ahead_%d.pkl.bz2'
                % (N_YEARS_AHEAD, year))
    X, next_Ys = load_x_and_following_n_ys(
        data_path, year, n=N_YEARS_AHEAD, verbose=verbose)
    new_X = add_next_n_years_beetle_data(X, next_Ys)
    print('Saving tensor to %s...' % out_path)
    pickle.dump(new_X, bz2.open(out_path, 'wb'))


def load_x_and_following_n_ys(data_path, year, n=3, verbose=False):
    x_path = data_path + 'tensor%d.pkl.bz2' % year
    y_paths = [data_path + 'y_matrix%d.pkl.bz2' % (year + i)
               for i in range(1, n + 1)]
    if verbose:
        print('\nLoading X tensor from %s' % x_path)
    X = pickle.load(bz2.open(x_path, 'rb'))
    Ys = []
    for y_path in y_paths:
        if verbose:
            print('Loading y tensor from %s' % y_path)
        Y = pickle.load(bz2.open(y_path, 'rb'))
        Ys.append(Y)    
    if verbose:
        print('  X: ', X.shape, '(width, height, layers)')
        for Y in Ys:
            print('  Y: ', Y.shape, '    (width, height)')
    return X, Ys


def add_next_n_years_beetle_data(X, next_Ys):
    width, height, layers = X.shape
    for next_Y in next_Ys:
        X = np.concatenate([X, next_Y.reshape([width, height, 1])], axis=2)
    return X




if __name__ == '__main__':
    main()
