#!/bin/bash
#BSUB -oo /genomes/analysis/research_and_dev/ed_working/readDensityPipeline/seqSumPipeDir/output_%J.out
#BSUB -eo /genomes/analysis/research_and_dev/ed_working/readDensityPipeline/seqSumPipeDir/output_%J.err
#BSUB -J readLenDensityPipe
#BSUB -q pipeline
#BSUB -R "select[mem>4000] rusage[mem=4000]"
#BSUB -P bio
#BSUB -M 3000
#BSUB -n 8
export NXF_CLUSTER_SEED=$(shuf -i 0-16777216 -n 1)
#inFile=$1
/genomes/analysis/research_and_dev/ed_working/software/nextflow run readLenDensity.nf -c nextflow.config --in /pgen_ext_restricted_data/sanger/cohort_hemonc/
sed '1!{/^"Bin"/d}' /genomes/analysis/research_and_dev/ed_working/readDensityPipeline/seqSumPipeDir/gbsPerHour.txt >> /genomes/analysis/research_and_dev/ed_working/readDensityPipeline/seqSumPipeDir/gbsPerHour_sed.txt
xvfb-run -a R -e "rmarkdown::render('./gbsPerHour.Rmd', output_file='gbsPerHour.html', params = list(gbsFile = 'gbsPerHour_sed.txt'))"
rm cut_sequencing_summary*.txt
rm gbsPerHour.txt
mkdir htmlReports
mv *.html htmlReports
