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
    virulencefinderdb = Channel.value(params.virulencefinderdb)
    spa_type_file = Channel.value(params.spa_type_file)
    spa_repeat_file = Channel.value(params.spa_repeat_file)
    card_db_dir = Channel.value(params.card_db_dir)
    spa_freq_file = Channel.value(params.spa_freq_file)
    spaccdb_file = Channel.value(params.spaccdb_file)
    spadb_file = Channel.value(params.spadb_file)
    druglist_file = Channel.value(params.druglist_file)
    final_result_template_file = Channel.value(params.template_file)

    // Beginning of this pipeline
    samplesheetfile = Channel.value(params.samplesheet)
    if (params.path2projfolder) {
        path2projfolder = Channel.fromPath(params.path2projfolder)
        fastafilelist = renameFastaFiles(samplesheetfile, path2projfolder).flatten()
    }
    if (params.path2fastafolder) {
        fastafilelist = Channel.fromPath(["${params.path2fastafolder}/*.fa", "${params.path2fastafolder}/*.fasta", "${params.path2fastafolder}/*.fna"])
    }
    
    // If input files does not include a sample sheet, then create a fake sample sheet using the file names
    if (! params.samplesheet) {
        fake_samplesheet = fastafilelist.map { it -> it.getSimpleName() }.map { it -> it + "," + it + "," + it}
        samplesheetfile = Channel.of("Experiment ID,barcode,MIRL no.")
                                 .concat(fake_samplesheet)
                                 .collectFile(name: "samplesheet.csv", sort: false, newLine: true)
    }
    sampleidANDfasta = fastafilelist.map { it -> [it.getSimpleName(), it] }

    //if (params.runPGAP == true) {
    //    (pgap_out_dir, pgap_annot_sampleid_and_aa_seq, pgap_gff, pgap_gbk) = runPGAP(sampleidANDfasta, species)
    //    card_result = runRGI(pgap_annot_sampleid_and_aa_seq, card_db_dir)
    //} else {
    //    card_result = runRGI(sampleidANDfasta, card_db_dir)
    //}
    staramr_result = runStarAMR(sampleidANDfasta, species)
    //virulencefinder_result = runVirulenceFinder(sampleidANDfasta, virulencefinderdb)
    //sccmec_result = runSccmec(sampleidANDfasta)
    //spatyper_result = runSpaTyper(sampleidANDfasta, spa_type_file, spa_repeat_file)
    //prediction_results = staramr_result.join(sccmec_result, remainder: true)
    //                                   .join(spatyper_result, remainder: true)
    //                                   .join(virulencefinder_result, remainder: true)
    //                                   .join(card_result, remainder: true)
    // Parsing prediction outputs and generating summary files
    // gathered_results = gatherResultsV1(prediction_results, spa_freq_file)
    // outputfiles = gathered_results.collect(flat: false, sort: true)
    // excelfiles = outputfiles.flatMap { it->it }.map{ it -> it[1] }
    // summary_file = parseGatheredResults(excelfiles, druglist_file, spaccdb_file, samplesheetfile).collectFile(name: "${params.out_dir}/summaries.csv")
    // mergrResultsWithTemplate(summary_file, final_result_template_file)
    // SheetName: ResFinder, PlasmidFinder, MLST_Summary, Staramr_Summary, Staramr_Detail, VirulenceFinder, Sccmec, SpaTyper, CARD
}
