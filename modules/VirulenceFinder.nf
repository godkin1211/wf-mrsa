process runVirulenceFinder {
    publishDir "$params.out_dir/virulencefinder", mode: 'copy'
    container 'quay.io/biocontainers/virulencefinder:2.0.4--hdfd78af_1'
    maxForks 1

    input:
    tuple val(sample), path('input.fasta')
    val virulencefinderdb

    output:
    tuple val(sample), path("${sample}_data.json")
    
    script:
    """
    virulencefinder.py -i input.fasta -p $virulencefinderdb
    mv data.json ${sample}_data.json
    """
}
