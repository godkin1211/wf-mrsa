process gatherResultsV1 {
    publishDir "${params.out_dir}/prediction_results", mode: 'copy'
    maxForks 1
    debug true

    input:
    tuple val(sample), path(staramr_result), path(sccmec_result), path(spatyper_result), path(virulencefinder_result), path(card_result)
    val spafreq

    output:
    tuple val(sample), path("${sample}.xlsx")
    """
    gatherMRSA.py -s $sample \
                  -t ${spatyper_result} \
                  -d $spafreq \
                  -m ${sccmec_result} \
                  -a ${staramr_result} \
                  -v ${virulencefinder_result} \
                  -c ${card_result} \
                  -o ${sample}
    """
}



process gatherResultsV2 {
    publishDir "$params.out_dir", mode: 'copy'
    maxForks 1
    debug true

    input:
    tuple val(sample), path(staramr_result_mlst), path(staramr_result_resfinder), path(staramr_result_pointfinder),path(staramr_result_plasmidfinder), \
    path(sccmec_result), path(spatyper_result), path(virulencefinder_result), path(card_result)
    val spafreq
    val spaccdb
    val resfinder_notes_file
    val card_aro2short_file
    val required_genes_file
    val samplesheetvalue

    output:
    stdout
    //path "${sample}.xlsx", emit: prediction_results

    """
    #!/bin/bash
    mirl_id=$sample
    targetRow=\$(in2csv ${samplesheetvalue} | grep "\${mirl_id}")
    experiment_id=\$(echo \$targetRow | cut -d ',' -f 1)
    barcode=\$(echo \$targetRow | cut -d ',' -f 2)
    # Extract MLST info
    mlst_res=\$(cat ${staramr_result_mlst} | wc -l)
    if (( \${mlst_res} == 1 )); then
        mlst_type="NA"
        mlst_cc="NA"
    else
        mlst_res=\$(cat ${staramr_result_mlst} | tail -n 1)
        species=\$(echo \${mlst_res} | cut -d ' ' -f 2)
        mlst_type=\$(echo \${mlst_res} | cut -d ' ' -f 3)
        [[ \${mlst_type} == "-" ]] && mlst_type=\$(echo \${mlst_res} | cut -d ' ' -f 4-10 | tr ' ' '-')
        mlstdb=/home/\$(whoami)/epi2melabs/workflows/nhri-labs/wf-mrsa/databases/\${species}.tsv
        mlst_cc=\$(awk -F '\\t' -v type=\${mlst_type} '\$1==type { print \$9 }' \${mlstdb})
        [[ -z \${mlst_cc} ]] && mlst_cc="NA"
    fi
    # Processing Sccmec part
    sccmec_res=\$(cat ${sccmec_result} | wc -l)
    if (( \${sccmec_res} == 1 )); then
        sccmec_type="NA"
    else
        sccmec_res=\$(cat ${sccmec_result} | tail -n 1)
        sccmec_type=\$(echo \${sccmec_res} | cut -d ' ' -f 2)
    fi

    # Processing SpaTyper part
    spatype_res=\$(cat ${spatyper_result} | wc -l)
    if (( \${spatype_res} == 1 )); then
        spa_type="NA"
        spa_cc="NA"
    else
        spa_type=\$(cat ${spatyper_result} | tail -n 1 | cut -f 3)
        spa_cc=\$(grep "\${spa_type}" ${spaccdb} | sed 's#,##; s#\"##g; s#[[:space:]]##g' | cut -d':' -f2)
        [[ -z \${spa_cc} ]] && spa_cc="NA"
    fi

    # Determine the Clone type
    new_sccmec_type=\$(echo \${sccmec_type} | sed 's# ##g')
    clone_key="\${new_sccmec_type}_\${spa_cc}"
    case "\${clone_key}" in
        "IVorV_spa-CC1081") clonetype="TW500"
            ;;
        "IV_spa-CC008") clonetype="USA300"
            ;;
        "III_spa-CC037") clonetype="TW100"
            ;;
        "IV_spa-CC437") clonetype="TW200"
            ;;
        "V_spa-CC437") clonetype="TW300"
            ;;
        "II_spa-CC002") clonetype="TW400"
            ;;
        *) clonetype="Other"
    esac

    # Processing PlasmidFinder part
    plasmidfinder_amr_genes=\$(cat ${staramr_result_plasmidfinder} | sed '1d' | cut -f 2 | tr '\\n' ';' | sed 's/;\$//')

    # Processing PointFinder part
    pointfinder_results=\$(cat ${staramr_result_pointfinder} | sed '1d' | cut -f 2,17 | sed 's/\\t/:/' | tr '\\n' ';' | sed 's/;\$//')

    # Processing ResFinder part
    declare -A resfinderInfo
    while IFS=":" read -r key value drop; do
        resfinderInfo[\$key]=\$value
    done < ${resfinder_notes_file}
    resfinder_results_amrgenes=(\$(cat ${staramr_result_resfinder} | sed '1d' | cut -f 2))
    resfinder_results_treatments=(\$(cat ${staramr_result_resfinder} | sed '1d' | cut -f 3 | sed 's/, /|/g'))
    resfinder_amr_class=(\$(for i in \${resfinder_results_amrgenes[@]}; do echo \${resfinderInfo[\$i]} | sed 's/,/   /g'; done))
    numRecordsInResfinderResults=\$(expr \${#resfinder_results_amrgenes[@]} - 1)
    resfinder_results=\$(for i in \$(seq 0 \$numRecordsInResfinderResults); do g=\${resfinder_results_amrgenes[\$i]}; echo "\${g}:\${resfinder_results_treatments[\$i]}:\${resfinderInfo[\$g]}"; done | tr '\\n' ';' | sed 's/;\$//')
    
    # Processing CARD part
    IFS=\$'\\n' read -d '' -r -a card_results_amrgenes < <(cat ${card_result} | sed '1d' | cut -f 9)
    IFS=\$'\\n' read -d '' -r -a card_results_treatments < <(cat ${card_result} | sed '1d' | cut -f 15 | sed 's/ antibiotic//g;s/;/|/g')
    IFS=\$'\\n' read -d '' -r -a card_results_class < <(cat ${card_result} | sed '1d' | cut -f 16)
    IFS=\$'\\n' read -d '' -r -a required_amrgenes < <(cat ${required_genes_file} | cut -f 2 | sed 's/Enterotoxin[[:space:]]//')
    numRecordsInCardResults=\$(expr \${#card_results_amrgenes[@]} - 1)
    numRequiredAMRGenes=\$(expr \${#required_amrgenes[@]} - 1)
    card_results=\$(for i in \$(seq 0 \${numRecordsInCardResults}); do for j in \$(seq 0 \${numRequiredAMRGenes}); do [[ "\${card_results_amrgenes[\$i]}" =~ "\${required_amrgenes[\$j]}" ]] && echo -e "\${card_results_amrgenes[\$i]}:\${required_amrgenes[\$j]}" | grep -v -e "aureus" -e "aur" | cut -d':' -f2  ; done; done | tr '\\n' ':' | sed 's/:\$//')
    echo -e "\${experiment_id},\${barcode},\${mirl_id},ST\${mlst_type},\${mlst_cc},\${sccmec_type},\${spa_type},\${spa_cc},\${clonetype},\${plasmidfinder_amr_genes},\${pointfinder_results},\${resfinder_results},\${card_results}"
    """
}
