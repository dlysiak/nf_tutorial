#!/usr/bin/env nextflow

blastdb="myBlastDatabase" // set a variable inside the nextflow script
params.query="file.fasta" // set a pipeline parameter
// to make a variable a pipeline parameter just prepend the variable with params.



println "I will BLAST $params.query against $blastdb" // a simple print statement
// that uses both a nextflow variable and a pipeline parameter
