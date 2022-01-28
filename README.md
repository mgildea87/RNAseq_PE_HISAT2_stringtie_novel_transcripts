# RNAseq_PE_HISAT2_stringtie_novel_transcripts
This readme describes how to execute the snake make workflow for paired-end RNA-seq pre-processing (fastq -> feature counting) utilizing HISAT2 and Stringtie for alignment and gene/transcript
level counting. This version of the pipeline allows stringtie to assemble novel transcript isoforms.

# Description of files required for snakemake:

## Snakefile
This file contains the work flow.
## samples_info.tab 
This file contains a tab deliminated table with:

		1. The names of R1 and R2 of each fastq file as received from the sequencing center. 
		2. Simple sample names
		3. Condition (e.g. diabetic vs non_diabetic)
		4. Replicate #
		5. Sample name is the concatenated final sample_id 
		6. Additional info can be added to this table for downstream use in analysis
## config.yaml
This file contains general configuaration info:

		1. Where to locate the samples_info.tab file
		2. Path to HISAT2 indexed genome
		3. Path to feature file (.GTF)
## cluster_config.yml
Sbatch parameters for each rule in the Snakefile workflow.
## cat_rename.py
		1. Concatenates fastq files for samples that were split over multiple sequencing lanes
		2. Renames the fastq files from the generally verbose ids given by the sequencing center to those supplied in the Samples_info.tab file.
		3. The sample name, condition, and replicate columns are concatenated and form the new sample_id_Rx.fastq.gz files
		4. This script is executed snakemake_init.sh prior to snakemake execution
## snakemake_init.sh
This bash script:

		1. loads the miniconda3/cpu/4.9.2 module
		2. Loads the conda environment (/gpfs/data/fisherlab/conda_envs/RNAseq). You can clone the conda environment using the RNAseq.yml file and modify this bash script to load the env.
		3. Executes snakemake
## RNAseq.yml
This file contains the environment info used by this pipeline. 

## Usage
When starting a new project:

		1. Clone the git repo using 'git clone --recurse-submodules https://github.com/mgildea87/RNAseq_PE_HISAT2_stringtie_novel_transcripts.git'
		2. Run 'git submodule update --remote' to pull any changes that have been made to the cat_rename_init submodule.
		3. Within snakemake_init.sh specifiy the location of the sequencing files from the core. cat_rename.py will concatenate, rename, and copy these to a local directory 'fastq/' 
		4. Update the samples_info.tab file with fastq.gz file names and desired sample, condition, replicate names.
		5. Update config.yaml with path to genome and feature file (if needed. The default right now is mm10)
		6. Update cluster_config.yml with job desired specifications for each Snakemake rule, if desired.
		7. Perform a dry run of snakemake with 'snakemake -n -r' to check for errors and this will tell you the number of jobs required. You will need to load the miniconda3/cpu/4.9.2 module and activate the RNAseq environment first. Dont forget to deactivate the environment and miniconda module before running snakemake_init.sh. This step is not necessary.
		8. Run "bash cat_rename_init/snakemake_init.sh -c 'RNAseq' -w 'RNAseq_PE_HISAT2_stringtie_novel_transcripts'" to execute workflow. The -c and -w parameters tell the workflow which conda env to use and which workflow is being executed.
		9. There are several parameters within stringtie that may need to be altered
			-Read length (def = 65) in the prepDE.py script. This script creates a gene and transcript level count matrix for use in DESeq and requires read length to calculate raw read counts
			-This software is new to me so there are things im likely not thinking of.


