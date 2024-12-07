process runSccmec {
    publishDir "$params.out_dir", mode: 'copy'
    container 'quay.io/biocontainers/sccmec:1.0.0--hdfd78af_0'
    maxForks 1

    input:
    tuple val(sample), path('input.fasta')

    output:
    tuple val(sample), path("sccmec/${sample}.tsv")

    script:
    """
    sccmec --input input.fasta --outdir sccmec --prefix $sample
    """
}
