#!/bin/bash
for i in {1..2};do
echo "#!/bin/bash
#SBATCH --partition=fat       ### Partition (like a queue in PBS)
#SBATCH --job-name=SDM${i}    ### Job Name
#SBATCH --output=SDM${i}.out       ### File in which to store job output
#SBATCH --error=SDM${i}.err        ### File in which to store job error messages
#SBATCH --time=1-00:00:00      ### Wall clock time limit in Days-HH:MM:SS
#SBATCH --nodes=1              ### Node count required for the job
#SBATCH --ntasks-per-node=1    ### Number of tasks to be launched per Node
#SBATCH --workdir=/gpfs/projects/gavingrp/dongmeic/beetle/output/daily/20181228 ###Set the working directory of the batch script to directory before it is executed
#SBATCH --mail-type=END,FAIL
#SBATCH --mail-user=dongmeic@uoregon.edu
#SBATCH --mem=100GB

echo \"starting job on SDM at \" `date` >> job.log
echo \"loading R module\" >> job.log
module load python3

echo \"preparing for job on SDM \" >> job.log
python3 /gpfs/projects/gavingrp/dongmeic/sdm/python/models_new/logistic_model_iteration.py $i > p-SDM${i}.out
echo \"job on SDM finished \" >> job.log
echo \"job on SDM completed at \" `date` >> job.log"  > SDM${i}.srun
chmod u+x SDM${i}.srun
sbatch SDM${i}.srun&
done