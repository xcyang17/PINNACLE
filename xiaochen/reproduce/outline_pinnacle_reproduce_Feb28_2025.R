
# interactive session
(/home/yang1641/.conda/envs/cent7/2024.02-py311/pinnacle) (r-reticulate) bash-4.2$ squeue -u yang1641                                  
JOBID        USER      ACCOUNT      NAME             NODES   CPUS  TIME_LIMIT ST TIME                                                  
45181816     yang1641  gpu          OnDemand/Noteboo     1     10  1-00:00:00  R 12:44:10


### Feb 28, 2025, 10:34: 45187196
cd /scratch/bell/yang1641/exome/logs
sbatch  -N 1 --mem 100g -t 1-00:00:00 --mail-type=end,fail --mail-user=yang1641@purdue.edu -A gpu /home/yang1641/PINNACLE/xiaochen/reproduce/run_pinnacle_Feb28_2025.sh
### 10:41: 45187258; try again 45187273;
sbatch -N 1 --mem 100g -t 1-00:00:00 --mail-type=end,fail --mail-user=yang1641@purdue.edu -A multigpu /home/yang1641/PINNACLE/xiaochen/reproduce/run_pinnacle_Feb28_2025.sh
#SBATCH -N 1
#SBATCH --mem 100g
#SBATCH -t 1-00:00:00
#SBATCH --mail-type=end,fail
#SBATCH --mail-user=yang1641@purdue.edu