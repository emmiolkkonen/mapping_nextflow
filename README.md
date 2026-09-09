# Nextflow pipeline for mapping and variant calling, modified from a pipeline by Ari Löytynoja

### The pipeline

The pipeline aligns WGS data against a reference genome with BWA-MEM2, realigns around indels with GATK 3, and calls variants with GATK 4.  

Nextflow parameters are defined in params.config, and the environment created in init.sh. Customise the latter based your software installations. 

### Running the pipeline

Data is assumed to be stored in Allas, and is accessed with S3 tools. The reference genome is to be located in the "reference/" directory, alongside with files containing 10 genomic intervals (assumed naming "S[NUMBER].list"). Example of these files is included in the github repository. The pipeline takes in information of fastq files in a .tsv table containing 1) population or Allas subdirectory of your choosing, 2) sample ID, and 3) the Allas path of a fastq file (each fastq file on a row of their own). 

An example script "map_2samples_example.sh" is included in the "scripts/" directory of the repository. In this script, mapping and variantcalling is carried out for 2 individuals in parallel, allocating ~45 GB of memory and 10 CPU for each sample.  

For creating such scripts, scripts/create_slurm_command.sh is provided. 
The script can be run as follows:

```./create_slurm_command.sh map allas_data.tsv SAMPLE1 POPULATION1 SAMPLE2 POPULATION2 PLATFORM```

### Software/tools required for running the pipelineg

The following software is required for running the nextflow pipeline, but deviation from the exact software versions previously used is unlikely to cause serious problems.  

- nextflow (used with v. 22.10.1)
- BWA-MEM2 (used with v. 2.2.1)
- samtools (used with v. 1.16.1)
- GATK3 (used with v. 3.8-1-0)
- GATK4 (used with v. 4.2.5.0)
- java (used with v. 16.0.2)
- Access to S3 tools

