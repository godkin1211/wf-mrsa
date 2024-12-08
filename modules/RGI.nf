process runRGI {
    publishDir "${params.out_dir}/CARD", mode: 'copy'
    container 'quay.io/biocontainers/rgi:6.0.3--pyha8f3691_0'
    maxForks 2

    input:
    tuple val(sample), path('input.fasta')
    path(card_db_dir)

    output:
    tuple val(sample), path("${sample}_card_output.txt")

    script:

    if (params.runPGAP == true) {
        """
        rgi main -i input.fasta -o ${sample}_card_output -t protein -a DIAMOND -n 7 --include_loose --local
        """
    } else {
        """
        rgi main -i input.fasta -o ${sample}_card_output -t contig -a DIAMOND -n 7 --include_loose --local
        """
    }
}