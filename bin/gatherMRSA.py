#!/usr/bin/python3
import pandas as pd
import argparse
import json

def parseVirulenceFinderOutput(virulencefinder_output):
    with open(virulencefinder_output, 'r') as file:
        data = json.load(file)
    results_data = data['virulencefinder']['results']
    species_hits = []

    # Iterate through each species and its data
    for species, content in results_data.items():
        # Check if the species has any hits
        if isinstance(content, dict) and any("No hit found" not in str(v) for v in content.values()):
            # For each hit within the species, extract detailed info
            for feature, details in content.items():
                if isinstance(details, dict):  # Ensuring there are details to extract
                    for substance, substance_info in details.items():
                        substance_info['Species'] = species
                        substance_info['Feature'] = feature
                        species_hits.append(substance_info)

    # Convert list of dicts to DataFrame
    species_df = pd.DataFrame(species_hits)

    # Sort the DataFrame by the species names
    species_df_sorted = species_df.sort_values(by='Species')
    return species_df_sorted


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description="This is the tool to gather all the results from MRSA nextflow pipeline into single excel sheet")
    parser.add_argument('-s', '--sample', required=True, help="input Sample name")
    parser.add_argument('-t', '--spatyper', required=True, help="input your spaTyper result file (txt)")
    parser.add_argument('-d', '--spatyperdb', required=True, help="input your spaTyper database file (txt)")
    parser.add_argument('-m', '--sccmec', required=True, help="input your sccmec tsv file")
    parser.add_argument('-a', '--staramr', required=True, help ='input your excel results from staramr')
    parser.add_argument('-v', '--virulencefinder', required=True, help="input your virulencefinder output json file")
    parser.add_argument('-o', '--output', required=True, help="define your output name without extension")
    parser.add_argument('-c', '--card', required=True, help ='input your CARD result from abricate')

    # Input parameters
    args = parser.parse_args()
    sample = args.sample
    spa = args.spatyper
    sccmec = args.sccmec
    staramr = args.staramr
    virulencefinder = args.virulencefinder
    output_data = args.output + '.xlsx'    
    spdb = args.spatyperdb
    card_path = args.card

    # Parser VirulenceFinder output json to dataframe wit hit data
    dfVirulenceFinder = parseVirulenceFinderOutput(virulencefinder)

    # Sccmec part
    dfSccmec = pd.read_csv(sccmec, sep = '\t', header = 0)    

    # SpaTyper part and link to annotation database
    dfSpa = pd.read_csv(spa, sep = '\t', header = 0)
    dbSp = pd.read_csv(spdb, sep = '\t', header = 0)
    dfSpaTyper = pd.merge(dfSpa, dbSp, left_on="Type", right_on="Spa-type", how="inner")
    dfSpaTyper = dfSpaTyper.drop('Type', axis=1)

    # CARD
    dfCARD = pd.read_csv(card_path, sep = '\t', header = 0)
    dfCARD = dfCARD.rename(columns={'#FILE':'FILE'})

    # Staramr as excel baseline sheet file
    sheets = pd.read_excel(staramr, sheet_name=None)
    
    # Remove Settings sheet and mark "staramr" label to the name of "summary" sheet
    sheet_to_remove = 'Settings'
    if sheet_to_remove in sheets:
        sheets.pop(sheet_to_remove)
    old_sheet_name = 'Summary'
    new_sheet_name = 'Staramr_Summary'
    if old_sheet_name in sheets:
        sheets[new_sheet_name] = sheets.pop(old_sheet_name)
    old_sheet_name = 'Detailed_Summary'
    new_sheet_name = 'Staramr_Detail'
    if old_sheet_name in sheets:
        sheets[new_sheet_name] = sheets.pop(old_sheet_name)

    # Gather all the sheet into excel file
    sheets['VirulenceFinder'] = dfVirulenceFinder
    sheets['Sccmec'] = dfSccmec
    sheets['SpaTyper'] = dfSpaTyper
    sheets['CARD'] = dfCARD
    with pd.ExcelWriter(output_data) as writer:
        for sheet_name, df in sheets.items():
            output4eachsheet = sheet_name + '_result.csv'
            df.to_csv(output4eachsheet, index=False)
            df.to_excel(writer, sheet_name=sheet_name, index=False)
