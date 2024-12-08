process renameFastaFiles {
    publishDir "${params.out_dir}", mode: 'copy', overwrite: true
    //debug true

    input:
    val samplesheet
    path path2AssembliesDir
    
    output:
    path "renamedFastaFiles/*.fasta", emit: renamedFastaFiles_ch

    """
    rename_barcodefolder_and_fasta.sh $samplesheet $path2AssembliesDir renamedFastaFiles
    """
}
