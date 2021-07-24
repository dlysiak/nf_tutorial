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
        --genome                       If specified with a genome fasta file, a BLAST database will be generated for the genome 
        --help                         This usage statement.
        """
}
 //Show help message
if (params.help) {
    helpMessage()
    exit 0
}



Channel
    .fromPath(params.query) // create a channel from path params.query
    .splitFasta(by: params.chunkSize, file: true) //splitFasta by chunks of size 1 fasta record and make a file for these chunks in the work porcess folder
    .into {queryFile_ch} // put this into  a channel named queryFile_ch

// Send the output of all these chunks to a new channel and then use a different parameter to collect them before publishing.


// If --genome is supplied on the command line it will run a process
if(params.genome) {
    genomefile_ch = Channel //other method for creating a Channel- define the channel name and then an equal sign like a variable
        .fromPath(params.genome)
        .map { file -> tuple(file.simpleName, file.parent, file) } //nextflow function which will take the input (file) and create a tuple (multivariable output) of file.simpleName(file prefix), file.parent(directory path) and file(full file path)

    process runMakeBlastDB {
        
        input:
        set val(dbName), path(dbDir), file(FILE) from genomefile_ch //from the genomefile_ch we set the (val, path, file) for the tuple (dbName,dbdir,FILE)

        output:
        val dbName into dbName_ch
        path dbDir into dbDir_ch
        //The output we are just passing the dbName and dbDir into new channels that are read into the runBlast process

      
        script:
        """
        makeblastdb -in ${params.genome} -dbtype 'nucl' -out $dbDir/$dbName
        """
    }

} else {
Channel.fromPath(params.dbDir)
    .set { dbDir_ch }
Channel.from(params.dbName)
    .set { dbName_ch }
}
    // Part enclosed into else clause: creates the BLAST databases and override 
    // channels dbDir_ch, dbName_ch if genome parameter has not been passed  

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