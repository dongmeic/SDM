#!/usr/bin/env python3
import os
import re
import sys

import numpy as np
import pandas as pd



DATA_DIR = '../data'
OUTPUT_DIR = '%s/Xy_internal_split_data' % DATA_DIR
INPUT_FILE_FORMAT = r'input_data_[0-9]{4}\.csv$'


def main():
    input_files = [f for f in os.listdir(DATA_DIR)
                   if re.match(INPUT_FILE_FORMAT, f)]
    for file_name in input_files:
        file_path = '%s/%s' % (DATA_DIR, file_name)
        year = file_path.split('_')[-1].replace('.csv', '')
        dat = pd.read_csv(file_path)
        split_data = split_data_internal(
                dat, 'btl_t', np.array([0.16, 0.22, 0.62]), cell_dim=10000)
        if not save_files(year, split_data):
            print('Error saving files')
            sys.exit(1)
    print('Program completed.')


def split_data_internal(dat, response, proportions, cell_dim):
    data = dat.copy()
    train, valid, test = proportions
    n = data.shape[0]
    n_train = int(round(n * proportions[0]))
    n_valid = int(round(n * proportions[1]))
    n_test = n - n_train - n_valid
    data = convert_data_to_0_base(data, cell_dim)
    test_valid_box = get_proportional_internal_block(
        width=data.x.max(), height=data.y.max(), proportion=valid + test)
    x_offset = test_valid_box['x_range'][0]
    y_offset = test_valid_box['y_range'][0]
    test_box = get_proportional_internal_block(
        width=test_valid_box['x_range'][1] - test_valid_box['x_range'][0],
        height=test_valid_box['y_range'][1] - test_valid_box['y_range'][0],
        proportion=test / (test + valid))
    test_box['x_range'] += x_offset
    test_box['y_range'] += y_offset
    test_set, tv_set = split_data_by_xy_ranges(
        data, test_box['x_range'], test_box['y_range'])
    valid_set, train_set = split_data_by_xy_ranges(
        tv_set, test_valid_box['x_range'], test_valid_box['y_range'])
    X_train, y_train = split_predictors_response(train_set, response)
    X_valid, y_valid = split_predictors_response(valid_set, response)
    X_test,  y_test  = split_predictors_response(test_set,  response)
    return [[X_train, y_train], [X_valid, y_valid], [X_test, y_test]]


def convert_data_to_0_base(data, cell_dim):
    data.x = ((data.x - min(data.x)) / cell_dim).astype(int)
    data.y = ((data.y - min(data.y)) / cell_dim).astype(int)
    return data


def get_proportional_internal_block(height, width, proportion):
    n = height * width
    n_block = int(round(n * proportion))
    h_block = int(proportion * height)
    w_block = int(proportion * width)
    x_offset = (width - w_block) // 2
    y_offset = (height - h_block) // 2
    deficit = n_block - (h_block * w_block)
    x_range = [x_offset, x_offset + w_block]
    y_range = [y_offset, y_offset + h_block]
    return {'x_range': x_range, 'y_range': y_range, 'deficit': deficit}


def split_data_by_xy_ranges(dat, x_range, y_range):
    data = dat.copy()
    inner_data = data.loc[((data.x >= x_range[0])
                           & (data.x <  x_range[1])
                           & (data.y >= y_range[0])
                           & (data.y <  y_range[1])), :]
    outer_data = data.loc[((data.x <  x_range[0])
                           | (data.x >= x_range[1])
                           | (data.y <  y_range[0])
                           | (data.y >= y_range[1])), :]
    return inner_data, outer_data


def split_predictors_response(dat, response):
    data = dat.copy()
    y = pd.DataFrame(data.loc[:, response])
    X = data.drop(response, axis=1)
    return X, y


def save_files(year, split_data):
    if not os.path.exists(OUTPUT_DIR):
        os.mkdir(OUTPUT_DIR)
    set_names = ['test', 'valid', 'train']
    xy_names = ['X', 'y']
    for data_set, set_name in zip(split_data, set_names):
        for xy, xy_name in zip(data_set, xy_names):
            path = '%s/%s_%s_%s.csv' % (OUTPUT_DIR, xy_name, set_name, year)
            print('Writing data to ', path)
            xy.to_csv(path, index=False)
    return True



if __name__ == '__main__':
    main()
