#!/usr/bin/env python3
import os
import sys
import time

#import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
#from pylab import *
from sklearn.linear_model import LogisticRegression#, Ridge
#from sklearn.pipeline import Pipeline
#from sklearn.model_selection import GridSearchCV
from sklearn.preprocessing import StandardScaler

sys.path.append('..')
import model_utils as util


DATA_PATH =  '../../../data/cluster/year/'
HISTORIC_DATA_PATH = '../../../data/cluster/historic/'
OPTIMAL_THRESHOLD = 0.60521042084168331
SQ_FIELDS = [
    'meanTemp_Annual', 'meanTemp_AprAug', 'meanTemp_Aug', 'meanMinTemp_DecFeb',
    'meanMinTemp_Oct', 'meanMinTemp_Jan', 'meanMinTemp_Mar', 'meanMaxTemp_Aug',
    'precip_meanAnnual', 'precip_JunAug', 'precipPrevious_JunAug',
    'precip_OctSep', 'precipPrevious_OctSep', 'precip_growingSeason',
    'elev_etopo1', 'lat', 'lon']
INTERACTIONS = [
    'meanMinTemp_Oct:precip_OctSep', 'precip_meanAnnual:precip_OctSep',
    'precip_OctSep:precipPrevious_OctSep', 'meanTemp_Aug:meanMinTemp_Oct',
    'precip_OctSep:lon', 'precip_OctSep:precip_growingSeason',
    'precip_OctSep:meanMaxTemp_Aug', 'meanMinTemp_Oct:precip_meanAnnual',
    'precip_OctSep:meanTemp_Aug', 'precip_OctSep:meanMinTemp_Oct',
    'precip_OctSep:elev_etopo1', 'precip_OctSep:elev_etopo1',
    'precip_OctSep:lat', 'precip_OctSep:precip_growingSeason',
    'precip_OctSep:precipPrevious_OctSep', 'precip_OctSep:precip_meanAnnual',
    'precip_OctSep:precip_OctSep', 'meanMaxTemp_Aug:precip_OctSep',
    'meanTemp_AprAug:precip_OctSep', 'precip_OctSep:varPrecip_growingSeason',
    'meanTemp_Aug:precip_OctSep']

def main():
    [[X_train, y_train],
      [X_valid, y_valid],
      [X_test, y_test]] = util.load_data(DATA_PATH)
    print('Merging data...')
    X = X_train.append(X_valid).append(X_test)
    y = y_train.append(y_valid).append(y_test)
    del X_train
    del X_valid
    del X_test
    del y_train
    del y_valid
    del y_test
    X = make_squared(X, SQ_FIELDS)
    X = make_interactions(X, INTERACTIONS)
    full = X.copy()
    full['beetle'] = y['beetle']
    X = X.drop(
        ['studyArea', 'x', 'y', 'elev_srtm30', 'year',
         'varPrecip_growingSeason', 'precip_OctSep:varPrecip_growingSeason'],
        axis=1)
    predictors = list(X)

    print('Fitting model to full data set...')
    scaler = StandardScaler()
    X = scaler.fit_transform(X)
    y = y['beetle'].values.reshape(-1)
    logistic_clf = LogisticRegression(C=0.001, penalty='l2')
    logistic_clf.fit(X, y)

    coefs = pd.DataFrame(
        [[pred, coef]
         for pred, coef in zip(predictors, logistic_clf.coef_[0])],
        columns=['predictor', 'coef'])
    coefs['abs'] = np.abs(coefs.coef)
    coefs = coefs.sort_values('abs', ascending=False)
    coefs = coefs.drop(['abs'], axis=1)
    print('Model Coefficients:\n', coefs)

    x_range, y_range = get_ranges(full, verbose=True)
    historic_years = range(1903, 2000)
    year = 1999
    next_year_data = full.loc[full.year == (year + 1), :]

    while year >= historic_years[0]:
        hist_data = pd.read_csv(HISTORIC_DATA_PATH + 'clean_%d.csv' % year)
        hist_data = mask_data(hist_data, x_range, y_range, verbose=False)
        hist_data = make_squared(hist_data, SQ_FIELDS)
        hist_data = make_interactions(hist_data, INTERACTIONS)

        print('\nBeginning predictions for', year)
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
        hist_essentials = pd.DataFrame(hist_data[predictors[0]])
        print('  Keeping essentials...')
        for p in predictors[1:]:
            hist_essentials[p] = hist_data[p]
            
        hist_essentials = scaler.fit_transform(hist_essentials)
        print('  Predicting...')
        probs = logistic_clf.predict_proba(hist_essentials)
        probs = np.array([prob[1] for prob in probs])
        hist_merge.loc[:, 'probs_%d' % year] = probs
        hist_merge.loc[:, 'preds_%d' % year] = list(map(
            lambda x: 1 if x >= OPTIMAL_THRESHOLD else 0, probs))
        print('  Saving data so far....')
        hist_merge.to_csv(HISTORIC_DATA_PATH + 'predictions_no_beetle.csv')

        year -= 1
        next_year_data = hist_data

    
def make_squared(dataframe, fields):
    df = dataframe.copy()
    for field in fields:
        df['%s_sq' % field] = df[field] ** 2
    return df


def make_interactions(dataframe, interactions):
    df = dataframe.copy()
    for interaction in interactions:
        main_effects = interaction.split(':')
        df[interaction] = df[main_effects[0]] * df[main_effects[1]]
    return df


def get_ranges(data, verbose=False):
    x_range = data.x.min(), data.x.max()
    y_range = data.y.min(), data.y.max()
    if verbose:
        print('x range:', x_range, '\ny range:', y_range)
    return x_range, y_range


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


def find_extra_rows(data, xy):
    remove = []
    for row in data.index:
        data_xy = str(data.loc[row, 'x']) + str(data.loc[row, 'y'])
        if data_xy not in list(xy):
            remove.append(row)
    return remove

    
if __name__ == '__main__':
    main()
