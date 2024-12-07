process runRGI {
    publishDir "${params.out_dir}/CARD", mode: 'copy'
    container 'quay.io/biocontainers/rgi:6.0.3--pyha8f3691_0'
    //debug true
    maxForks 2

    input:
    tuple val(sample), path('input.fasta')
    path(card_db_dir)
    //val card_json
    //val card_annotation
    //val card_annotation_all_models
    //val wildcard_annotation
    //val wildcard_annotation_all_models
    //val wildcard_index
    //val wildcard_version
    //val amr_kmers
    //val kmer_database
    //val kmer_size

    output:
    tuple val(sample), path("${sample}_card_output.txt")

    script:
    """
    rgi main -i input.fasta -o ${sample}_card_output -t contig -a DIAMOND -n 7 -g PRODIGAL --include_loose --local --clean
    """
}


/*
#rgi load --card_json ${card_json} --local \\
#         --card_annotation ${card_annotation} \\
#         --card_annotation_all_models ${card_annotation_all_models} \\
#         --wildcard_annotation ${wildcard_annotation} \\
#         --wildcard_annotation_all_models ${wildcard_annotation_all_models} \\
#         --wildcard_index ${wildcard_index} \\
#         --wildcard_version ${wildcard_version} \\
#         --amr_kmers ${amr_kmers} \\
#         --kmer_database ${kmer_database} \\
#         --kmer_size ${kmer_size} && \\
#rgi main -i input.fasta -o ${sample}_card_output -t protein -a DIAMOND -n 10 --local
*/