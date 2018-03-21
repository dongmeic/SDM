#!/usr/bin/env python3

import bz2
import matplotlib.pyplot as plt
import numpy as np
import os
import pickle
import sys
import time
from keras.callbacks import ModelCheckpoint
from keras.layers import (
    Activation, BatchNormalization, Conv2D, Dense, Dropout, Flatten,
    MaxPooling2D)
from keras.models import Sequential
from keras.optimizers import Adam
from keras.utils import np_utils
from pprint import pprint
#from pylab import *
from sklearn.preprocessing import StandardScaler

DATA_DIR = '../../../data/cluster/year/'
OUT_DIR = './weights/'
TEST_YEARS  = range(2000, 2003) # 2000 - 02
VALID_YEARS = range(2003, 2006) # 2003 - 05
TRAIN_YEARS = range(2006, 2014) # 2006 - 13
# (2014 excluded from this model b/c it has no `following year` beetle data
YEARS_PER_SET = (TRAIN_YEARS, VALID_YEARS, TEST_YEARS)
VERBOSE = True
N_TO_AVERAGE_OVER = 100 # last n epochs to average loss over

# Model Hyperparameters
BUFFER = 4 # number of cells to include in each direction around target cell
N_CLASSES = 2 # values in response (1, 0) or beetle (presence, absence)
HEIGHT = WIDTH = 2*BUFFER + 1
ETA = 0.0001 # Learning rate
BATCH = 512
EPOCHS = 3 # 10000
DROPOUT = 0
BETA_1 = 0.9
BETA_2 = 0.999
EPSILON = 1e-08
DECAY = 0.001


def main(best_loss_so_far):
    ((X_train, Y_train), (X_valid, Y_valid), (X_test, Y_test)) = load_all_data(
        DATA_DIR, YEARS_PER_SET, VERBOSE)
    train_norm, valid_norm, test_norm = normalize(X_train, X_valid, X_test)
    LAYERS = train_norm.shape[3] # number of raster layers (predictors)
    train = (train_norm, Y_train)
    valid = (valid_norm, Y_valid)
    test  = (test_norm,  Y_test)
    print_setup(LAYERS)
    model = build_model(LAYERS)
    training_generator = data_generator(train, BUFFER)
    validation_generator = data_generator(valid, BUFFER)
    opt = Adam(
        lr=ETA, beta_1=BETA_1, beta_2=BETA_2, epsilon=EPSILON, decay=DECAY)
    model.compile(
        loss='binary_crossentropy', optimizer=opt, metrics=['accuracy'])
    checkpointer = ModelCheckpoint(filepath='./weights/convTemp.hdf5',
                                   verbose=1,
                                   save_best_only=True)
    print('Fitting model...')
    start = time.time()
    history = model.fit_generator(generator=training_generator,
                                  steps_per_epoch=BATCH,
                                  epochs=EPOCHS,
                                  validation_data=validation_generator,
                                  validation_steps=BATCH // 2,
                                  callbacks=[checkpointer],
                                  verbose=1)
    elapsed = time.time() - start
    print('Ran %d epochs in %.2f minutes' % (EPOCHS, (elapsed / 60)))
    plot_curves(history.history)
    loss_this_run = get_final_performance(history.history)
    save_data(loss_this_run, best_loss_so_far, model)

    
def load_all_data(data_dir, years_per_set, verbose=True):
    train_years, valid_years, test_years = years_per_set
    print('TRAINING DATA:')
    X_train, Y_train = load_xy_set(DATA_DIR, train_years, verbose=True)
    print('\n\n\nVALIDATION DATA:')
    X_valid, Y_valid = load_xy_set(DATA_DIR, valid_years, verbose=True)
    print('\n\n\nTEST DATA:')
    X_test, Y_test  = load_xy_set(DATA_DIR, test_years, verbose=True)
    return ((X_train, Y_train), (X_valid, Y_valid), (X_test, Y_test))


def load_xy_set(data_path, years, verbose=False):
    X_set = []
    Y_set = []
    for year in years:
        X, Y = load_xy(data_path, year, verbose)
        X_set.append(X)
        Y_set.append(Y)
    X = np.array(X_set)
    Y = np.array(Y_set)
    if verbose:
        print('\nX:', X.shape, '(years, width, height, layers)')
        print('Y:', Y.shape, '    (years, width, height)')    
    return (X, Y)

def load_xy(data_path, year, verbose=False):
    x_path = data_path + 'tensor20_%d.pkl.bz2' % year
    y_path = data_path + 'y_matrix%d.pkl.bz2' % year
    if verbose: print('\nLoading X tensor from %s' % x_path)
    X = pickle.load(bz2.open(x_path, 'rb'))
    if verbose: print('Loading Y tensor from %s' % y_path)
    Y = pickle.load(bz2.open(y_path, 'rb'))
    if verbose:
        print('  X: ', X.shape, '(width, height, layers)')
        print('  Y: ', Y.shape, '    (width, height)')
    return X, Y


