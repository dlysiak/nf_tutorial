#!/usr/bin/env nextflow

//blastdb="myBlastDatabase" // set a variable inside the nextflow script
//params.query="file.fasta" // set a pipeline parameter
// to make a variable a pipeline parameter just prepend the variable with params.


//println "I will BLAST $params.query against $blastdb" // a simple print statement
println "\nI want to BLAST $params.query to $params.dbDir/$params.dbName using $params.threads CPUs and output it to $params.outdir\n"

// that uses both a nextflow variable and a pipeline parameter

def helpMessage() {
    log.info """
        Usage: 
        The typical command for running this pipeline is as follows:
        nextflow run main.df --query QUERY.fasta --dbDir "blastDatabaseDirectory" --dbName "blastPrefixName"
        
        Mandatory arguments:
        --query                       Query fasta file of sequences you wish to BLAST 
        --dbDir                       BLAST database directory (full path required)
        --dbName                      Prefix name of the BLAST database


        Optional arguments:

        --outdir                       Output directory to place final BLAST output
        --outfmt                       Output format ['6']
        --options                      Additional options for BLAST command [-evalue 1e-3]
        --outFileName                  Prefix name for BLAST output [input.blastout]
        --threads                      Number of CPUs to use during blast job [16]
        --chunkSize                    Number of fasta records to use when splitting the query fasta file
        --app                          BLAST program to use [blastn;blastp,tblastn,blastx]
        --help                         This usage statement.
        """
}
 //Show help message
if (params.help) {
    helpMessage()
    exit 0
}

Channel
    .fromPath(params.query)
    .into {queryFile_ch} // create a channel from a file path and set the channel name into queryFile_ch
    

process runBlast {

    input:
    path(queryFile) from queryFile_ch

    script:
    """
    $params.app -num_threads $params.threads -db $params.dbDir/$params.dbName -query $queryFile -outfmt $params.outfmt $params.options -out $params.outFileName
    """

}