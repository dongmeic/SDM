import os

import numpy as np
import pandas as pd

DATA_DIR = '../../../data/cluster/historic/'
print([f for f in os.listdir(DATA_DIR) if 'pred' in f or 'recent' in f])

no_beetle = pd.read_csv(DATA_DIR + 'recent_data_fitted_no_beetle.csv')
full      = pd.read_csv(DATA_DIR + 'recent_data_fitted_full.csv')

print(full.head())
print('no_beetle:', no_beetle.shape)
print('  X:', no_beetle.x.min(), no_beetle.x.max())
print('  Y:', no_beetle.y.min(), no_beetle.y.max())

n = no_beetle.shape[0]
beetle_cells_2012 = no_beetle.preds_2012.sum()
print('  beetles in', beetle_cells_2012 / n)


print('full:', full.shape)
print('  X:', full.x.min(), full.x.max())
print('  Y:', full.y.min(), full.y.max())

n = full.shape[0]
beetle_cells_2012 = full.preds_2012.sum()
print('  beetles in', beetle_cells_2012 / n)


