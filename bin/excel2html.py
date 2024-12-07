import pandas as pd
import sys
from html import escape

def create_html_table(df, table_name):
    """Create HTML table from dataframe"""
    html = f'<div class="table-container" id="{table_name}" style="display: none;">\n'
    html += f'<h2>{table_name}</h2>\n'
    html += '<table border="1">\n'
    
    # Add header row
    html += '<tr>\n'
    for col in df.columns:
        html += f'<th>{escape(str(col))}</th>\n'
    html += '</tr>\n'
    
    # Add data rows
    for _, row in df.iterrows():
        html += '<tr>\n'
        for val in row:
            html += f'<td>{escape(str(val))}</td>\n'
        html += '</tr>\n'
    
    html += '</table>\n</div>\n'
    return html

def main():
    if len(sys.argv) != 4:
        print("Usage: python excel2html.py <input_csv> <table1_name> <table2_name>")
        sys.exit(1)
        
    input_file = sys.argv[1]
    table1_name = sys.argv[2]
    table2_name = sys.argv[3]
    
    # Read CSV file
    df = pd.read_csv(input_file)
    
    # Split into two tables
    table1 = df.iloc[:, :9]  # First 9 columns
    table2 = df.iloc[:, 9:29]  # Next 20 columns
    
    # Create HTML content
    html_content = """
    <!DOCTYPE html>
    <html>
    <head>
        <title>CSV Data Tables</title>
        <style>
            .table-container { margin: 20px; }
            table { border-collapse: collapse; width: 100%; }
            th, td { padding: 8px; text-align: left; }
            .button-container { margin: 20px; }
            button { padding: 10px 20px; margin-right: 10px; }
        </style>
        <script>
            function showTable(tableName) {
                // Hide all tables
                document.querySelectorAll('.table-container').forEach(table => {
                    table.style.display = 'none';
                });
                // Show selected table
                document.getElementById(tableName).style.display = 'block';
            }
        </script>
    </head>
    <body>
        <div class="button-container">
            <button onclick="showTable('""" + table1_name + """')">""" + table1_name + """</button>
            <button onclick="showTable('""" + table2_name + """')">""" + table2_name + """</button>
        </div>
    """
    
    # Add tables
    html_content += create_html_table(table1, table1_name)
    html_content += create_html_table(table2, table2_name)
    
    # Close HTML
    html_content += """
    <script>
        // Show first table by default
        document.getElementById('""" + table1_name + """').style.display = 'block';
    </script>
    </body>
    </html>
    """
    
    # Write to output file
    output_file = 'output.html'
    with open(output_file, 'w') as f:
        f.write(html_content)
    
    print(f"HTML file generated: {output_file}")

if __name__ == "__main__":
    main()
