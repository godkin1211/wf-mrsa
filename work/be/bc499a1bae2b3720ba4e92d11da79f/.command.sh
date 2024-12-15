#!/bin/bash -euo pipefail
sed -i '116s#_")#-")#' /usr/local/lib/python3.9/site-packages/staramr/blast/results/pointfinder/nucleotide/PointfinderHitHSPPromoter.py
species=$(echo Staphylococcus aureus | tr '[:upper:]' '[:lower:]' | sed 's/ /_/')
mv input.fasta MR03.fasta
staramr search --pointfinder-organism $species                    --output-summary MR03_summary.tsv                    --output-detailed-summary MR03_detailed_summary.tsv                    --output-resfinder MR03_resfinder.tsv                    --output-pointfinder MR03_pointfinder.tsv                    --output-plasmidfinder MR03_plasmidfinder.tsv                    --output-settings MR03_settings.txt                    --output-excel MR03_results.xlsx                    --output-hits-dir MR03_hits                    --output-mlst MR03_mlst.tsv                    MR03.fasta
