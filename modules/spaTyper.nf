
process runSpaTyper {
    publishDir "$params.out_dir/spatyper", mode: 'copy'
    container 'quay.io/biocontainers/spatyper:0.3.3--pyhdfd78af_3'
    maxForks 1

    input:
    tuple val(sample), path('input.fasta')
    val spa_type_file
    val spa_repeat_file

    output:
    tuple val(sample), path("${sample}_spatyper_results.txt")

    script:
    """
    spaTyper -r ${spa_repeat_file} -o ${spa_type_file} -f input.fasta --output "${sample}_spatyper_results.txt"
    """
}
