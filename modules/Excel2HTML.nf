process convertExcelToHTML {
    publishDir "$params.out_dir", mode: 'copy'

    input:
    path excel_file

    output:
    path "results.html"

    script:
    """
    excel2html.py -i $excel_file -o results.html
    """
}
