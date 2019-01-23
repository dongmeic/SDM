import os
import sys
import time

import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
from pylab import *
from sklearn.linear_model import LogisticRegression, Ridge
from sklearn.pipeline import Pipeline
from sklearn.model_selection import GridSearchCV
from sklearn.preprocessing import StandardScaler

sys.path.append('/gpfs/projects/gavingrp/dongmeic/sdm/python/models_new')
import model_utils_new as util
from construct_model_matrices_random import ModelMatrixConstructor

i = sys.argv[1]
print('iteration:', i)

model = 'model2'

DATA_DIR = '/gpfs/projects/gavingrp/dongmeic/sdm/data/Xy_random_split_data'
IMG_DIR = '/gpfs/projects/gavingrp/dongmeic/beetle/output/plots/images/iter' + i
OUT_DIR = '/gpfs/projects/gavingrp/dongmeic/beetle/output/tables/iter' + i
REGULARIZER = 'l2'
print('Regularizer:', REGULARIZER)

DIR = '/gpfs/projects/gavingrp/dongmeic/beetle/output/daily/20181228/iter'

def main():
    make_dirs()
    plt.rcParams['figure.figsize'] = 10, 8
    TEST = False
    dropBtl = False
    dropVgt = False
    matrix_constructor = ModelMatrixConstructor(DATA_DIR, TEST)
    matrix_constructor.construct_model_matrices()
    if model == 'model1':
    	test_vars = matrix_constructor.get_variables(random=True)
    else:
    	test_vars = matrix_constructor.add_beetle_vars(random=True)
    	if model == 'model2':
    		dropBtl = True
    	elif model != 'model5':
    		dropVgt = True
    for var in ['x', 'y', 'year']:
    		test_vars.append(var)
    test_vars = sorted(test_vars)
    data_sets = matrix_constructor.select_variables(test_vars)
    [[X_train, y_train], [X_valid, y_valid], [X_test, y_test]] = data_sets
    for (data_set, name) in zip(data_sets, ['Train', 'Valid', 'Test']):
    		print_dims(data_set, name)
    util.print_percent_presence(y_train, 'y_train')
    util.print_percent_presence(y_valid, 'y_valid')
    util.print_percent_presence(y_test, 'y_test')
    y_train.columns=['btl_t']
    y_valid.columns=['btl_t']
    y_test.columns=['btl_t']
    full_train = X_train.copy()
    full_valid = X_valid.copy()
    full_test = X_test.copy()
    full_train['btl_t'] = y_train['btl_t']
    full_valid['btl_t'] = y_valid['btl_t']
    full_test['btl_t'] = y_test['btl_t']
    drop = ['x', 'y', 'year']
    if dropBtl:
    	btl_sum9 = [var for var in list(X_train) if 'btl' in var or 'sum9' in var]
    	vgt = [var for var in list(X_train) if 'age' in var or 'density' in var]
    	drop += vgt
    	drop += btl_sum9
    	drop.append('vgt')
    if dropVgt:
    	vgt = [var for var in list(X_train) if 'age' in var or 'density' in var]
    	drop += vgt
    X_train = X_train.drop(drop, axis=1)
    X_valid = X_valid.drop(drop, axis=1)
    X_test  = X_test.drop(drop, axis=1)
    predictors = list(X_train)
    X_train, X_valid, X_test = scale_data(X_train, X_valid, X_test)
    y_train = y_train['btl_t'].values.reshape(-1)
    y_valid = y_valid['btl_t'].values.reshape(-1)
    y_test  = y_test['btl_t'].values.reshape(-1)

    print('Fitting model...')
    BEST_C = get_best_C(X_train, y_train, X_valid, y_valid, predictors)
    logistic_clf = LogisticRegression(C=BEST_C, penalty=REGULARIZER, solver='saga', n_jobs=-1)
    logistic_clf.fit(X_train, y_train)
    preds = logistic_clf.predict(X_test)
    probs = logistic_clf.predict_proba(X_test)
    accuracy = sum(y_test == preds) / len(preds)
    print('Test accuracy:', accuracy)   

    pred_ps = logistic_clf.predict_proba(X_test)
    pred_ps = np.array([p[1] for p in pred_ps])
    THRESHOLD = 0.5
    preds = get_predictions_at_threshold(pred_ps, THRESHOLD)
    best_threshold = threshold_plot(pred_ps, y_test);
    print('\n\nConfusion Matrices============================================')
    print('0.5 threshold:')
    cm = util.make_confusion_matrix(y_test, pred_ps, 0.5)
    metrics = util.get_metrics(cm)
    print('\n\nOptimal threshold:', best_threshold['threshold'])
    cm = util.make_confusion_matrix(
            y_test, pred_ps, best_threshold['threshold'])
    metrics = util.get_metrics(cm)
    auc_metrics = util.get_auc(y_test, pred_ps, OUT_DIR)
    util.plot_roc(
        auc_metrics['fpr'], auc_metrics['tpr'], path='%s/roc.png' % IMG_DIR)
    coefs = pd.DataFrame(
            [[pred, coef]
             for pred, coef in zip(predictors, logistic_clf.coef_[0])],
            columns=['predictor', 'coef'])
    coefs['abs'] = np.abs(coefs.coef)
    coefs = coefs.sort_values('abs', ascending=False)
    coefs = coefs.drop(['abs'], axis=1)
    print(coefs)
    coefs.to_csv('%s/coefficients.csv' % OUT_DIR, index=False)
    print('\n\nModel intercept:', logistic_clf.intercept_)

    pred_ps_train = logistic_clf.predict_proba(X_train)
    pred_ps_train = np.array([p[1] for p in pred_ps_train])
    pred_ps_valid = logistic_clf.predict_proba(X_valid)
    pred_ps_valid = np.array([p[1] for p in pred_ps_valid])
    full_train['probs'] = pred_ps_train
    full_train['preds'] = get_predictions_at_threshold(
            pred_ps_train, best_threshold['threshold'])
    full_valid['probs'] = pred_ps_valid
    full_valid['preds'] = get_predictions_at_threshold(
            pred_ps_valid, best_threshold['threshold'])
    full_test['probs'] = pred_ps
    full_test['preds'] = get_predictions_at_threshold(
            pred_ps, best_threshold['threshold'])
    all_data = full_train.append(full_valid).append(full_test)
    all_data.index = range(all_data.shape[0])
    years = sorted(full_train.year.unique())
    df = all_data[['x', 'y', 'year', 'btl_t', 'probs', 'preds']]
    df.to_csv('%s/predictions.csv' % OUT_DIR, index=False)

    print('\n\nGenerating prediction plots==================================')
    for year in years:
        print('  Train...')
        make_actual_pred_and_error_matrices(
            full_train,
            year,
            plot=True,
            path='%s/pred_plot_train_%d.png' % (IMG_DIR, year))
        print('  Valid...')
        make_actual_pred_and_error_matrices(
            full_valid,
            year,
            plot=True,
            path='%s/pred_plot_valid_%d.png' % (IMG_DIR, year))
        print('  Test...')
        make_actual_pred_and_error_matrices(
            full_test,
            year,
            plot=True,
            path='%s/pred_plot_test_%d.png' % (IMG_DIR, year))
        print('  Combined probabilities...')
        make_actual_pred_and_error_matrices(
            all_data,
            year,
            pred_type='probs',
            plot=True,
            path='%s/prob_plot_all_%d.png' % (IMG_DIR, year))
    print('all done!')
            
