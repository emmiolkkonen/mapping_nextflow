#!/bin/bash

mode=$1
file=$2
smp1=$3
out1=$4
smp2=$5
out2=$6
platform=$7

mem="45G"
ntask=1
two=false
extrapar="" # --clean_files false"
s3path="s3://output_bucket"

if [[ $# -eq 7 ]]; then
  mem="90G"
  ntask=2
  two=true
fi

# Find population for sample_1, exit if not found
pop1=$(grep -w $smp1 meta/$file|cut -f1|head -1)

if [ -z "$pop1" ]; then
  echo "$smp1 not found"
  exit 0
fi

# If mapping, find fastq paths for sample_1, exit if not found
if [[ "$mode" == "map" ]]; then
  name=map_${smp1}
  path1=$(grep -w $smp1 meta/$file|cut -f3|xargs dirname|sort|uniq|tr '\n' ,|sed 's/,$//')
  if [ -z "$path1" ]; then
    echo "$smp1 path not found"
    exit 0
  fi
fi

# If calling, find bam file for sample_1, exit if not found
if [[ "$mode" == "call" ]]; then
  name=call_${smp1}
  bam1=$PWD/output/$platform/$pop1/$smp1/${smp1}_markdup.bam
  bai1=$PWD/output/$platform/$pop1/$smp1/${smp1}_markdup.bam.bai
  if [ ! -e "$bam1" ]; then
    echo "$smp1 bam not found"
    exit 0
  fi
fi

if "$two"; then
  # Find population for sample_2, exit if not found
  pop2=$(grep -w $smp2 meta/$file|cut -f1|head -1)
  if [ -z "$pop2" ]; then
    echo "$smp2 not found"
    exit 0
  fi

  # If mapping, find fastq paths for sample_2, exit if not found
  if [[ "$mode" == "map" ]]; then
    name=map_${smp1}_${smp2}
    path2=$(grep -w $smp2 meta/$file|cut -f3|xargs dirname|sort|uniq|tr '\n' ,|sed 's/,$//')
    if [ -z "$path2" ]; then
      echo "$smp2 path not found"
      exit 0
    fi
  fi

  # If calling, find bam file for sample_1, exit if not found
  if [[ "$mode" == "call" ]]; then
    name=call_${smp1}_${smp2}
    bam2=$PWD/output/$platform/$pop2/$smp2/${smp2}_markdup.bam
    bai2=$PWD/output/$platform/$pop2/$smp2/${smp2}_markdup.bam.bai
    if [ ! -e "$bam1" ]; then
      echo "$smp2 bam not found"
      exit 0
    fi
  fi
fi

echo "#!/bin/bash

#SBATCH --time=72:00:00
#SBATCH --nodes=1
#SBATCH --ntasks=$ntask
#SBATCH --cpus-per-task=10
#SBATCH --mem=$mem
#SBATCH --partition=small
#SBATCH --account=project_NUMBER
#SBATCH --output=slurm/${name}-%j.out

export TMPDIR=$PWD
unset XDG_RUNTIME_DIR

source init.sh"

if [[ "$mode" == "map" ]]; then
echo -e "

mkdir -p ${name}; cd ${name}

srun --ntasks=1 --nodes=1 --exclusive --cpus-per-task=10 --mem=44GB nextflow run ../process_seal_samples.nf --sample_id ${smp1} --population ${pop1} --inpath ${path1} --outpath $s3path/${platform}/${out1}/${smp1} --platform ${platform} --split_call --all $extrapar &\n"

if "$two"; then
  echo "srun --ntasks=1 --nodes=1 --exclusive --cpus-per-task=10 --mem=44GB nextflow run ../process_seal_samples.nf --sample_id ${smp2} --population ${pop2} --inpath ${path2} --outpath $s3path/${platform}/${out2}/${smp2} --platform ${platform} --split_call --all $extrapar &"
fi

echo -e "\nwait"
fi

if [[ "$mode" == "call" ]]; then
echo -e "

mkdir -p ${name}; cd ${name}

srun --ntasks=1 --nodes=1 --exclusive --cpus-per-task=10 --mem=44GB nextflow run ../process_seal_samples.nf --sample_id ${smp1} --population ${pop1} --alignedbam ${bam1} --alignedbai ${bai1} --outpath $s3path/${platform}/${out1}/${smp1} --platform ${platform} --split_call --call_only &\n"

if "$two"; then

  echo "srun --ntasks=1 --nodes=1 --exclusive --cpus-per-task=10 --mem=44GB nextflow run ../process_seal_samples.nf --sample_id ${smp2} --population ${pop2} --alignedbam ${bam2} --alignedbai ${bai2} --outpath $s3path/${platform}/${out2}/${smp2} --platform ${platform} --split_call --call_only &"
fi

echo -e "\nwait"
fi
