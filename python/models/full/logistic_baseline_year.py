#!/usr/bin/env python3

import os
import sys
import time

import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
from pylab import *
from sklearn.linear_model import LogisticRegression, Ridge
from sklearn.pipeline import Pipeline
from sklearn.model_selection import GridSearchCV
from sklearn.preprocessing import StandardScaler

sys.path.append('..')
import model_utils as util


DATA_PATH =  '../../../data/cluster/year/'
HISTORIC_DATA_PATH = '../../../data/cluster/historic/'


def main():
    [[X_train, y_train], [X_valid, y_valid], [X_test, y_test]] = load_data(
        'full')
    full_test = X_test.copy()
    full_test['beetle'] = y_test['beetle']
    X_train, X_valid, X_test = drop_unused(
        [X_train, X_valid, X_test],
        ['studyArea', 'x', 'y', 'elev_srtm30', 'year'])
    predictors = list(X_train)
    scaler = StandardScaler()
    X_train = scaler.fit_transform(X_train)
    X_valid = scaler.transform(X_valid)
    X_test  = scaler.transform(X_test)
    y_train = y_train['beetle'].values.reshape(-1)
    y_valid = y_valid['beetle'].values.reshape(-1)
    y_test  = y_test['beetle'].values.reshape(-1)
    logistic_clf = LogisticRegression(C=0.00215443469003, penalty='l1')
    logistic_clf.fit(X_train, y_train)
    preds = logistic_clf.predict(X_test)
    pred_ps = logistic_clf.predict_proba(X_test)
    full_test['preds'] = preds
    historic_years = range(1903, 2000)
    start_year = 1999
    next_year_data = full_test.loc[full_test.year == (start_year + 1), :]
    hist_data = pd.read_csv(HISTORIC_DATA_PATH + 'clean_%d.csv' % start_year)
    x_range, y_range = get_ranges(full_test, verbose=True)
    hist_data = mask_data(hist_data, x_range, y_range, verbose=False)
    hist_merge = hist_data[['x', 'y']]
    create_historical_predictions(historic_years,
                                  start_year,
                                  next_year_data,
                                  hist_data,
                                  hist_merge,
                                  scaler,
                                  logistic_clf,
                                  predictors)
    
    
def load_data(dataset):
    X_train = pd.read_csv(DATA_PATH + 'X_train_%s.csv' % dataset)
    X_valid = pd.read_csv(DATA_PATH + 'X_valid_%s.csv' % dataset)
    X_test  = pd.read_csv(DATA_PATH + 'X_test_%s.csv'  % dataset)
    y_train = pd.read_csv(DATA_PATH + 'y_train_%s.csv' % dataset)
    y_valid = pd.read_csv(DATA_PATH + 'y_valid_%s.csv' % dataset)
    y_test  = pd.read_csv(DATA_PATH + 'y_test_%s.csv'  % dataset)
    X_train = X_train.drop(['Unnamed: 0'], axis=1)
    X_valid = X_valid.drop(['Unnamed: 0'], axis=1)
    X_test  = X_test.drop(['Unnamed: 0'],  axis=1)
    y_train = y_train.drop(['Unnamed: 0'], axis=1)
    y_valid = y_valid.drop(['Unnamed: 0'], axis=1)
    y_test  = y_test.drop(['Unnamed: 0'],  axis=1)
    X_train, y_train = util.drop_nans(
        X_train, y_train, 'varPrecip_growingSeason')
    X_valid, y_valid = util.drop_nans(
        X_valid, y_valid, 'varPrecip_growingSeason')
    X_test,  y_test  = util.drop_nans(
        X_test,  y_test,  'varPrecip_growingSeason')
    print('train: X %s\t y%s' % (X_train.shape, y_train.shape))
    print('valid: X %s\t y%s' % (X_valid.shape, y_valid.shape))
    print('test:  X %s\t y%s' % (X_test.shape,  y_test.shape))
    #print('train:', np.isfinite(X_train).all())
    #print('valid:', np.isfinite(X_valid).all())
    #print('test:',  np.isfinite(X_test).all())
    return [[X_train, y_train], [X_valid, y_valid], [X_test, y_test]]


def drop_unused(Xs, unused):
    X_train, X_valid, X_test = Xs
    X_train = X_train.drop(unused, axis=1)
    X_valid = X_valid.drop(unused, axis=1)
    X_test  = X_test.drop(unused,  axis=1)
    return X_train, X_valid, X_test


def get_ranges(data, verbose=False):
    xrange = data.x.min(), data.x.max()
    yrange = data.y.min(), data.y.max()
    if verbose:
        print('x range:', xrange, '\ny range:', yrange)
        return xrange, yrange

                            
def mask_data(data, xrange, yrange, verbose=False):
    if verbose:
        print('Input data:')
        get_ranges(data, verbose)
    data = data.loc[(data.x >= xrange[0])
                    & (data.x <= xrange[1])
                    & (data.y >= yrange[0])
                    & (data.y <= yrange[1]), :]
    if verbose:
        print('Output data:')
        get_ranges(data, verbose)
    return data


def create_historical_predictions(
        historic_years, year, next_year_data, hist_data, hist_merge, scaler,
        logistic_clf, predictors):
    while year >= historic_years[0]:
        print('\n\nBeginning predictions for', year)
        xy = next_year_data.apply(
            lambda row: str(row['x']) + str(row['y']), axis=1)
        print('  Reducing %d data to study area...' % year)
        extras = find_extra_rows(hist_data, xy)
        hist_data = hist_data.drop(extras, axis=0)
        hist_data = hist_data.rename(
            columns={'precipPreious_OctSep': 'precipPrevious_OctSep'})
        if year == historic_years[-1]:
            hist_merge = hist_data[['x', 'y']]
        print('  Ascertaining rows are aligned...')
        assert list(hist_data.x) == list(next_year_data.x)
        assert list(hist_data.y) == list(next_year_data.y)
        hist_data.index = next_year_data.index
        hist_merge.index = hist_data.index
        hist_data['next_year_beetle'] = next_year_data['beetle'] 
        hist_essentials = pd.DataFrame(hist_data[predictors[0]])
        print('  Keeping essentials...')
        for p in predictors[1:]:
            hist_essentials[p] = hist_data[p]    
        hist_essentials = scaler.fit_transform(hist_essentials)
        hist_data['beetle'] = logistic_clf.predict(hist_essentials)
        print('  Predicting...')
        hist_merge['preds_%d' % year] = hist_data['beetle']
        probs = logistic_clf.predict_proba(hist_essentials)
        probs = [prob[1] for prob in probs]
        hist_merge['probs_%d' % year] = probs
        print('Saving data so far....')
        hist_merge.to_csv(HISTORIC_DATA_PATH + 'predictions.csv', index=False)
        
        year -= 1
        next_year_data = hist_data
        hist_data = pd.read_csv(HISTORIC_DATA_PATH + 'clean_%d.csv' % year)


def find_extra_rows(data, xy):
    remove = []
    for row in data.index:
        data_xy = str(data.loc[row, 'x']) + str(data.loc[row, 'y'])
        if data_xy not in list(xy):
            remove.append(row)
    return remove
    

if __name__ == '__main__':
    main()
