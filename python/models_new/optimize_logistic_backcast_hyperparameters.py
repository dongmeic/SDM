#!/usr/bin/env python3
import sys
import time

import matplotlib.pyplot as plt
import numpy as np
from sklearn.linear_model import LogisticRegression
from sklearn.preprocessing import StandardScaler

import model_utils as util
from construct_model_matrices import ModelMatrixConstructor

DATA_DIR = '/gpfs/projects/gavingrp/dongmeic/beetle/output/tables/backcasting/Xy_year_split_data'
IMG_DIR = '/gpfs/projects/gavingrp/dongmeic/beetle/output/plots/images/backcast'
SQUARE = [
    'lon', 'lat', 'etopo1', 'JanTmin', 'MarTmin', 'TMarAug', 'summerTmean',
    'AugTmean', 'AugTmax', 'GSP', 'PMarAug', 'summerP0', 'OctTmin',
    'fallTmean', 'winterTmin', 'Tmin', 'Tmean', 'Tvar', 'TOctSep',
    'summerP1', 'summerP2', 'Pmean', 'POctSep', 'PcumOctSep', 'PPT',
    'ddAugJul', 'ddAugJun']
CUBE = ['etopo1', 'summerP0', 'summerP1', 'summerP2', 'Pmean', 'POctSep',
        'GSP', 'PMarAug']
INTERACTIONS = [
    'lon:summerTmean', 'lon:AugTmean', 'lon:AugTmax', 'lon:GSP', 'lon:PMarAug',
    'lon:Pmean', 'lon:POctSep', 'lon:PcumOctSep', 'lon:PPT', 'lat:etopo1',
    'lat:JanTmin', 'lat:MarTmin', 'lat:TMarAug', 'lat:summerTmean',
    'lat:AugTmean', 'lat:AugTmax', 'lat:GSP', 'lat:PMarAug', 'lat:summerP0',
    'lat:fallTmean', 'lat:winterTmin', 'lat:Tmin', 'lat:Tmean', 'lat:TOctSep',
    'lat:summerP2', 'lat:Pmean', 'lat:POctSep', 'lat:PcumOctSep', 'lat:PPT',
    'lat:ddAugJul', 'lat:ddAugJun', 'etopo1:MarTmin', 'etopo1:winterTmin',
    'etopo1:Tmean', 'etopo1:TOctSep', 'etopo1:Pmean', 'etopo1:PcumOctSep',
    'JanTmin:MarTmin', 'JanTmin:TMarAug', 'JanTmin:summerP0',
    'JanTmin:fallTmean', 'JanTmin:winterTmin', 'JanTmin:Tmin', 'JanTmin:Tmean',
    'JanTmin:Tvar', 'JanTmin:TOctSep', 'JanTmin:summerP2', 'JanTmin:Pmean',
    'JanTmin:POctSep', 'JanTmin:PcumOctSep', 'JanTmin:PPT', 'MarTmin:TMarAug',
    'MarTmin:AugTmax', 'MarTmin:summerP0', 'MarTmin:fallTmean',
    'MarTmin:winterTmin', 'MarTmin:Tmin', 'MarTmin:Tmean', 'MarTmin:Tvar',
    'MarTmin:TOctSep', 'MarTmin:summerP2', 'TMarAug:AugTmean',
    'TMarAug:AugTmax', 'TMarAug:summerP0', 'TMarAug:fallTmean',
    'TMarAug:winterTmin', 'TMarAug:Tmin', 'TMarAug:Tmean', 'TMarAug:TOctSep',
    'TMarAug:summerP2', 'AugTmean:Tmean', 'AugTmean:TOctSep', 'AugTmax:GSP',
    'AugTmax:PMarAug', 'AugTmax:summerP0', 'AugTmax:fallTmean', 'AugTmax:Tmean',
    'AugTmax:TOctSep', 'AugTmax:summerP2', 'AugTmax:Pmean', 'AugTmax:POctSep',
    'AugTmax:PcumOctSep', 'AugTmax:PPT', 'GSP:PMarAug', 'GSP:Tvar', 'GSP:Pmean',
    'GSP:POctSep', 'GSP:PcumOctSep', 'GSP:PPT', 'PMarAug:summerP2',
    'PMarAug:Pmean', 'PMarAug:POctSep', 'PMarAug:PcumOctSep', 'PMarAug:PPT',
    'summerP0:fallTmean', 'summerP0:winterTmin', 'summerP0:Tmin',
    'summerP0:Tmean', 'summerP0:TOctSep', 'summerP0:summerP2',
    'fallTmean:winterTmin', 'fallTmean:Tmin', 'fallTmean:Tmean',
    'fallTmean:TOctSep', 'fallTmean:summerP2', 'winterTmin:Tmin',
    'winterTmin:Tmean', 'winterTmin:Tvar', 'winterTmin:TOctSep',
    'winterTmin:summerP2', 'winterTmin:POctSep', 'winterTmin:PcumOctSep',
    'winterTmin:PPT', 'Tmin:Tmean', 'Tmin:Tvar', 'Tmin:TOctSep',
    'Tmin:summerP2', 'Tmin:POctSep', 'Tmin:PPT', 'Tmean:Tvar', 'Tmean:TOctSep',
    'Tmean:summerP2', 'Tvar:TOctSep', 'Tvar:Pmean', 'Tvar:POctSep',
    'Tvar:PcumOctSep', 'Tvar:PPT', 'TOctSep:summerP2', 'summerP1:Pmean',
    'summerP1:POctSep', 'summerP1:PcumOctSep', 'summerP1:PPT', 'summerP2:Pmean',
    'summerP2:PcumOctSep', 'Pmean:POctSep', 'Pmean:PcumOctSep', 'Pmean:PPT',
    'POctSep:PcumOctSep', 'POctSep:PPT', 'PcumOctSep:PPT']

        