def normalize(X_train, X_valid, X_test):
    n_layers = X_train.shape[3]
    for layer in range(n_layers):
        layer_max = np.nanmax(X_train[:, :, :, layer])
        X_train[:, :, :, layer] /= layer_max
        X_valid[:, :, :, layer] /= layer_max
        X_test[:,  :, :, layer] /= layer_max
    return X_train, X_valid, X_test


def data_generator(data, buffer_size):
    X_data, Y_data = data
    years, width, height, layers = X_data.shape

    def get_candidate():
        yr = np.random.choice(range(years))
        w = np.random.choice(range(buffer_size, width - buffer_size))
        h = np.random.choice(range(buffer_size, height - buffer_size))
        candidate = X_data[yr,
                           w - buffer_size:w + buffer_size + 1,
                           h - buffer_size:h + buffer_size + 1,
                           :]
        mY = Y_data[yr, w, h]
        return candidate, mY
    
    while True:
        mX, mY = get_candidate()
        while np.isnan(mX).any():
            mX, mY = get_candidate()
        mY = np.array(np_utils.to_categorical(mY, N_CLASSES))\
               .reshape([1, 2])
        mX = np.array(mX).reshape(
            [1, 2*buffer_size + 1, 2*buffer_size + 1, layers])
        yield mX, mY


def print_setup(layers):
    print('Starting Convolutional Neural Network with full data set using:\n'
          '  Input dimensions: %d x % d x %d (H x W x L)'
          % (HEIGHT, WIDTH, layers))
    params = get_params()
    for k, v in params.items():
        print('%-12s %s' % (k + ':', v))


def get_params():
    return {'ETA': ETA,
            'DROPOUT': DROPOUT,
            'BETA_1': BETA_1,
            'BETA_2': BETA_2,
            'EPSILON': EPSILON,
            'DECAY': DECAY,
            'EPOCHS': EPOCHS,
            'BATCH': BATCH,
            'BUFFER': BUFFER}


def build_model(layers):
    model = Sequential()
    model.add(Conv2D(32, (5, 5),
                     padding='same',
                     input_shape=(HEIGHT, WIDTH, layers)))
    model.add(Activation('relu'))
    model.add(MaxPooling2D(pool_size=(2, 2)))
    #model.add(Dropout(DROPOUT))

    model.add(Conv2D(64, (3, 3), padding='same'))
    model.add(Activation('relu'))
    model.add(MaxPooling2D(pool_size=(2, 2)))
    #model.add(Dropout(DROPOUT))

    model.add(Conv2D(128, (2, 2), padding='same'))
    model.add(Activation('relu'))
    model.add(MaxPooling2D(pool_size=(2, 2)))
    #model.add(Dropout(DROPOUT))

    model.add(Flatten())

    model.add(Dense(64))
    model.add(Activation('relu'))
    model.add(Dropout(DROPOUT))

    model.add(Dense(32))
    model.add(Activation('relu'))
    model.add(Dropout(DROPOUT))

    model.add(Dense(N_CLASSES))
    model.add(Activation('softmax'))

    if VERBOSE:
        model.summary()
    return model


def plot_curves(history):
    plot_loss_curve(history)
    plot_accuracy_curve(history)

    
def plot_loss_curve(history):
    plt.plot(history['loss'], 'k-', label='Training')
    plt.plot(history['val_loss'], 'r-', alpha=0.8, label='Validation')
    plt.xlabel('Epochs')
    plt.ylabel('Loss (Binary Cross-Entropy)')
    plt.legend()
    plt.show()


def plot_accuracy_curve(history):
    plt.plot(history['acc'], 'k-', label='Training')
    plt.plot(history['val_acc'], 'r-', alpha=0.8, label='Validation')
    plt.xlabel('Epochs')
    plt.ylabel('Accuracy')
    plt.legend()
    plt.show()


def get_final_performance(history):
    def get_final_avg(metric):
        return np.mean(history[metric][-N_TO_AVERAGE_OVER:])

    final_loss = get_final_avg('val_loss')
    print(
        'This run:\n'
        '              Loss    Accuracy\n'
        '  Training:   %.5f %.5f\n'
        '  Validation: %.5f %.5f\n'
        % (get_final_avg('loss'), get_final_avg('acc'),
           final_loss, get_final_avg('val_acc')))
    return final_loss


def save_data(loss_this_run, best_loss, model):
    if loss_this_run < best_loss:
        make_dir(OUT_DIR)
        print('New Best Model Found!\n')
        print('Saving to %s...' % (OUT_DIR + 'convBest.h5'))
        model.save(OUT_DIR + 'convBest.h5')
    else:
        print('Model did not outperform current best.  Not saving.')
        

def make_dir(path):
    if not os.path.isdir(path):
        print('Making required directory: %s...' % path)
        os.makedirs(path)
        return True
    return False

                 
if __name__ == '__main__':
    # best loss value for this model so far
    BEST_LOSS_SO_FAR = float(sys.argv[1]) if len(sys.argv) > 1 else np.inf 
    print('Best loss score so far:', BEST_LOSS_SO_FAR)
    main(BEST_LOSS_SO_FAR)
