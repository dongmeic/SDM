import os

import numpy as np
import pandas as pd


class ModelMatrixConstructor:
    def __init__(self, data_dir):
        self.DATA_DIR = data_dir
        self.SQUARE = [
            'lon', 'lat', 'etopo1', 'age', 'density', 'JanTmin', 'MarTmin',
            'TMarAug', 'summerTmean', 'AugTmean', 'AugTmax', 'GSP', 'PMarAug',
            'summerP0', 'OctTmin', 'fallTmean', 'winterTmin', 'Tmin', 'Tmean',
            'Tvar', 'TOctSep', 'summerP1', 'summerP2', 'Pmean', 'POctSep',
            'PcumOctSep', 'PPT', 'ddAugJul', 'ddAugJun']
        self.CUBE = ['age', 'density', 'summerP0', 'summerP1', 'summerP2']
        self.INTERACTIONS = [
            'lon:lat', 'lon:etopo1', 'lon:JanTmin', 'lon:GSP', 'lon:Tvar',
            'lon:Pmean', 'lon:POctSep', 'lon:PcumOctSep', 'lon:PPT',
            'lat:etopo1', 'lat:density', 'lat:JanTmin', 'lat:MarTmin',
            'lat:TMarAug', 'lat:AugTmax', 'lat:PMarAug', 'lat:summerP0',
            'lat:OctTmin', 'lat:fallTmean', 'lat:winterTmin', 'lat:Tmin',
            'lat:Tmean', 'lat:TOctSep', 'lat:summerP1', 'lat:summerP2',
            'etopo1:age', 'etopo1:MarTmin', 'etopo1:summerP0',
            'etopo1:winterTmin', 'etopo1:Tmin', 'etopo1:Tmean',
            'etopo1:TOctSep', 'etopo1:summerP2', 'density:JanTmin',
            'density:MarTmin', 'density:TMarAug', 'density:AugTmax',
            'density:PMarAug', 'density:summerP0', 'density:OctTmin',
            'density:fallTmean', 'density:winterTmin', 'density:Tmin',
            'density:Tmean', 'density:TOctSep', 'density:summerP1',
            'density:summerP2', 'JanTmin:MarTmin', 'JanTmin:summerP0',
            'JanTmin:OctTmin', 'JanTmin:fallTmean', 'JanTmin:winterTmin',
            'JanTmin:Tmin', 'JanTmin:Tmean', 'JanTmin:TOctSep',
            'JanTmin:summerP1', 'JanTmin:summerP2', 'JanTmin:Pmean',
            'JanTmin:POctSep', 'JanTmin:PcumOctSep', 'JanTmin:PPT',
            'MarTmin:TMarAug', 'MarTmin:AugTmax', 'MarTmin:summerP0',
            'MarTmin:OctTmin', 'MarTmin:fallTmean', 'MarTmin:winterTmin',
            'MarTmin:Tmin', 'MarTmin:Tmean', 'MarTmin:TOctSep',
            'MarTmin:summerP1', 'MarTmin:summerP2', 'TMarAug:summerP0',
            'TMarAug:Tmean', 'TMarAug:TOctSep', 'TMarAug:summerP2',
            'summerTmean:Tmean', 'summerTmean:TOctSep', 'summerTmean:Pmean',
            'summerTmean:PPT', 'AugTmean:Tmean', 'AugTmean:TOctSep',
            'AugTmean:PPT', 'AugTmax:PMarAug', 'AugTmax:summerP0',
            'AugTmax:fallTmean', 'AugTmax:Tmean', 'AugTmax:TOctSep',
            'AugTmax:summerP1', 'AugTmax:summerP2', 'AugTmax:Pmean',
            'AugTmax:POctSep', 'AugTmax:PcumOctSep', 'AugTmax:PPT', 'GSP:Tvar',
            'GSP:Pmean', 'GSP:POctSep', 'GSP:PcumOctSep', 'GSP:PPT',
            'PMarAug:Tvar', 'PMarAug:summerP1', 'PMarAug:summerP2',
            'PMarAug:Pmean', 'PMarAug:POctSep', 'PMarAug:PcumOctSep',
            'PMarAug:PPT', 'summerP0:OctTmin', 'summerP0:fallTmean',
            'summerP0:winterTmin', 'summerP0:Tmin', 'summerP0:Tmean',
            'summerP0:TOctSep', 'summerP0:summerP1', 'summerP0:summerP2',
            'OctTmin:summerP1', 'OctTmin:summerP2', 'fallTmean:winterTmin',
            'fallTmean:Tmin', 'fallTmean:Tmean', 'fallTmean:TOctSep',
            'fallTmean:summerP1', 'fallTmean:summerP2', 'winterTmin:Tmin',
            'winterTmin:Tmean', 'winterTmin:TOctSep', 'winterTmin:summerP1',
            'winterTmin:summerP2', 'winterTmin:Pmean', 'winterTmin:POctSep',
            'winterTmin:PcumOctSep', 'winterTmin:PPT', 'Tmin:Tmean',
            'Tmin:TOctSep', 'Tmin:summerP1', 'Tmin:summerP2', 'Tmin:POctSep',
            'Tmin:PcumOctSep', 'Tmin:PPT', 'Tmean:TOctSep', 'Tmean:summerP1',
            'Tmean:summerP2', 'Tvar:Pmean', 'Tvar:POctSep', 'Tvar:PcumOctSep',
            'Tvar:PPT', 'TOctSep:summerP1', 'TOctSep:summerP2',
            'summerP1:summerP2', 'summerP1:Pmean', 'summerP1:POctSep',
            'summerP1:PcumOctSep', 'summerP1:PPT', 'summerP2:Pmean',
            'summerP2:PPT', 'Pmean:POctSep', 'Pmean:PcumOctSep', 'Pmean:PPT',
            'POctSep:PcumOctSep', 'POctSep:PPT', 'PcumOctSep:PPT']

        
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
        data_sets = [
            [X_train, y_train], [X_valid, y_valid], [X_test, y_test]]
        for i, [X, y] in enumerate(data_sets):
            X = self._fill_na(X, 'density')
            X = X.loc[np.isnan(X['density']) == False, :]
            X = self._add_all_cols(X.copy())
            X.index = range(X.shape[0])
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
            f1, f2 = field.split(':')
            data_set[field] = data_set[f1] * data_set[f2]
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
                        df.loc[i, field] = np.mean(use)
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
