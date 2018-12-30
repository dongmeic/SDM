import os

import numpy as np
import pandas as pd


class ModelMatrixConstructor:
    def __init__(self, data_dir, test=False):
        self.DATA_DIR = data_dir
        self.test = test
        self.categories = {
            'cold1': ['Jan20', 'Mar20', 'Acs', 'max.drop'],
            'cold2': ['JanTmin', 'MarTmin', 'OctTmin', 'Tmin', 'OctMin', 
                      'JanMin', 'MarMin', 'winterMin', 'minT'],
            'season': ['TMarAug', 'fallTmean', 'Tmean', 'Tvar', 'TOctSep',
                       'ddAugJul', 'ddAugJun'],
            'summer_temp': ['summerTmean', 'AugTmean', 'AugTmax', 'maxAugT',
                            'OptTsum', 'AugMaxT', 'maxT'],
            'rain1': ['PMarAug', 'summerP0', 'summerP1', 'summerP2', 'Pmean',
                      'POctSep', 'PcumOctSep', 'PPT'],
            'rain2': ['wd', 'vpd', 'mi', 'cwd']}

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
        X_train = self._load_data_set(train_X_files)
        X_valid = self._load_data_set(valid_X_files)
        X_test  = self._load_data_set(test_X_files)
        y_train = self._load_data_set(train_y_files)
        y_valid = self._load_data_set(valid_y_files)
        y_test  = self._load_data_set(test_y_files)
        data_sets = [
            [X_train, y_train], [X_valid, y_valid], [X_test, y_test]]
        self.data_sets = data_sets
        
    def select_variables(self, variables):
        all_variables = list(self.data_sets[0][0])
        for var in variables:
            if var not in all_variables and ':' in var:
                self._add_interaction_term(var)
        try:
            return self._select_variables_from_sets(variables)
        except BaseException as e:
            print('Error in select_variables():\n%s' % e)
    
    def get_random_variables(self):
        all_variables = list(self.data_sets[0][0])
        selected = [np.random.choice(vs) for k, vs in self.categories.items()]
        return selected
            
    def get_data_sets(self):
        return self.data_sets
    
    def _load_data_set(self, set_files):
        print('Loading data from %s...' % set_files)
        if self.test:
            YEAR = 2006
            file_name = [file for file in set_files if str(YEAR) in file][0]
            print(file_name)
            data_set = pd.read_csv('%s/%s' % (self.DATA_DIR, file_name))
            return data_set
        data_set = pd.read_csv('%s/%s' % (self.DATA_DIR, set_files.pop()))
        for f in set_files:
            next_chunk = pd.read_csv('%s/%s' % (self.DATA_DIR, f))
            data_set = data_set.append(next_chunk)
        data_set.index = range(data_set.shape[0])
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

    def _add_interaction_term(self, var):
        fields = var.split(':')
        for data_set in self.data_sets:
            if len(fields) == 2:
                f1, f2 = fields
                data_set[0][var] = data_set[0][f1] * data_set[0][f2]
            elif len(fields) == 3:
                f1, f2, f3 = fields
                data_set[var][0] = data_set[f1] * data_set[f2] * data_set[f3]

    def _select_variables_from_sets(self, variables):
        out = []
        for data_set in self.data_sets:
            X = data_set[0].copy()
            y = data_set[1].copy()
            X = X[variables]
            out.append([X, y])
        return out

# Test
#mod_matrix_constructor = ModelMatrixConstructor(
#    '../../data/Xy_internal_split_data')
#data_sets = mod_matrix_constructor.construct_model_matrices()
#print(list(data_sets[0][0]))
#print(list(data_sets[0][1]))
