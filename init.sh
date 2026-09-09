#!/usr/bin/bash

#PROJAPPL=/installation_path/

module load nextflow/22.10.1
module load bwa-mem2/2.2.1
module load samtools/1.16.1
module load allas/0.0.2

export APPTAINER_TMPDIR=$PWD
export APPTAINER_SCRATCHDIR=$PWD
export SINGULARITY_TMPDIR=$PWD
export SINGULARITY_SCRATCHDIR=$PWD

unset XDG_RUNTIME_DIR

#For GATK 3 and GATK 4
PATH=/installation_path/:$PATH
