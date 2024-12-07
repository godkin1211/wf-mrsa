#!/usr/bin/env python3
import pandas as pd
import argparse
from collections import defaultdict
import numpy as np
import os
import re
import openpyxl
import glob
import math
import json

def match_mrsa_clone_type(sccmec, spa_cc, lookup_df):
    matched_row = lookup_df[(lookup_df['SCCmec'] == sccmec) & (lookup_df['spa_CC'] == spa_cc)]
    if not matched_row.empty:
        return matched_row['MRSA_clone_type'].values[0]
    return 'other'

def process_mrsa_json(json_data, classification_df, outputdir):
    """
    將 JSON 資料解析並分類到對應的 treatment.csv 中，文件會保存到 outputdir/MRSAdrugs 資料夾下。
    
    :param json_data: 單個樣本的 JSON 資料（包含 MIRL ID 和基因對應值）
    :param classification_df: 包含基因和 Treatment 對應的分類 DataFrame
    :param outputdir: 輸出 CSV 的資料夾路徑
    """
    # 建立 output 資料夾（如果尚未建立）
    output_folder = os.path.join(outputdir, "MRSAdrugs")
    os.makedirs(output_folder, exist_ok=True)  # 確保 MRSAdrugs 目錄存在
    classification_df = classification_df[classification_df['Outputable']==1]

    # 從 JSON 資料中提取 MIRL ID
    mirl_id = json_data["MIRL ID"]

    # 遍歷所有 Treatment
    for treatment in classification_df["Treatment"].unique():
        # 根據 treatment 過濾基因
        genes_in_treatment = classification_df[classification_df["Treatment"] == treatment]["Gene"]

        # 建立一個 DataFrame，記錄 MIRL ID 和該 treatment 下的基因
        treatment_df = pd.DataFrame(columns=["MIRL ID", "DrugID"] + list(genes_in_treatment))
        treatment_df["MIRL ID"] = [mirl_id]  # 設置 MIRL ID
        treatment_df["DrugID"] = treatment   # 設置 DrugID

        # 對於每個基因，從 JSON 中獲取該基因的值（如果不存在則默認為 0）
        for gene in genes_in_treatment:
            treatment_df[gene] = json_data.get(gene, 0)

        # 處理檔名：將檔名中的 "/" 替換為 "_"
        safe_treatment = treatment.replace("/", "_").replace(" ", "_")

        # 設定 CSV 檔案名稱
        csv_filename = os.path.join(output_folder, f"{safe_treatment}.csv")

        # 檢查 CSV 檔案是否存在，存在則追加資料，不存在則創建文件
        if not os.path.exists(csv_filename):
            # 文件不存在，創建並寫入標題
            treatment_df.to_csv(csv_filename, mode='w', index=False)
        else:
            # 文件已經存在，追加新資料（不重寫標題）
            treatment_df.to_csv(csv_filename, mode='a', header=False, index=False)

        print(f"Data for {mirl_id} added to {csv_filename}")


