#!/bin/bash -euo pipefail
sed -i '116s#_")#-")#' /usr/local/lib/python3.9/site-packages/staramr/blast/results/pointfinder/nucleotide/PointfinderHitHSPPromoter.py
species=$(echo Staphylococcus aureus | tr '[:upper:]' '[:lower:]' | sed 's/ /_/')
mv input.fasta 2C010.fasta
staramr search --pointfinder-organism $species                    --output-summary 2C010_summary.tsv                    --output-detailed-summary 2C010_detailed_summary.tsv                    --output-resfinder 2C010_resfinder.tsv                    --output-pointfinder 2C010_pointfinder.tsv                    --output-plasmidfinder 2C010_plasmidfinder.tsv                    --output-settings 2C010_settings.txt                    --output-excel 2C010_results.xlsx                    --output-hits-dir 2C010_hits                    --output-mlst 2C010_mlst.tsv                    2C010.fasta
