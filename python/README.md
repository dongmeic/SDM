# python

## Files in this directory
* `data_manipulations.py`: code to reduce the original data set to make it more computationally efficient--
  * removes redundant columns
  * allows data to be filtered by a bounding box to omit out-of-range data
* `split_data.py`: code to divide the data into training, validation, and test sets.  Because of spatial (TODO: and temporal) autocorrelation in the data, different splitting regimes are available--
  * random: all raster cells equally likely to belong to each set
  * internal: validation set completely surrounded by training set; test set completely surrounded by validation set (allows for prediction of model to be tested on variable values within the range of the training set, but diminishes the role of autocorellation)
  * edge: test set is from one edge of the raster; validation set lies between test and training sets. Choice of edge may be specified by cardinal directions: 'n', 's', 'e', 'w' (allows testing of how well the model generalizes to regions _outside_ of the range from which the model was trained).