def transferReport(inputfile, experimentid, barcodeid, mirl):
    global antibiotics_dict
    global mrsa_df
    global drugsdb
    global dbspa
    global mlstdb
    #global outputpath

    sheets = pd.read_excel(inputfile, sheet_name=None)

    # information
    experiment = experimentid
    barcode = barcodeid
    MIRL = mirl

    # SCCmec
    dfsub = sheets['Sccmec']
    if dfsub.notna().any().any():
        sccmec = dfsub['type'][0]
    else:
        sccmec = "NA"

    # MLST type
    # Import MLST databases which fit to the suspected species, only one answer will be searched
    dfsub = sheets['MLST_Summary']
    dbmlst = pd.read_csv(mlstdb, sep = '\t', header = 0)
    dbmlst = dbmlst.set_index('ST')['clonal_complex'].to_dict()

    dfsub['mlstlocus'] = dfsub[['Locus 1', 'Locus 2', 'Locus 3', 'Locus 4', 'Locus 5', 'Locus 6', 'Locus 7']].agg('-'.join, axis=1)
    if dfsub.notna().any().any():
        mlst = 'ST' + str(dfsub['Sequence Type'][0])
        mlstcc = dbmlst.get(dfsub['Sequence Type'][0], "NA")
        if pd.isna(mlstcc):
            mlstcc = "NA"
        if str(dfsub['Sequence Type'][0]) == '-':
            # if MLST == '-' no value -> return all 7 housekeeping genes locus type
            mlst = dfsub['mlstlocus'][0]
    else:
        mlst = "NA"
        mlstcc = "NA"


    dfsub = sheets['SpaTyper']
    if dfsub.notna().any().any():
        spa = dfsub['Spa-type'][0]
        spacc = dbspa.get(spa, "NA")
    else:
        spa = "NA"
        spacc = "NA"

    # MRSA clone
    mrsa_clone = match_mrsa_clone_type(sccmec, spacc, mrsa_df)

    # drug genes check
    unique_genes = drugsdb['Gene'].unique()

    gene_count = defaultdict(int)
    for gene in unique_genes:
        gene_count[gene] = 0

    dfstaramr = sheets['Staramr_Detail']
    dfstaramr = dfstaramr.loc[1:]
    dfcard = sheets['CARD']
    dfvfdb = sheets['VirulenceFinder']
    dfpointfinder = sheets['PointFinder']

    vfdblist = []
    other_genes_res = []
    other_genes_plasmid = []
    other_genes_card = []
    pointfinderlist = []
    drugslist = []

    # overall
    for gene, datatype, drugs in zip(dfstaramr['Data'], dfstaramr['Data Type'],dfstaramr['CGE Predicted Phenotype']):
        if gene in gene_count and gene_count[gene] == 0:
            gene_count[gene] += 1
        else:
            if datatype == 'Plasmid':
                other_genes_plasmid.append(gene)
            else:
                other_genes_res.append(gene)
            #other_genes.append(gene)
        if not pd.isna(drugs):
            tmp = [word.strip() for word in drugs.split(',')]
            for abbr in tmp:
                if abbr in antibiotics_dict:
                    drugslist.append(antibiotics_dict.get(abbr))
                else:
                    drugslist.append(abbr)


    for gene, drugs in zip(dfcard['Best_Hit_ARO'], dfcard['Antibiotic']):
        target_gene = [key for key in gene_count.keys() if key in gene]
        if len(target_gene) != 1:
            other_genes_card.append(gene)

        if len(target_gene) == 1 and gene_count[target_gene[0]] == 0:
            gene_count[target_gene[0]] += 1

        if not pd.isna(drugs):
            words = [word.strip() for word in drugs.split(';')]
            tmp = [word.title() for word in words]
            for abbr in tmp:
                if abbr in antibiotics_dict:
                    drugslist.append(antibiotics_dict.get(abbr))
                else:
                    drugslist.append(abbr)

    for gene in dfvfdb['virulence_gene']:
        vfdblist.append(gene)
        if gene in gene_count and gene_count[gene] == 0:
            gene_count[gene] += 1

    for gene in dfpointfinder['Gene']:
        pointfinderlist.append(gene)
        if gene in gene_count and gene_count[gene] == 0:
            gene_count[gene] += 1

    # make result
    data = {
        'Experiment ID': experiment,
        'Barcode assignment': barcode,
        'MIRL ID': MIRL,
        'SCCmec': sccmec,
        'MLST': mlst,
        'MLST_CC': mlstcc,
        'spa type': spa,
        'spa_CC': spacc,
        'MRSA Clone': mrsa_clone
    }

    for gene, count in gene_count.items():
        data[gene] = count

    # other genes change to database
    othergenes_res = list(dict.fromkeys(other_genes_res))
    othergenes_res = [item for item in othergenes_res if not (isinstance(item, float) and math.isnan(item))]
    othergenes_plasmid = list(dict.fromkeys(other_genes_plasmid))
    othergenes_plasmid = [item for item in othergenes_plasmid if not (isinstance(item, float) and math.isnan(item))]
    othergenes_card = list(dict.fromkeys(other_genes_card))
    othergenes_card = [item for item in othergenes_card if not (isinstance(item, float) and math.isnan(item))]
    drugslist = list(dict.fromkeys(drugslist))
    three_letter_items = [item for item in drugslist if len(item) == 3]
    other_items = [item for item in drugslist if len(item) != 3]
    sorted_items = three_letter_items + other_items

    arggenes_res = ';'.join(othergenes_res)
    plasmids = ';'.join(othergenes_plasmid)
    arggenes_card = ';'.join(othergenes_card)
    amrlist = ';'.join(sorted_items)
    vfdbst = ';'.join(vfdblist)
    pointfinderst = ';'.join(pointfinderlist)

    
    for gene, count in gene_count.items():
        data[gene] = count

    # Save all to the drug table
    combined_df = pd.DataFrame(data, index=[0])
    combined_df.replace(0, "", inplace=True)
    combined_df.iloc[0,61] = pointfinderst
    combined_df.iloc[0,62] = plasmids # ARG-others
    combined_df.iloc[0,63] = arggenes_res # AMR predict
    combined_df.iloc[0,64] = arggenes_card # 
    combined_df.iloc[0,65] = amrlist
    combined_df.iloc[0,66] = vfdbst


    return combined_df

    
