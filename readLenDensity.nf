seqSums = Channel.fromPath ( params.in + "*/*/sequencing_summary_*.txt", type:'file')
//summaryFile = Channel.fromPath ( "./*_cut.txt", type:'file')

//Find and copy sequencing summary files
process findCopy {
	memory { 2.GB * task.attempt }
	clusterOptions = '-P bio -n 2'
        publishDir "/genomes/analysis/research_and_dev/ed_working/readDensityPipeline/seqSumPipeDir/", mode: 'copy', overwrite: 'false'
        maxForks 30
        errorStrategy 'retry'
        maxRetries 5

	input:
	val seqSum from seqSums

	output:
	file '**' optional true into cpSeqs
	val flowcellStrFinal into flowcell

	script:
	flowcellStrFinal = seqSum.getParent().getName()
	"""
	if [[ "${seqSum}" != *"combined"* ]]; then
	  cp ${seqSum} . 
	fi
	"""
}

process cutSeqs {
        memory { 2.GB * task.attempt }
	clusterOptions = '-P bio -n 2'
        publishDir "/genomes/analysis/research_and_dev/ed_working/readDensityPipeline/seqSumPipeDir/", mode: 'copy', overwrite: 'false'
        maxForks 30
        errorStrategy 'retry'
        maxRetries 5

	input:
	file cutSeq from cpSeqs
	val strflowcell from flowcell

	output:
	file '**' optional true into summaryFile

	script:
	"""
	if [[ \$(wc -l <${cutSeq}) -ge 10 ]]; then
            sed -i '1 s|.*|&\\tFlowcell ID|' ${cutSeq}
            sed -i '1p; \$n; s|\$|\\t${strflowcell}|' ${cutSeq}
            sed -i 1d ${cutSeq}
            sed '\${s/\$/\\t${strflowcell}/}' ${cutSeq} > cut_${cutSeq}
        fi
	"""
}	

//Generate read len dist for each sequencing summary
process readLenGen {
	memory { 30.GB * task.attempt }
	clusterOptions = '-P bio -n 2'
	publishDir "/genomes/analysis/research_and_dev/ed_working/readDensityPipeline/seqSumPipeDir/", mode: 'copy', overwrite: 'false'
	maxForks 15
	errorStrategy 'retry'
        maxRetries 5

	input:
	file sumFile from summaryFile

	script:
	fileName = sumFile.toString()
	fileName = fileName.replace(".txt","")
	"""
	xvfb-run -a R -e "rmarkdown::render('${PWD}/readDensityMarkdown.Rmd', output_file='${PWD}/${fileName}.html', params = list(seqFile = '${sumFile}'))"
	for filename in cut*; do 
    	  [ -f "\$filename" ] || continue
    	  mv "\$filename" "\${filename//cut_sequencing_summary_/}"
	done
	"""
}
