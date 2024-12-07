process mergrResultsWithTemplate {
    publishDir "${params.out_dir}/", mode: 'copy'
    debug true

    input:
    path summary_file
    path template_file

    output:
    path "final_results.xlsx"

    """
    #!/usr/bin/env python3
    import pandas as pd
    import openpyxl
    template_path = "${template_file}"
    summary_file = "${summary_file}"
    wb = openpyxl.load_workbook(template_path)
    ws = wb.active
    last_row = ws.max_row
    summaries = pd.read_csv(summary_file, header = None, index_col = None)
    for i, row in enumerate(summaries.values, 1):
        for j, value in enumerate(row, 1):
            ws.cell(row = last_row + i, column = j, value = value)

    wb.save("final_results.xlsx")
    """
}