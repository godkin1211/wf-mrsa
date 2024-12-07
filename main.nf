//import groovy.json.JsonBuilder
include { runPGAP } from './modules/PGAP.nf'
include { runRGI } from './modules/RGI.nf'
include { runStarAMR } from './modules/StarAMR.nf'
include { runVirulenceFinder } from './modules/VirulenceFinder.nf'
include { runSccmec } from './modules/SCCmec.nf'
include { runSpaTyper } from './modules/spaTyper.nf'
include { gatherResultsV1 } from './modules/gatherResultFromSingleSample.nf'
include { convertExcelToHTML } from './modules/Excel2HTML.nf'
include { renameFastaFiles } from './modules/RenameFasta.nf'
include { parseGatheredResults } from './modules/parseGatheredResults.nf'
include { mergrResultsWithTemplate } from './modules/MergeResults.nf'



workflow {
    // Creating channel from arguments
    species = Channel.value(params.species)
    path2projfolder = Channel.fromPath(params.path2projfolder)
    samplesheetfile = Channel.fromPath(params.samplesheet)
    samplesheetvalue = Channel.value(params.samplesheet)
    virulencefinderdb = Channel.value(params.virulencefinderdb)
    spa_type_file = Channel.value(params.spa_type_file)
    spa_repeat_file = Channel.value(params.spa_repeat_file)
    //card_json = Channel.value(params.card_json)
    //card_annotation = Channel.value(params.card_annotation)
    //card_annotation_all_models = Channel.value(params.card_annotation_all_models)
    //wildcard_annotation = Channel.value(params.wildcard_annotation)
    //wildcard_annotation_all_models = Channel.value(params.wildcard_annotation_all_models)
    //wildcard_index = Channel.value(params.wildcard_index)
    //wildcard_version = Channel.value(params.wildcard_version)
    //amr_kmers = Channel.value(params.amr_kmers)
    //kmer_database = Channel.value(params.kmer_database)
    //kmer_size = Channel.value(params.kmer_size)
    card_db_dir = Channel.value(params.card_db_dir)
    spa_freq_file = Channel.value(params.spa_freq_file)
    spaccdb_file = Channel.value(params.spaccdb_file)
    spadb_file = Channel.value(params.spadb_file)
    druglist_file = Channel.value(params.druglist_file)
    final_result_template_file = Channel.value(params.template_file)

    // Beginning of this pipeline
    fastafilelist = renameFastaFiles(samplesheetfile, path2projfolder).flatten()
    sampleidANDfasta = fastafilelist.map { it -> [it.getSimpleName(), it] } // Extract MIRL ID from fasta file and emit [mirl.id, fastafile] into output channel
    /*
    (pgap_out_dir, pgap_annot_sampleid_and_aa_seq) = runPGAP(sampleidANDfasta, species)
    card_result = runRGI(pgap_annot_sampleid_and_aa_seq, card_json, card_annotation, card_annotation_all_models, \
                        wildcard_annotation, wildcard_annotation_all_models, wildcard_index, wildcard_version, \
                        amr_kmers, kmer_database, kmer_size)
    */
    card_result = runRGI(sampleidANDfasta, card_db_dir)
    staramr_result = runStarAMR(sampleidANDfasta, species)
    virulencefinder_result = runVirulenceFinder(sampleidANDfasta, virulencefinderdb)
    sccmec_result = runSccmec(sampleidANDfasta)
    spatyper_result = runSpaTyper(sampleidANDfasta, spa_type_file, spa_repeat_file)
    prediction_results = staramr_result.join(sccmec_result, remainder: true)
                                       .join(spatyper_result, remainder: true)
                                       .join(virulencefinder_result, remainder: true)
                                       .join(card_result, remainder: true)
    // Parsing prediction outputs and generating summary files
    gathered_results = gatherResultsV1(prediction_results, spa_freq_file)
    outputfiles = gathered_results.collect(flat: false, sort: true)
    excelfiles = outputfiles.flatMap { it->it }.map{ it -> it[1] }
    summary_file = parseGatheredResults(excelfiles, druglist_file, spaccdb_file, samplesheetvalue).collectFile(name: "${params.out_dir}/summaries.csv")
    mergrResultsWithTemplate(summary_file, final_result_template_file)

    // SheetName: ResFinder, PlasmidFinder, MLST_Summary, Staramr_Summary, Staramr_Detail, VirulenceFinder, Sccmec, SpaTyper, CARD
    //convertExcelToHTML(gathered_results)
}