def make_dirs():
    for d in [IMG_DIR, OUT_DIR]:
        if not os.path.exists(d):
            os.makedirs(d)
            
        
def print_dims(data_set, name):
    print('%s:\n X: %r\n y: %r'
          % (name, data_set[0].shape, data_set[1].shape))


def scale_data(X_train, X_valid, X_test):
    scaler = StandardScaler()
    X_train = scaler.fit_transform(X_train)
    X_valid = scaler.transform(X_valid)
    X_test  = scaler.transform(X_test)
    return X_train, X_valid, X_test

def get_best_C(X_train, y_train, X_valid, y_valid, predictors):
		l_mods = []
		Cs = np.logspace(-4, 0, 5)
		best_C = np.nan
		best_accuracy = 0
		t0 = time.time()
		best_penalty = None
		for C in Cs:
				print('Testing C =', C)
				for penalty in ['l1']:
						print('  %s:' % penalty, end=' ')
						logistic_clf = LogisticRegression(C=C, penalty=penalty, solver='saga', n_jobs=-1)
						logistic_clf.fit(X_train, y_train)
						preds = logistic_clf.predict(X_valid)
						accuracy = sum(y_valid == preds) / len(preds)
						a = [[pred, coef] for pred, coef in zip(predictors, logistic_clf.coef_[0])]
						sig_preds = []
						sig_coefs = []
						for pred, coef in a:
								if abs(coef) > 0:
										sig_preds.append(pred)
										sig_coefs.append(coef)
						print([sig_preds[i] for i in argsort(np.abs(sig_coefs))[::-1]])
						print([sig_coefs[i] for i in argsort(np.abs(sig_coefs))[::-1]])						
						if (accuracy > best_accuracy):
								best_C = C
								best_accuaracy = accuracy
								best_penalty = penalty
						print('Validation accuracy:', round(accuracy, 4))
						l_mods.append(accuracy)
						print('Elapsed time: %.2f minutes' % ((time.time() - t0) / 60))
		print(l_mods)
		return best_C

def get_predictions_at_threshold(pred_ps, threshold):
    return 1 * (pred_ps >= threshold)


def threshold_plot(pred_ps, targets, plot=False):
    thresholds = np.linspace(0, 1, 500)
    accuracies = []
    n = len(pred_ps)
    for threshold in thresholds:
        preds = get_predictions_at_threshold(pred_ps, threshold)
        accuracies.append((preds == targets).sum() / n)
    if plot:
        plt.plot(thresholds, accuracies);
    optimal_threshold = thresholds[np.argmax(accuracies)]
    optimal_accuracy = max(accuracies)
    if plot:
        plt.plot([optimal_threshold, optimal_threshold],
                 [min(accuracies), max(accuracies)],
                 'r')
        plt.plot([0, 1], [optimal_accuracy, optimal_accuracy], 'r')
        plt.xlabel('Threshold for predicting "Renewal"')
        plt.ylabel('Accuracy')
    return {'threshold': optimal_threshold, 'accuracy': optimal_accuracy}


def pred_plot(actual_matrix, pred_matrix, error_matrix, year, path):
    fig = plt.figure()
    plt.subplot(131)
    imshow(np.rot90(actual_matrix));
    plt.title('%d Actual' % year);
    plt.subplot(132)
    imshow(np.rot90(pred_matrix));
    plt.title('%d Predicted' % year);
    plt.subplot(133)
    imshow(np.rot90(error_matrix));
    plt.title('%d Error' % year);
    fig.savefig(path)


def make_actual_pred_and_error_matrices(
        data, year, pred_type='preds', plot=False, path=''):
    data_year = data.loc[data.year == year, :]
    actual_matrix = util.column2matrix(data_year, 'btl_t')
    pred_matrix   = util.column2matrix(data_year, pred_type)
    error_matrix  = pred_matrix - actual_matrix
    if plot:
        pred_plot(actual_matrix, pred_matrix, error_matrix, year, path)
    return actual_matrix, pred_matrix, error_matrix
    
if __name__ == '__main__':
    main()
