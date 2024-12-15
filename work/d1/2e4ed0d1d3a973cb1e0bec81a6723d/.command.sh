#!/bin/bash -euo pipefail
sed -i '116s#_")#-")#' /usr/local/lib/python3.9/site-packages/staramr/blast/results/pointfinder/nucleotide/PointfinderHitHSPPromoter.py
species=$(echo Staphylococcus aureus | tr '[:upper:]' '[:lower:]' | sed 's/ /_/')
mv input.fasta MR04.fasta
staramr search --pointfinder-organism $species                    --output-summary MR04_summary.tsv                    --output-detailed-summary MR04_detailed_summary.tsv                    --output-resfinder MR04_resfinder.tsv                    --output-pointfinder MR04_pointfinder.tsv                    --output-plasmidfinder MR04_plasmidfinder.tsv                    --output-settings MR04_settings.txt                    --output-excel MR04_results.xlsx                    --output-hits-dir MR04_hits                    --output-mlst MR04_mlst.tsv                    MR04.fasta
