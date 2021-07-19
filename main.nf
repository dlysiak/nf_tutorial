#!/usr/bin/env nextflow

//blastdb="myBlastDatabase" // set a variable inside the nextflow script
//params.query="file.fasta" // set a pipeline parameter
// to make a variable a pipeline parameter just prepend the variable with params.


//println "I will BLAST $params.query against $blastdb" // a simple print statement
println "\nI want to BLAST $params.query to $params.dbDir/$params.dbName using $params.threads CPUs and output it to $params.outdir\n"

// that uses both a nextflow variable and a pipeline parameter

process runBlast {

    script:
    """
    $params.app -num_threads $params.threads -db $params.dbDir/$params.dbName -query $params.query -outfmt $params.outfmt $params.options -out $params.outFileName
    """

}