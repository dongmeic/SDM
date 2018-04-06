import os
import sys

import numpy as np
import pandas as pd
from sklearn.linear_model import LogisticRegression
from sklearn.preprocessing import StandardScaler

sys.path.append('..')
import model_utils as util

DATA_PATH =  '../../../data/cluster/year/'
HISTORIC_DATA_PATH = '../../../data/cluster/historic/'
OPTIMAL_THRESHOLD = 0.5


def main():
    X_train = pd.read_csv(DATA_PATH + 'X_train_full.csv')
    X_valid = pd.read_csv(DATA_PATH + 'X_valid_full.csv')
    X_test  = pd.read_csv(DATA_PATH + 'X_test_full.csv')
    y_train = pd.read_csv(DATA_PATH + 'y_train_full.csv')
    y_valid = pd.read_csv(DATA_PATH + 'y_valid_full.csv')
    y_test  = pd.read_csv(DATA_PATH + 'y_test_full.csv')

    X_train = X_train.drop(['Unnamed: 0'], axis=1)
    X_valid = X_valid.drop(['Unnamed: 0'], axis=1)
    X_test  = X_test.drop(['Unnamed: 0'],  axis=1)
    y_train = y_train.drop(['Unnamed: 0'], axis=1)
    y_valid = y_valid.drop(['Unnamed: 0'], axis=1)
    y_test  = y_test.drop(['Unnamed: 0'],  axis=1)
    
    X = X_train.append(X_valid).append(X_test)
    y = y_train.append(y_valid).append(y_test)
    del X_train
    del X_valid
    del X_test
    del y_train
    del y_valid
    del y_test
    
    full = X.copy()
    X = X.drop(
        ['studyArea', 'x', 'y', 'elev_srtm30', 'year',
         'varPrecip_growingSeason'],
        axis=1)
    predictors = list(X)
    scaler = StandardScaler()
    X = scaler.fit_transform(X)
    y = y['beetle'].values.reshape(-1)
    logistic_clf = LogisticRegression(C=0.001923583801, penalty='l1')
    logistic_clf.fit(X, y)
    probs = logistic_clf.predict_proba(X)
    probs = [p[1] for p in probs]

    X_df = pd.DataFrame(data=X, index=full.index, columns=predictors)
    X_df['year'] = full['year']
    X_df['x'] = full['x']
    X_df['y'] = full['y']
    X_df['probs'] = probs
    X_df['preds'] = X_df['probs'].apply(
        lambda x: 1 if x >= OPTIMAL_THRESHOLD else 0)
    out_data = X_df.loc[X_df.year == 2000, ['x', 'y', 'probs', 'preds']]
    out_data = out_data.rename(columns={'probs': 'probs_2000',
                                        'preds': 'preds_2000'})
    out_data.index = out_data.apply(
        lambda row: str(row['x']) + str(row['y']), axis=1)

    for year in range(2001, 2014):
        year_data = X_df.loc[X_df.year == year, ['x', 'y', 'probs', 'preds']]
        year_data.index = year_data.apply(
            lambda row: str(row['x']) + str(row['y']), axis=1)
        out_data['probs_%s' % year] = year_data['probs']
        out_data['preds_%s' % year] = year_data['preds']
    out_data.index = range(out_data.shape[0])
    print(out_data.head())
    out_data.to_csv(HISTORIC_DATA_PATH + 'recent_data_fitted_full.csv')

    

if __name__ == '__main__':
    main()
