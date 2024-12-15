#!/bin/bash -euo pipefail
sed -i '118s#_")#-")#' /usr/local/lib/python3.9/site-packages/staramr/blast/results/pointfinder/nucleotide/PointfinderHitHSPPromoter.py
species=$(echo Staphylococcus aureus | tr '[:upper:]' '[:lower:]' | sed 's/ /_/')
mv input.fasta MR05.fasta
staramr search --pointfinder-organism $species                    --output-summary MR05_summary.tsv                    --output-detailed-summary MR05_detailed_summary.tsv                    --output-resfinder MR05_resfinder.tsv                    --output-pointfinder MR05_pointfinder.tsv                    --output-plasmidfinder MR05_plasmidfinder.tsv                    --output-settings MR05_settings.txt                    --output-excel MR05_results.xlsx                    --output-hits-dir MR05_hits                    --output-mlst MR05_mlst.tsv                    MR05.fasta
