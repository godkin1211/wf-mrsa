#!/bin/bash -euo pipefail
sed -i '116s#_")#-")#' /usr/local/lib/python3.9/site-packages/staramr/blast/results/pointfinder/nucleotide/PointfinderHitHSPPromoter.py
species=$(echo Staphylococcus aureus | tr '[:upper:]' '[:lower:]' | sed 's/ /_/')
mv input.fasta sau021.fasta
staramr search --pointfinder-organism $species                    --output-summary sau021_summary.tsv                    --output-detailed-summary sau021_detailed_summary.tsv                    --output-resfinder sau021_resfinder.tsv                    --output-pointfinder sau021_pointfinder.tsv                    --output-plasmidfinder sau021_plasmidfinder.tsv                    --output-settings sau021_settings.txt                    --output-excel sau021_results.xlsx                    --output-hits-dir sau021_hits                    --output-mlst sau021_mlst.tsv                    sau021.fasta
