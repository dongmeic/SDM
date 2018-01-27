#!/bin/bash

# Loads python3 module, creates necessary directories and runs
# python/prep_data.py to split data into various train/validation/test sets

ENV='cluster'
DATA_PATH=./data/

echo Loading python3 module...
module load python3

echo Checking that required directories exist
for DIRECTORY in 'random' 'internal' 'edge/n' 'edge/s' 'edge/w' 'edge/e' 'year'
do
    [ -d "$DATA_PATH$ENV/$DIRECTORY" ] || mkdir -p $DATA_PATH$ENV/$DIRECTORY
done
    

echo Running prep_data.py...
./python/prep_data.py -e $ENV -d $DATA_PATH

echo Contents of $DATA_PATH$ENV
ls $DATA_PATH$ENV
