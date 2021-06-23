import os, subprocess, sys
import pandas as pd

#Combine fastq files from multiple lanes
#Run script inside fastq directory
def concat():
	cur_dir = 'fastq/'
	files = os.listdir(cur_dir)
	samples = {}
	for file in files:
		file = 'fastq/%s' % (file)
		if 'L00' in file:
			if os.path.isfile(file) and file.endswith('fastq.gz'):
					a = file.split('L00')
					f = '%s%s' % (a[0], a[1][2:4])
					if f not in samples:
						samples[f] = [file]
					else:
						samples[f].append(file)
	for sample in samples:
		com = samples[sample]
		com.sort()
		com.insert(0, 'cat')
		print('Concatenating: %s' % (com[1:]))
		with open('%s_001.fastq.gz' % (sample), 'w') as R1:
			subprocess.run(com, stdout=R1)
			com[0] = 'rm'
			subprocess.run(com)

#rename samples based on sample ids in samples_info.tab
def rename():
	sample_file = "samples_info.tab"
	sample = pd.read_table(sample_file)['Sample']
	replicate = pd.read_table(sample_file)['Replicate']
	condition = pd.read_table(sample_file)['Condition']
	File_R1 = pd.read_table(sample_file)['File_Name_R1']
	File_R2 = pd.read_table(sample_file)['File_Name_R2']

	for i in range(len(File_R1)):
		if os.path.exists('fastq/%s' % (File_R1[i])):
			os.system('mv fastq/%s fastq/%s_%s_%s_R1.fastq.gz' % (File_R1[i],sample[i],condition[i],replicate[i]))
		elif os.path.exists('fastq/%s_%s_%s_R1.fastq.gz' % (sample[i],condition[i],replicate[i])) == False:
			print('fastq/%s and fastq/%s_%s_%s_R1.fastq.gz do not exist!' % (File_R1[i], sample[i],condition[i],replicate[i]))
			sys.exit(1)

	for i in range(len(File_R2)):
		if os.path.exists('fastq/%s' % (File_R2[i])):
			os.system('mv fastq/%s fastq/%s_%s_%s_R2.fastq.gz' % (File_R2[i],sample[i],condition[i],replicate[i]))
		elif os.path.exists('fastq/%s_%s_%s_R2.fastq.gz' % (sample[i],condition[i],replicate[i])) == False:
			print('fastq/%s and fastq/%s_%s_%s_R2.fastq.gz do not exist!' % (File_R2[i], sample[i],condition[i],replicate[i]))
			sys.exit(1)

concat()
rename()