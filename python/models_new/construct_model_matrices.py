import os

import pandas as pd


class ModelMatrixConstructor:
    def __init__(self, data_dir):
        self.DATA_DIR = data_dir
        self.SQUARE = [
            'lon', 'lat', 'etopo1', 'age', 'density', 'JanTmin', 'MarTmin',
            'TMarAug', 'summerTmean', 'AugTmean', 'AugTmax', 'GSP', 'PMarAug',
            'summerP0', 'OctTmin', 'fallTmean', 'winterTmin', 'Tmin', 'Tmean',
            'Tvar', 'TOctSep', 'summerP1', 'summerP2', 'Pmean', 'POctSep',
            'PcumOctSep', 'PPT', 'drop0', 'drop5', 'ddAugJul', 'ddAugJun']
        self.CUBE = ['age', 'density', 'drop0', 'drop5']
        self.INTERACTIONS = [
            'lon:TMarAug', 'lon:AugTmean', 'lon:AugTmax', 'lon:OctTmin',
            'lon:Tmean', 'lon:TOctSep', 'lat:ddAugJul', 'lat:ddAugJun',
            'density:summerP0', 'density:summerP1', 'density:summerP2',
            'JanTmin:summerTmean', 'JanTmin:AugTmean', 'JanTmin:AugTmax',
            'JanTmin:ddAugJul', 'JanTmin:ddAugJun', 'MarTmin:AugTmean',
            'MarTmin:AugTmax', 'TMarAug:ddAugJul', 'TMarAug:ddAugJun',
            'summerTmean:OctTmin', 'summerTmean:winterTmin', 'summerTmean:Tmin',
            'summerTmean:ddAugJul', 'summerTmean:ddAugJun',
            'AugTmean:winterTmin', 'AugTmean:ddAugJul', 'AugTmean:ddAugJun',
            'AugTmax:ddAugJun', 'GSP:summerP0', 'GSP:summerP1', 'GSP:summerP2',
            'GSP:Pmean', 'GSP:POctSep', 'GSP:PcumOctSep', 'GSP:PPT',
            'PMarAug:summerP0', 'PMarAug:summerP2', 'PMarAug:POctSep',
            'PMarAug:PcumOctSep', 'PMarAug:PPT', 'OctTmin:ddAugJul',
            'OctTmin:ddAugJun', 'fallTmean:ddAugJun', 'winterTmin:ddAugJul',
            'winterTmin:ddAugJun', 'Tmin:ddAugJun', 'summerP1:POctSep',
            'summerP1:PcumOctSep','summerP1:PPT']
        
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
            data_sets[i] = [self._add_all_cols(X), y]
        return data_sets

    def _load_data_set(self, set_files):
        print('Loading data from %s...' % set_files)
        data_set = pd.read_csv('%s/%s' % (self.DATA_DIR, set_files.pop()))
        for f in set_files:
            next_chunk = pd.read_csv('%s/%s' % (self.DATA_DIR, f))
            data_set = data_set.append(next_chunk)
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


# Test
#mod_matrix_constructor = ModelMatrixConstructor(
#    '../../data/Xy_internal_split_data')
#data_sets = mod_matrix_constructor.construct_model_matrices()
#print(list(data_sets[0][0]))
#print(list(data_sets[0][1]))
