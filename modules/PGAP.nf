process runPGAP {
    publishDir "${params.out_dir}/PGAP", mode: 'copy'
    maxForks 1
    cpus 10

    input:
    tuple val(sample), path('input.fasta')
    val species

    output:
    path "${sample}_pgap_output", emit: pgap_output_dir
    tuple val(sample), path("${sample}_pgap_output/${sample}.faa"), emit: sampleid_and_aa_seqs

    script:
    """
    cp input.fasta tmp.fasta
    pgap.py -n --no-self-update --no-internet -c ${task.cpus} -m 50g -g tmp.fasta -s "$species" --prefix $sample -o ${sample}_pgap_output
    rm -f tmp.fasta
    """
}
