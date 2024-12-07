process parseGatheredResults {
    publishDir "${params.out_dir}/Summaries", mode:'copy'
    maxForks 1
    //debug true

    input:
    path excelfile
    val druglist_file
    val spaccdb_file
    val samplesheet

    output:
    stdout

    script:
    """
    excelfilename=$excelfile
    mirlid=\$( echo \${excelfilename##*/} | cut -d'.' -f 1)
    mlstdb_schema=\$(in2csv --sheet MLST_Summary $excelfile | sed '1d' | cut -d ',' -f 2)
    mlstdb_file="${baseDir}/databases/mlst_db/\${mlstdb_schema}/\${mlstdb_schema}.tsv"
    generateGlobReport.py -i $excelfile -f $samplesheet -s \$mirlid -d ${druglist_file} -m \${mlstdb_file} -c ${spaccdb_file} -o tmp.csv
    cat tmp.csv && rm -f tmp.csv
    """
}