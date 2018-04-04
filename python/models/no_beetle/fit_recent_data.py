import os
import sys
import time

import numpy as np
import pandas as pd
from sklearn.linear_model import LogisticRegression
from sklearn.preprocessing import StandardScaler

sys.path.append('..')
import model_utils as util

DATA_PATH =  '../../../data/cluster/year/'
HISTORIC_DATA_PATH = '../../../data/cluster/historic/'
OPTIMAL_THRESHOLD = 0.60521042084168331

sq_fields = [
        'meanTemp_Annual', 'meanTemp_AprAug', 'meanTemp_Aug',
        'meanMinTemp_DecFeb', 'meanMinTemp_Oct', 'meanMinTemp_Jan',
        'meanMinTemp_Mar', 'meanMaxTemp_Aug', 'precip_meanAnnual',
        'precip_JunAug', 'precipPrevious_JunAug', 'precip_OctSep',
        'precipPrevious_OctSep', 'precip_growingSeason',
        'elev_etopo1', 'lat', 'lon']
interactions = [
        'meanMinTemp_Oct:precip_OctSep', 'precip_meanAnnual:precip_OctSep',
        'precip_OctSep:precipPrevious_OctSep', 'meanTemp_Aug:meanMinTemp_Oct',
        'precip_OctSep:lon', 'precip_OctSep:precip_growingSeason',
        'precip_OctSep:meanMaxTemp_Aug', 'meanMinTemp_Oct:precip_meanAnnual',
        'precip_OctSep:meanTemp_Aug', 'precip_OctSep:meanMinTemp_Oct',
        'precip_OctSep:elev_etopo1', 'precip_OctSep:elev_etopo1',
        'precip_OctSep:lat', 'precip_OctSep:precip_growingSeason',
        'precip_OctSep:precipPrevious_OctSep',
        'precip_OctSep:precip_meanAnnual', 'precip_OctSep:precip_OctSep',
        'meanMaxTemp_Aug:precip_OctSep', 'meanTemp_AprAug:precip_OctSep',
        'precip_OctSep:varPrecip_growingSeason', 'meanTemp_Aug:precip_OctSep']

def main():
    [[X_train, y_train],
     [X_valid, y_valid],
     [X_test, y_test]] = util.load_data(DATA_PATH)
    
    X = X_train.append(X_valid).append(X_test)
    y = y_train.append(y_valid).append(y_test)
    del X_train
    del X_valid
    del X_test
    del y_train
    del y_valid
    del y_test
    X = make_squared(X, sq_fields)
    X = make_interactions(X, interactions)
    full = X.copy()
    X = X.drop(
        ['studyArea', 'x', 'y', 'elev_srtm30', 'year',
         'varPrecip_growingSeason', 'precip_OctSep:varPrecip_growingSeason'],
        axis=1)
    predictors = list(X)
    scaler = StandardScaler()
    X = scaler.fit_transform(X)
    y = y['beetle'].values.reshape(-1)
    logistic_clf = LogisticRegression(C=0.001, penalty='l2')
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

    for year in range(2001, 2015):
        year_data = X_df.loc[X_df.year == year, ['x', 'y', 'probs', 'preds']]
        year_data.index = year_data.apply(
            lambda row: str(row['x']) + str(row['y']), axis=1)
        out_data['probs_%s' % year] = year_data['probs']
        out_data['preds_%s' % year] = year_data['preds']
    out_data.index = range(out_data.shape[0])
    print(out_data.head())
    out_data.to_csv(HISTORIC_DATA_PATH + 'recent_data_fitted_no_beetle.csv')

    
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


if __name__ == '__main__':
    main()
