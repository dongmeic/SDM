import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
#from pylab import *


# Filtering data by geographic range (limit to bounding box)--------------------
class Point:
    def __init__(self, x, y):
        self.x = x
        self.y = y

    def __str__(self):
        return '(%s, %s)' % (self.x, self.y)
                    

        
class BoundingBox:
    def __init__(self, lower_left, upper_right):
        assert type(lower_left) is Point and type(upper_right) is Point
        self.lower_left = lower_left
        self.upper_right = upper_right

    def __str__(self):
        return ('Lower left: %s; Upper right: %s'
                % (self.lower_left, self.upper_right))



def restrict_to_bounding_box(data, bounding_box, coord_type='lon_lat'):
    '''
    Returns data restricted to rows enclosed in bounding box
    
    Args:
    data: Dataframe with either x and y columns, or lon and lat columns 
          (or both)
    bounding_box: BoundingBox
    coord_type: 'lon_lat' or 'xy' - tells which fields to use to filter 
                data
    
    Returns: DataFrame
    '''
    
    assert coord_type in ['lon_lat', 'xy']
    x_min = bounding_box.lower_left.x
    y_min = bounding_box.lower_left.y
    x_max = bounding_box.upper_right.x
    y_max = bounding_box.upper_right.y
    x, y = ('x', 'y') if coord_type == 'xy' else ('lon', 'lat')
    
    return data[(x_min <= data[x]) & (data[x] <= x_max) &
                (y_min <= data[y]) & (data[y] <= y_max)]


def column2matrix(df, column, cell_dim=10000):
    '''
    Convert a column from DataFrame df into a matrix representation with the 
    upper-left cell indexing beginning at [0, 0].
    It is expected that the DataFrame has columns x and y.
    
    Args:
    df: DataFrame: the source data
    column: string: the column name to extract
    cel_dim: numeric: the dimensions of each grid cell
    
    Returns: np.ndarray (a 2D list; matrix)
    '''

    xs = sorted(df.x.unique())
    ys = sorted(df.y.unique())
    matrix = np.array([[np.nan for y in range(len(ys))]
                       for x in range(len(xs))])

    for row in range(df.shape[0]):
        x, y, value = df.loc[row, ['x', 'y', column]]
        i = int((x - xs[0]) / cell_dim)
        j = int((y - ys[0]) / cell_dim)
        matrix[i, j] = value

    return matrix                                                    


def get_bounding_box_by_mask_col(df, mask_column='beetle', coord_type='xy'):
        assert coord_type in ['xy', 'lon_lat']
        cols = ['x', 'y'] if coord_type == 'xy' else ['lon', 'lat']
        dtype = int if coord_type is 'xy' else float
        mask = np.isnan(df[mask_column]) == False
        masked_df = df.loc[mask, cols]
        x_min, x_max = masked_df['x'].min(), masked_df['x'].max()
        y_min, y_max = masked_df['y'].min(), masked_df['y'].max()

        try:
            lower_left = Point(dtype(x_min), dtype(y_min))
            upper_right = Point(dtype(x_max), dtype(y_max))
            return BoundingBox(lower_left, upper_right)
        except Exception as e:
            print('Bad value passed to Point() constructor.  Could not '
                  'create bounding box.\nx range: [%s, %s]\ny range: [%s, %s]'
                  % (x_min, x_max, y_min, y_max))
            print(e)
            return None
                                


# Reformatting the structure of the data----------------------------------------
def reduce_masks(masks, dataframe):
    df = dataframe.copy()
    for mask in masks:
        df = reduce_mask_to_single(mask, df)
        df = mask_to_binary(mask, df)
    return df


def reduce_mask_to_single(mask, dataframe):
    assert mask in ['btl', 'vgt']
    df = dataframe.copy()
    drop_cols = [field for field in list(df)
                 if field.startswith(mask) and '_cpja_' not in field]
    df = df.drop(drop_cols, axis=1)
    return df


def mask_to_binary(mask, dataframe):
    assert mask in ['btl', 'vgt', 'mask']
    df = dataframe.copy()
    
    for col in list(df):
        if col.startswith(mask):
            df[col] = df[col].apply(lambda x: 0 if np.isnan(x) else 1)

    return df


def make_single_year_dataframe(source_df, year, static_df, verbose=True):
    static = static_df.copy()
    n = source_df.shape[0]
    year_col = [year] * n
    df = pd.DataFrame(index=range(n), data=year_col, columns=['year'])

    for field in list(source_df):
        if field.endswith('.%s' % (year - 2000)):
            simple_field = field.split('.')[0]
            if 'btl' in simple_field:
                simple_field = 'beetle'
            elif 'vgt' in simple_field:
                simple_field = 'vegetation'
            df[simple_field] = source_df.pop(field)
        elif '.' not in field and year == 2000:
            simple_field = field
            if 'btl' in field:
                simple_field = 'beetle'
            elif 'vgt' in field:
                simple_field = 'vegetation'
            df[simple_field] = source_df.pop(field)
            
    for field in static:
        df[field] = static[field]
        
    if verbose:
        print('Dataframe for %d has dimensions:' % year, df.shape)
        
    return df, source_df
