# SDM

### Data Preparation
Run `start.sh` to clean and prepare data. This script does the following:
* creates the necessary data output sub-directories in `data/` if not already present
* runs `python/prep_data.py`, which does the following:
  * removes redundant columns from the data
  * restricts the data to the bounding box in which the Mountain Pine Beetle is found
  * splits the data into training, validation, and test sets according to each of 3 regimes:
    * random (all cells equally likely to belong to each set)
    * internal (test region fully enclosed by validation region, fully enclosed by training region)
    * edge (test region along specified edge [n, s, e, w]; validation region between test and training regions)
  * Writes `X_train.csv`, `y_train.csv`, `X_valid.csv`, `y_valid.csv`, `X_test.csv`, and `y_test.csv` to each of the following directories:

```
data/
  edge/
    e/
    n/
    s/
    w/
  internal/
  random/
```