if __name__ == '__main__':

    parser = argparse.ArgumentParser(description="This is the tool to gather all the results from MRSA nextflow pipeline into single excel sheet.")
    parser.add_argument('-i', '--inputfile', required=True, help="input excel file is the prediction results of each sample.")
    parser.add_argument('-f', '--samplesheet', required=True, help="input original sample sheet file which used to rename the FASTA file.")
    parser.add_argument('-s', '--mirlid', required=True, help="input MIRL ID of the sample that matched the inputfile.")
    parser.add_argument('-d', '--druglist', required=True, help="The path to druglist.xlsx")
    parser.add_argument('-m', '--mlstdb', required=True, help="MLST db file.")
    parser.add_argument('-c', '--spacc', required=True, help="SPA-CC json file.")
    parser.add_argument('-o', '--outputfile', required=True, help="input your output file name (csv).")

    args = parser.parse_args()
    inputfile = args.inputfile
    outputfile = args.outputfile
    samplesheet = args.samplesheet
    mirl_id = args.mirlid
    druglist = args.druglist
    mlstdb = args.mlstdb
    spacc = args.spacc
    samplesheet_df = pd.read_excel(samplesheet)
    experiment_id,barcode = tuple(samplesheet_df.loc[samplesheet_df["MIRL no."] == mirl_id, ["Experiment ID","barcode"]].iloc[0,])

    antibiotics_dict = {
        'Gentamicin': 'GEN',
        'Streptomycin': 'STR',
        'Rifampin': 'RIF',
        'Ceftaroline': 'CPT',
        'Ceftriaxone': 'CRO',
        'Cefiderocol': '',
        'Ciprofloxacin': 'CIP',
        'Levofloxacin': 'LVX',
        'Moxifloxacin': 'MFX',
        'Trimethoprim': 'SXT',
        'Sulfamethoxazole': 'SXT',
        'Vancomycin': 'VAN',
        'Telavancin': 'TLV',
        'Teicoplanin': 'TEC',
        'Clindamycin': 'CLI',
        'Daptomycin': 'DAP',
        'Erythromycin': 'ERY',
        'Nitrofurantoin': 'NIT',
        'Linezolid': 'LNZ',
        'Ampicillin': 'AMP',
        'Penicillin': 'PEN',
        'Oxacillin': 'OXA',
        'Chloramphenicol': 'CHL',
        'Tetracycline': 'TCY',
        'Tigecycline': 'TGC'
    }

    # MRSA clone
    mrsa_data = {
        'MRSA_clone_type': ['TW100', 'TW200', 'TW300', 'TW400', 'TW500', 'USA300'],
        'SCCmec': ['III', 'IV', 'V', 'II', 'IV or V', 'IV'],
        'spa_CC': ['spa-CC037', 'spa-CC437', 'spa-CC437', 'spa-CC002', 'spa-CC1081', 'spa-CC008']
    }
    mrsa_df = pd.DataFrame(mrsa_data)

    # drug genes check
    drugsdb = pd.read_excel(druglist, sheet_name='drugs')
    
    # spa cc
    with open(spacc, 'r') as file:
        dbspa = json.load(file)
    
    # Merge template and output
    combined_df = transferReport(inputfile, experiment_id, barcode, mirl_id)
    combined_df.to_csv(outputfile, header = False, index = False)