def main():
    matrix_constructor = ModelMatrixConstructor(DATA_DIR)
    matrix_constructor.set_squares(SQUARE)
    matrix_constructor.set_cubes(CUBE)
    matrix_constructor.set_interactions(INTERACTIONS)
    data_sets = matrix_constructor.construct_model_matrices()
    [[X_train, y_train], [X_valid, y_valid], [X_test, y_test]] = data_sets
    for (data_set, name) in zip(data_sets, ['Train', 'Valid', 'Test']):
        print_dims(data_set, name)
    util.print_percent_presence(y_train, 'y_train')
    util.print_percent_presence(y_valid, 'y_valid')
    util.print_percent_presence(y_test,  'y_test')
    full_train = X_train.copy()
    full_valid = X_valid.copy()
    full_test = X_test.copy()
    full_train['btl_t'] = y_train['btl_t']
    full_valid['btl_t'] = y_valid['btl_t']
    full_test['btl_t'] = y_test['btl_t']
    drop = ['x', 'y', 'year']
    X_train = X_train.drop(drop, axis=1)
    X_valid = X_valid.drop(drop, axis=1)
    X_test  = X_test.drop(drop, axis=1)
    predictors = list(X_train)
    X_train, X_valid, X_test = scale_data(X_train, X_valid, X_test)
    y_train = y_train['btl_t'].values.reshape(-1)
    y_valid = y_valid['btl_t'].values.reshape(-1)
    y_test  = y_test['btl_t'].values.reshape(-1)
    Cs, l1_mods, l2_mods = optimize_regularization_parameter(
        -4, -2, 20, X_train, y_train, X_valid, y_valid)
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
    fig.savefig('%s/hyperparam_backcast_tuning.png' % IMG_DIR)
                                                            
    
def print_dims(data_set, name):
    print('%s:\n X: %r\n y: %r'
          % (name, data_set[0].shape, data_set[1].shape))


def scale_data(X_train, X_valid, X_test):
    scaler = StandardScaler()
    X_train = scaler.fit_transform(X_train)
    X_valid = scaler.transform(X_valid)
    X_test  = scaler.transform(X_test)
    return X_train, X_valid, X_test
    

def optimize_regularization_parameter(
        mn, mx, steps, X_train, y_train, X_valid, y_valid):
    l1_mods = []
    l2_mods = []
    Cs = np.logspace(mn, mx, steps)
    t0 = time.time()
    for C in Cs:
        #print('Testing C =', C)
        for penalty in ['l1', 'l2']:
            #print('  %s:' % penalty, end=' ')
            logistic_clf = LogisticRegression(C=C, penalty=penalty, n_jobs=-1)
            logistic_clf.fit(X_train, y_train)
            preds = logistic_clf.predict(X_valid)
            accuracy = sum(y_valid == preds) / len(preds)
            #print(round(accuracy, 4))
            if penalty == 'l1':
                l1_mods.append(accuracy)
            else:
                l2_mods.append(accuracy)
            #print('Elapsed time: %.2f minutes' % ((time.time() - t0) / 60))
    return Cs, l1_mods, l2_mods



if __name__ == '__main__':
    main()
