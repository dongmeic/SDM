import os

import numpy as np
import pandas as pd


class ModelMatrixConstructor:
    def __init__(self, data_dir):
        self.DATA_DIR = data_dir
        self.SQUARE = [
            'lon', 'lat', 'etopo1', 'age', 'density', 'JanTmin', 'MarTmin', 'maxT',
            'TMarAug', 'summerTmean', 'AugTmean','PMarAug','TMarAug','Tmin', 'summerP2',
            'summerP1', 'OctTmin','Tvar', 'TOctSep', 'summerP0', 'Pmean', 'POctSep', 'wd',
            'PcumOctSep', 'PPT', 'cwd']
        self.CUBE = ['ddAugJul','ddAugJun','Tmean','TMarAug','fallTmean','TOctSep','vpd','AugMaxT','AugTmax']
        self.INTERACTIONS = ['age:density', 'age:summerTmean', 'age:summerP0', 'age:ddAugJul', 'density:JanTmin', 
                             'density:Tmean', 'density:OptTsum', 'density:wd', 'density:mi', 'density:ddAugJul']
        self.DROP = None

    def set_squares(self, squares):
        squares = squares if isinstance(squares, list) else [squares]
        self.SQUARE = squares

    def set_cubes(self, cubes):
        cubes = cubes if isinstance(cubes, list) else [cubes]
        self.CUBE = cubes

    def set_interactions(self, interactions):
        interactions = (interactions if isinstance(interactions, list)
                        else [interactions])
        self.INTERACTIONS = interactions

    def set_drop_columns(self, drops):
        self.DROP = drops if isinstance(drops, list) else [drops]
        
    def construct_model_matrices(self):
        train_X_files = sorted(
            [f for f in os.listdir(self.DATA_DIR) if 'X_train' in f])
        valid_X_files = sorted(
            [f for f in os.listdir(self.DATA_DIR) if 'X_valid' in f])
        test_X_files  = sorted(
            [f for f in os.listdir(self.DATA_DIR) if 'X_test' in f])
        train_y_files = sorted(
            [f for f in os.listdir(self.DATA_DIR) if 'y_train' in f])
        valid_y_files = sorted(
            [f for f in os.listdir(self.DATA_DIR) if 'y_valid' in f])
        test_y_files  = sorted(
            [f for f in os.listdir(self.DATA_DIR) if 'y_test' in f])
        print('Train:\n ', train_X_files, '\n ', train_y_files)
        print('Valid:\n ', valid_X_files, '\n ', valid_y_files)
        print('Test:\n ',  test_X_files,  '\n ', test_y_files)
        X_train = self._load_data_set(train_X_files)
        X_valid = self._load_data_set(valid_X_files)
        X_test  = self._load_data_set(test_X_files)
        y_train = self._load_data_set(train_y_files)
        y_valid = self._load_data_set(valid_y_files)
        y_test  = self._load_data_set(test_y_files)

        if self.DROP:
            X_train = X_train.drop(self.DROP, axis=1)
            X_valid = X_valid.drop(self.DROP, axis=1)
            X_test  = X_test.drop(self.DROP,  axis=1)
        data_sets = [
            [X_train, y_train], [X_valid, y_valid], [X_test, y_test]]
        for i, [X, y] in enumerate(data_sets):
            X = X.reindex()
            y = y.reindex()
            if 'density' in list(X):
                X = self._fill_na(X, 'density')
                y = y.loc[np.isnan(X['density']) == False, :]
                X = X.loc[np.isnan(X['density']) == False, :]
            X = self._add_all_cols(X.copy())
            X = X.reindex()
            y = y.reindex()
            data_sets[i] = [X, y]
        return data_sets

    def _load_data_set(self, set_files):
        print('Loading data from %s...' % set_files)
        data_set = pd.read_csv('%s/%s' % (self.DATA_DIR, set_files.pop()))
        for f in set_files:
            next_chunk = pd.read_csv('%s/%s' % (self.DATA_DIR, f))
            data_set = data_set.append(next_chunk)
        data_set.index = range(data_set.shape[0])
        return data_set

    def _add_all_cols(self, data_set):
        data_set = self._add_squares(data_set)
        data_set = self._add_cubes(data_set)
        data_set = self._add_interactions(data_set)
        return data_set
    
    def _add_squares(self, data_set):
        print('Adding quadratic terms...')
        for field in self.SQUARE:
            data_set['%s_sq' % field] = data_set[field] ** 2
        return data_set

    def _add_cubes(self, data_set):
        print('Adding cubic terms...')
        for field in self.CUBE:
            data_set['%s_cub' % field] = data_set[field] ** 3
        return data_set

    def _add_interactions(self, data_set):
        print('Adding interactions...')
        for field in self.INTERACTIONS:
            fields = field.split(':')
            if len(fields) == 2:
                f1, f2 = fields
                data_set[field] = data_set[f1] * data_set[f2]
            elif len(fields) == 3:
                f1, f2, f3 = fields
                data_set[field] = data_set[f1] * data_set[f2] * data_set[f3]
        return data_set

    def _fill_na(self, df, field):
        '''
        Fills value by taking the average of cells above and below (or just 
        one if both not available)
        '''
        print('Attempting to fill NAs with average of neighboring cells.')
        iterations = 0
        while sum(np.isnan(df[field])):
            for i in range(df.shape[0]):
                if np.isnan(df.loc[i, field]):
                    use = []
                    x = int(df.loc[i, 'x'])
                    x_above = int(df.loc[i - 1, 'x']) if i > 0 else np.nan
                    x_below = (int(df.loc[i + 1, 'x']) if i < df.shape[0] - 1
                               else np.nan)
                    if abs(x - x_above) == 1:
                        use.append(x_above)
                    if abs(x - x_below) == 1:
                        use.append(x_below)
                    if len(use):
                        df.loc[i, field] = np.nanmean(use)
            iterations += 1
            if iterations > 2:
                print('Could not fill %s for %d rows.'
                      % (field, sum(np.isnan(df[field]))))
                return df
        return df


# Test
#mod_matrix_constructor = ModelMatrixConstructor(
#    '../../data/Xy_internal_split_data')
#data_sets = mod_matrix_constructor.construct_model_matrices()
#print(list(data_sets[0][0]))
#print(list(data_sets[0][1]))
