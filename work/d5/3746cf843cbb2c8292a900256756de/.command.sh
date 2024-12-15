#!/bin/bash -euo pipefail
sed -i '116s#_")#-")#' /usr/local/lib/python3.9/site-packages/staramr/blast/results/pointfinder/nucleotide/PointfinderHitHSPPromoter.py
species=$(echo Staphylococcus aureus | tr '[:upper:]' '[:lower:]' | sed 's/ /_/')
mv input.fasta MR01.fasta
staramr search --pointfinder-organism $species                    --output-summary MR01_summary.tsv                    --output-detailed-summary MR01_detailed_summary.tsv                    --output-resfinder MR01_resfinder.tsv                    --output-pointfinder MR01_pointfinder.tsv                    --output-plasmidfinder MR01_plasmidfinder.tsv                    --output-settings MR01_settings.txt                    --output-excel MR01_results.xlsx                    --output-hits-dir MR01_hits                    --output-mlst MR01_mlst.tsv                    MR01.fasta
