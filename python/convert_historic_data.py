#!/usr/bin/env python3

import matplotlib.pyplot as plt
import numpy as np
import os
import pandas as pd

DATA_DIR = '../data/cluster/historic/'
FIELD_MAP = {
    'cpja_slice_msk': 'precip_JunAug',
    'cpos_slice_msk': 'precip_OctSep',
    'gsp_slice_msk':  'precip_growingSeason',
    'map_slice_msk':  'precip_meanAnnual',
    'mat_slice_msk':  'meanTemp_Annual',
    'mta_slice_msk':  'meanTemp_Aug',
    'mtaa_slice_msk': 'meanTemp_AprAug',
    'ntj_slice_msk':  'meanMinTemp_Jan',
    'ntm_slice_msk':  'meanMinTemp_Mar',
    'nto_slice_msk':  'meanMinTemp_Oct',
    'ntw_slice_msk':  'meanMinTemp_DecFeb',
    'pja_slice_msk':  'precipPrevious_JunAug',
    'pos_slice_msk':  'precipPrevious_OctSep',
    'vgp_slice_msk':  'varPrecip_growingSeason',
    'vgt_mat_msk':    'vegetation',
    'xta_slice_msk':  'meanMaxTemp_Aug',
    'etopo1':         'elev_etopo1'}


def main():
    files = [f for f in os.listdir(DATA_DIR)
             if f.endswith('.csv')
             and 'clean' not in f]
    for f in files:
        print('Converting %s' % f)
        year = int(f[-8:-4])
        if year > 1999:
            continue
        in_path = DATA_DIR + f
        out_path = '%sclean_%d.csv' % (DATA_DIR, year)
        data = read_and_format_data(in_path)
        data['year'] = year
        data = data.rename(columns=FIELD_MAP)
        data = mask_to_binary('vegetation', data)
        print('Writing reformatted data to %s...' % out_path)
        data.to_csv(out_path, index=False)

        
def read_and_format_data(file_path):
    data = pd.read_csv(file_path)
    redundant_vgt_columns = [field for field in list(data)
                             if field.startswith('vgt')][1:]
    drop_columns = redundant_vgt_columns + ['Unnamed: 0', 'srtm30', 'mask']
    data = data.drop(drop_columns, axis=1)
    return data

def mask_to_binary(mask, dataframe):
    df = dataframe.copy()
    for col in list(df):
        if col.startswith(mask):
            df[col] = df[col].apply(lambda x: 0 if np.isnan(x) else 1)
    return df


if __name__ == '__main__':
    main()
