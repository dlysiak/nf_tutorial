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

// If --genome is supplied on the command line it will run a process
if(params.genome) {
    println "It worked"
    exit 0
}

Channel
    .fromPath(params.query) // create a channel from path params.query
    .splitFasta(by: params.chunkSize, file: true) //splitFasta by chunks of size 1 fasta record and make a file for these chunks in the work porcess folder
    .into {queryFile_ch} // put this into  a channel named queryFile_ch
    
// Send the output of all these chunks to a new channel and then use a different parameter to collect them before publishing.

process runBlast {

    label 'blast'

    input:
    path queryFile from queryFile_ch

    output:
    publishDir "${params.outdir}/blastout"
    path(params.outFileName) into blast_output_ch
    

    script:
    """
    $params.app -num_threads $params.threads -db $params.dbDir/$params.dbName -query $queryFile -outfmt $params.outfmt $params.options -out $params.outFileName
    """

}

blast_output_ch
    .collectFile(name: 'blast_output_combined.txt', storeDir: params.outdir)