import numpy as np

def column2matrix(dataframe, column, cell_dim=10000):
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
    df = dataframe.copy()
    x_min = df.x.min()
    y_min = df.y.min()
    df.x -= x_min
    df.y -= y_min
    xs = sorted(df.x.unique())
    ys = sorted(df.y.unique())
    #matrix = np.array([[np.nan for y in range(len(ys))]
    #                   for x in range(len(xs))])
    matrix = np.array([[np.nan for y in range(max(ys) + 1)]
                       for x in range(max(xs) + 1)])
    #for row in df.index:
    for row in range(df.shape[0]):
        x, y, value = df.loc[row, ['x', 'y', column]]
        i = int((x - xs[0]) / cell_dim)
        j = int((y - ys[0]) / cell_dim)
        matrix[i, j] = value
    return matrix
