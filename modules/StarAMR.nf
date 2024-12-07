process runStarAMR {
    publishDir "${params.out_dir}/staramr", mode: 'copy'
    maxForks 1

    input:
    tuple val(sample), path('input.fasta')
    val species

    output:
    tuple val(sample), path("${sample}_results.xlsx")

    script:
    """
    source /home/godkin/miniconda3/bin/activate staramr
    species=\$(echo $species | tr '[:upper:]' '[:lower:]' | sed 's/ /_/')
    mv input.fasta ${sample}.fasta
    staramr search --pointfinder-organism \$species \
                   --output-summary ${sample}_summary.tsv \
                   --output-detailed-summary ${sample}_detailed_summary.tsv \
                   --output-resfinder ${sample}_resfinder.tsv \
                   --output-pointfinder ${sample}_pointfinder.tsv \
                   --output-plasmidfinder ${sample}_plasmidfinder.tsv \
                   --output-settings ${sample}_settings.txt \
                   --output-excel ${sample}_results.xlsx \
                   --output-hits-dir ${sample}_hits \
                   --output-mlst ${sample}_mlst.tsv \
                   ${sample}.fasta
    """
}