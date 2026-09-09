#!/bin/bash

#SBATCH --time=72:00:00
#SBATCH --nodes=1
#SBATCH --ntasks=2
#SBATCH --cpus-per-task=10
#SBATCH --mem=95G
#SBATCH --partition=small
#SBATCH --account=project_NUMBER
#SBATCH --output=slurm/map_aviti_SAMPLE1_SAMPLE2-%j.out

export TMPDIR=/path/
unset XDG_RUNTIME_DIR

source init.sh

mkdir -p map_aviti_SAMPLE1_SAMPLE2; cd map_aviti_SAMPLE1_SAMPLE2

srun --ntasks=1 --nodes=1 --exclusive --cpus-per-task=10 --mem=44GB nextflow run ../process_seal_samples.nf --sample_id SAMPLE1 --population POPULATION --inpath s3://inputpath/aviti/POPULATION/SAMPLE1 --outpath s3://outputpath/aviti/POPULATION/SAMPLE1 --platform aviti --split_call --all  &

srun --ntasks=1 --nodes=1 --exclusive --cpus-per-task=10 --mem=44GB nextflow run ../process_seal_samples.nf --sample_id SAMPLE2 --population POPULATION --inpath s3://inputpath/aviti/POPULATION/SAMPLE2 --outpath s3://outputpath/aviti/POPULATION/SAMPLE2 --platform aviti --split_call --all  &

wait
