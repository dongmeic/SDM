#!/usr/bin/env python3
import os
import sys

import pandas as pd

import model_utils as util

DATA_DIR = '../../data/cluster/year/'
START_YEAR = 2000
END_YEAR = 2013 # Cannot add next year's data to 2014, so 2013 is last here
# Number of years for each set:
TEST = 2 
VALID = 2
TRAIN = 9


def main():
    print('Loading data...')
    [[X_train, y_train],
     [X_valid, y_valid],
     [X_test, y_test]] = load_data(DATA_DIR)
    print('Merging data....')
    data = X_train.append(X_valid).append(X_test)
    y = y_train.append(y_valid).append(y_test)
    data['beetle'] = y
    print('Adding the following year beetle data...')
    [[X_train, y_train],
     [X_valid, y_valid],
     [X_test, y_test]] = make_new_data_sets(data)
    print('X_train: %s\ty_train: %s\n'
          'X_valid: %s\ty_valid: %s\n'
          'X_test:  %s\ty_test:  %s'
          % (X_train.shape, y_train.shape,
             X_valid.shape, y_valid.shape,
             X_test.shape, y_test.shape))
    print('Saving files as "X_train_full.csv" etc....')
    save_xy([X_train, y_train], DATA_DIR, 'big_train_full')
    save_xy([X_valid, y_valid], DATA_DIR, 'big_valid_full')
    save_xy([X_test, y_test], DATA_DIR, 'big_test_full')


def load_data(data_dir):
    X_train = pd.read_csv(data_dir + 'X_big_train.csv')
    print('X_train:', X_train.shape)
    X_valid = pd.read_csv(data_dir + 'X_big_valid.csv')
    print('X_valid:', X_valid.shape)
    X_test  = pd.read_csv(data_dir + 'X_big_test.csv')
    print('X_test:',  X_test.shape)
    y_train = pd.read_csv(data_dir + 'y_big_train.csv')
    print('y_train:', y_train.shape)
    y_valid = pd.read_csv(data_dir + 'y_big_valid.csv')
    print('y_valid:', y_valid.shape)
    y_test  = pd.read_csv(data_dir + 'y_big_test.csv')
    print('y_test:',  y_test.shape)
    return [[X_train, y_train], [X_valid, y_valid], [X_test, y_test]]


def make_new_data_sets(data):
    yearly_data = []
    for year in range(START_YEAR, END_YEAR + 1):
        X, y = make_yearly_data(data, year)
        yearly_data.append([X, y])
    assert TRAIN + VALID + TEST == len(yearly_data) - 1
    with_beetle_data = []
    for i in range(len(yearly_data) - 1):
        x1, y1 = yearly_data[i]
        x2, y2 = yearly_data[i + 1]
        assert list(x1.x) == list(x2.x)
        assert list(x1.y) == list(x2.y)
        y2.index = x1.index
        x1['next_year_beetle'] = y2['beetle']
        with_beetle_data.append([x1, y1])
    test = with_beetle_data[:TEST]
    valid = with_beetle_data[TEST : TEST + VALID]
    train = with_beetle_data[TEST + VALID:]
    X_test, y_test = merge_sets(test)
    X_valid, y_valid = merge_sets(valid)
    X_train, y_train = merge_sets(train)
    return [[X_train, y_train], [X_valid, y_valid], [X_test, y_test]]


def make_yearly_data(data, year):
    dat = data.copy()
    year_data = dat.loc[dat.year == year, :]
    y_year = pd.DataFrame(year_data['beetle'])
    X_year = year_data.drop(['beetle'], axis=1)
    return X_year, y_year


def merge_sets(data_sets):
    X, y = data_sets[0]
    for i in range(1, len(data_sets)):
        next_X, next_y = data_sets[i]
        X = X.append(next_X)
        y = y.append(next_y)
    return X, y


def save_xy(xy, path, suffix):
    X, y = xy
    X.to_csv(path + 'X_' + suffix + '.csv')
    y.to_csv(path + 'y_' + suffix + '.csv')

    
if __name__ == '__main__':
    main()
