import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
from sklearn.metrics import auc, roc_curve 


def load_data(data_dir):
    X_train = pd.read_csv(data_dir + 'X_train.csv')
    print('X_train:', X_train.shape)
    X_valid = pd.read_csv(data_dir + 'X_valid.csv')
    print('X_valid:', X_valid.shape)
    X_test  = pd.read_csv(data_dir + 'X_test.csv')
    print('X_test:',  X_test.shape)
    y_train = pd.read_csv(data_dir + 'y_train.csv')
    print('y_train:', y_train.shape)
    y_valid = pd.read_csv(data_dir + 'y_valid.csv')
    print('y_valid:', y_valid.shape)
    y_test  = pd.read_csv(data_dir + 'y_test.csv')
    print('y_test:',  y_test.shape)
    
    return [[X_train, y_train], [X_valid, y_valid], [X_test, y_test]]


def summarize(df, field, plot=True):
    quantiles = df.quantile(q=[0, 0.25, 0.5, 0.75, 1], axis=0)
    means = df.mean(axis=0)
    quants = quantiles[field]
    values = df[field]
    values = values[np.isnan(values) == False]
    n_nan  = values[np.isnan(values) == True].sum()
    is_finite = np.isfinite(values).all()

    print('\n%s:\n%10s%10s%10s%10s%10s%10s\n'
          '%10.2f%10.2f%10.2f%10.2f%10.2f%10.2f'
          % (field, 'min', '25%', 'med', 'mean', '75%', 'max',
             quants[0], quants[0.25], quants[0.5], means[field],
             quants[0.75], quants[1]))
    if plot:
        plt.figure();
        plt.hist(values);
        plt.title(field);
        plt.show();


def print_percent_presence(y, y_name):
        print('Percent presence in %s: %.2f%%' %
              (y_name, 100 * y.sum() / y.shape[0]))

        
def drop_nans(X_df, y_df, field, verbose=True):
    X = X_df.copy()
    y = y_df.copy()
    X = X.loc[np.isnan(X_df[field]) == False, :]
    y = y.loc[np.isnan(X_df[field]) == False, :]
    
    if verbose:
        print(X.shape, y.shape)
    return X, y


def vectorize(y):
    # [1, 0, 0, 1] -> [[0, 1], [1, 0], [1, 0], [0, 1]]
    y = y.tolist()
    for i in range(len(y)):
        y[i] = [1, 0] if y[i] == [0] else [0, 1]
        
    return np.array(y)


def preds2probs(preds):
    return [pred[1] for pred in preds]


def binarize(preds):
        return [[round(x) for x in p] for p in preds]

    
def one_cold(one_hot_matrix):
    # [[0, 1], [0, 1], [1, 0]] -> [1, 1, 0]
    return [np.argmax(vector) for vector in one_hot_matrix]


def print_cm(tp, tn, fp, fn):
    print('Confusion Matrix:')
    print('         Predicted:')
    print('         \t1\t\t0')
    print('Actual: 1\t%d\t\t%d' %(tp, fn))
    print('        0\t%d\t\t%d' %(fp, tn))




def make_interactions(dataframe, interactions):
    df = dataframe.copy()
    for interaction in interactions:
        main_effects = interaction.split(':')
        df[interaction] = df[main_effects[0]] * df[main_effects[1]]
    return df


def make_confusion_matrix(targets, pred_probs, threshold, verbose=True):
    targets = np.array(targets)
    pred_probs = np.array(pred_probs)
    preds = 1 * (pred_probs >= threshold)

    #preds_binary = binarize(preds)
    tp = sum(preds & targets)
    tn = sum(np.logical_not(preds) & np.logical_not(targets))
    fp = sum(preds & np.logical_not(targets))
    fn = sum(np.logical_not(preds) & targets)

    if verbose:
        print_cm(tp, tn, fp, fn)

    return {'tp': tp, 'fp': fp,'tn': tn, 'fn': fn}


def get_metrics(cm):
    accuracy  = ((cm['tp'] + cm['tn']) /
                 (cm['tp'] + cm['tn'] + cm['fp'] + cm['fn']))
    precision = cm['tp'] / (cm['tp'] + cm['fp'])
    recall    = cm['tp'] / (cm['tp'] + cm['fn'])
    F1        = 2 * precision * recall / (precision + recall)

    print('Accuracy: ', accuracy)
    print('Precision:', precision)
    print('Recall:   ', recall)
    print('F1:       ', F1)


def get_auc(target, preds):
    fpr, tpr, _ = roc_curve(target, preds)
    mod_auc = auc(fpr, tpr)
    print('AUC:      ', mod_auc)
    
    return { 'fpr': fpr, 'tpr': tpr, 'auc': mod_auc }


def plot_roc(fpr, tpr):
    plt.plot(fpr, tpr, 'k')
    plt.plot([0, 1], [0, 1], 'r')
    plt.xlabel('False Positive Rate (1 - Specificity)')
    plt.ylabel('True Positive Rate (Sensitivity)')
    plt.title('ROC Curve')
    plt.show()


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
    matrix = np.array([[np.nan for y in range(len(ys))]
                       for x in range(len(xs))])
    for row in df.index:
        x, y, value = df.loc[row, ['x', 'y', column]]
        i = int((x - xs[0]) / cell_dim)
        j = int((y - ys[0]) / cell_dim)
        matrix[i, j] = value
    return matrix
