import os
import sys
import time

import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
#from pylab import *
from sklearn.linear_model import LogisticRegression, Ridge
#from sklearn.pipeline import Pipeline
#from sklearn.model_selection import GridSearchCV
from sklearn.preprocessing import StandardScaler

import model_utils as util
from construct_model_matrices_random import ModelMatrixConstructor

#DATA_DIR = '../../data/Xy_internal_split_data'
#IMG_DIR = '../../images'
DATA_DIR = '/gpfs/projects/gavingrp/dongmeic/sdm/data/Xy_random_split_data'
IMG_DIR = '/gpfs/projects/gavingrp/dongmeic/beetle/output/plots/images'


def main():
    make_image_dir()
    matrix_constructor = ModelMatrixConstructor(DATA_DIR)
    data_sets = matrix_constructor.construct_model_matrices()
    [[X_train, y_train], [X_valid, y_valid], [X_test, y_test]] = data_sets
    for (data_set, name) in zip(data_sets, ['Train', 'Valid', 'Test']):
        print_dims(data_set, name)
    util.print_percent_presence(y_train, 'y_train')
    util.print_percent_presence(y_valid, 'y_valid')
    util.print_percent_presence(y_test, 'y_test')
    print('Baseline accuracy if predicting "absent" for all cells:')
    print('  train:', 100 - 33.03)
    print('  valid:', 100 - 10.31)
    print('  test: ', 100 - 1.44)
    y_train.columns=['btl_t']
    y_valid.columns=['btl_t']
    y_test.columns=['btl_t']
    full_train = X_train.copy()
    full_valid = X_valid.copy()
    full_test = X_test.copy()
    full_train['btl_t'] = y_train['btl_t']
    full_valid['btl_t'] = y_valid['btl_t']
    full_test['btl_t'] = y_test['btl_t']
    predictors = list(X_train)
    X_train = drop_NA(X_train)
    X_valid = drop_NA(X_valid)
    X_test = drop_NA(X_test)
    X_train, X_valid, X_test = scale_data(X_train, X_valid, X_test)
    y_train = y_train['btl_t'].values.reshape(-1)
    y_valid = y_valid['btl_t'].values.reshape(-1)
    y_test  = y_test['btl_t'].values.reshape(-1)
    Cs, l1_mods, l2_mods = find_optimal_regularization_parameter(
        X_train, y_train, X_valid, y_valid)
    print('%8s\t%8s\t%8s' % ('C', 'l1_acc', 'l2_acc'))
    for c, l1, l2 in zip(Cs, l1_mods, l2_mods):
        print('%.6f\t%.6f\t%.6f' % (c, l1, l2))
    fig = plt.figure()
    plt.plot(Cs, l1_mods, label='L1 Reg.');
    plt.plot(Cs, l2_mods, label='L2 Reg.');
    plt.xscale('log');
    plt.xlabel('C');
    plt.ylabel('Accuracy');
    plt.legend(loc='best');
    fig.savefig('%s/hyperparam_tuning.png' % IMG_DIR)
        

def make_image_dir():
    if not os.path.exists(IMG_DIR):
        os.makedirs(IMG_DIR)


def print_dims(data_set, name):
    print('%s:\n X: %r\n y: %r'
          % (name, data_set[0].shape, data_set[1].shape))


def scale_data(X_train, X_valid, X_test):
    scaler = StandardScaler()
    X_train = scaler.fit_transform(X_train)
    X_valid = scaler.transform(X_valid)
    X_test  = scaler.transform(X_test)
    return X_train, X_valid, X_test


def find_optimal_regularization_parameter(X_train, y_train, X_valid, y_valid):
    l1_mods = []
    l2_mods = []
    Cs = np.logspace(-1.5, -0.5, 4)
    t0 = time.time()
    for C in Cs:
        print('Testing C =', C)
        for penalty in ['l1', 'l2']:
            print('  %s:' % penalty, end=' ')
            logistic_clf = LogisticRegression(C=C, penalty=penalty, n_jobs=-1)
            logistic_clf.fit(X_train, y_train)
            preds = logistic_clf.predict(X_valid)
            accuracy = sum(y_valid == preds) / len(preds)
            print(round(accuracy, 4))
            if penalty == 'l1':
                l1_mods.append(accuracy)
            else:
                l2_mods.append(accuracy)
            print('Elapsed time: %.2f minutes' % ((time.time() - t0) / 60))
    return Cs, l1_mods, l2_mods

def drop_NA(df):
    df = df[df.columns.drop(list(df.filter(regex='cv.gsp')))]
    return df   

if __name__ == '__main__':
    main()
    
