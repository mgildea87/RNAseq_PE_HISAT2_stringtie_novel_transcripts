import pandas as pd
import os

for directory in ['fastqc', 'trim', 'logs', 'logs/slurm_reports', 'logs/trim_reports', 'alignment', 'logs/alignment_reports', 'stringtie', 'stringtie/merged']:
	if not os.path.isdir(directory):
		os.mkdir(directory)

configfile: "config.yaml"
sample_file = config["sample_file"]
GTF = config["GTF"]
sample = pd.read_table(sample_file)['Sample']
replicate = pd.read_table(sample_file)['Replicate']
condition = pd.read_table(sample_file)['Condition']
File_R1 = pd.read_table(sample_file)['File_Name_R1']
File_R2 = pd.read_table(sample_file)['File_Name_R2']
File_names = File_R1.append(File_R2)
genome = config["genome"]

sample_ids = []
for i in range(len(sample)):
	sample_ids.append('%s_%s_%s' % (sample[i], condition[i], replicate[i]))

read = ['_R1', '_R2']


rule all:
	input:
		'stringtie/merged/gene_count_matrix.csv',
		'stringtie/merged/transcript_count_matrix.csv',
		expand('fastqc/{sample}{read}_fastqc.html', sample = sample_ids, read = read)

rule fastqc:
	input: 
		fastq = "fastq/{sample}{read}.fastq.gz"
	output:  
		"fastqc/{sample}{read}_fastqc.html",
		"fastqc/{sample}{read}_fastqc.zip"
	params:
		'fastqc/'
	shell: 
		'fastqc {input.fastq} -o {params}'

rule trim:
	input:
		R1='fastq/{sample}_R1.fastq.gz',
		R2='fastq/{sample}_R2.fastq.gz'
	output:
		R1='trim/{sample}_trimmed_R1.fastq.gz',
		R2='trim/{sample}_trimmed_R2.fastq.gz',
		html='logs/trim_reports/{sample}.html',
		json='logs/trim_reports/{sample}.json'
	threads: 4
	log:
		'logs/trim_reports/{sample}.log'
	params:
		'--detect_adapter_for_pe'
	shell:
		'fastp -w {threads} {params} -i {input.R1} -I {input.R2} -o {output.R1} -O {output.R2} --html {output.html} --json {output.json} 2> {log}'

rule align:
	input:
		R1='trim/{sample}_trimmed_R1.fastq.gz',
		R2='trim/{sample}_trimmed_R2.fastq.gz'
	output:
		bam = 'alignment/{sample}.bam'
	threads: 10
	log:
		'logs/alignment_reports/{sample}.log'
	params:
		'--phred33 --rna-strandness RF --dta'
	shell:
		'hisat2 {params} -p {threads} -x %s -1 {input.R1} -2 {input.R2} 2> {log} | samtools sort - -o alignment/{wildcards.sample}.bam -@ {threads}' % (genome)

rule count:
	input:
		bam = 'alignment/{sample}.bam'
	output:
		trans_counts = 'stringtie/{sample}.gtf',
		gene_counts = 'stringtie/{sample}.tab'
	threads: 10
	params:
		'--rf --conservative'
	shell:
		'stringtie -p {threads} {params} -G %s -o {output.trans_counts} -l {wildcards.sample} -A {output.gene_counts} {input.bam}' % (GTF)

rule combine_gtf:
	input:
		trans_counts = expand('stringtie/{sample}.gtf' , sample = sample_ids)
	output:
		gtf_list = 'stringtie/merged.txt'
	shell:
		'ls stringtie/*.gtf > {output.gtf_list}'

rule merge:
	input:
		gtf_list = 'stringtie/merged.txt'
	output:
		merged_gtf = 'stringtie/merged.gtf'
	threads: 10
	shell:
		'stringtie --merge -p {threads} -G %s -o {output.merged_gtf} {input.gtf_list}' % (GTF)

rule count_2:
	input:
		bam = 'alignment/{sample}.bam',
		merged_gtf = 'stringtie/merged.gtf'
	output:
		trans_counts = 'stringtie/merged/{sample}/{sample}_merged.gtf'
	threads: 10
	params:
		'--rf -e -B'
	shell:
		'stringtie -p {threads} {params} -G  {input.merged_gtf} -o {output.trans_counts} {input.bam}'

rule deseq_prep:
	input:
		expand('stringtie/merged/{sample}/{sample}_merged.gtf', sample = sample_ids),
		str_dir = 'stringtie/merged/' 
	output:
		gene_counts = 'stringtie/merged/gene_count_matrix.csv',
		transcript_counts = 'stringtie/merged/transcript_count_matrix.csv'
	shell:
		'prepDE.py -l 65 -i {input.str_dir} -g {output.gene_counts} -t {output.transcript_counts}'