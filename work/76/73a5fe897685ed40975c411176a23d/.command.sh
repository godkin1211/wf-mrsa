#!/bin/bash -euo pipefail
sed -i '116s#_")#-")#' /usr/local/lib/python3.9/site-packages/staramr/blast/results/pointfinder/nucleotide/PointfinderHitHSPPromoter.py
species=$(echo Staphylococcus aureus | tr '[:upper:]' '[:lower:]' | sed 's/ /_/')
mv input.fasta WGS-010.fasta
staramr search --pointfinder-organism $species                    --output-summary WGS-010_summary.tsv                    --output-detailed-summary WGS-010_detailed_summary.tsv                    --output-resfinder WGS-010_resfinder.tsv                    --output-pointfinder WGS-010_pointfinder.tsv                    --output-plasmidfinder WGS-010_plasmidfinder.tsv                    --output-settings WGS-010_settings.txt                    --output-excel WGS-010_results.xlsx                    --output-hits-dir WGS-010_hits                    --output-mlst WGS-010_mlst.tsv                    WGS-010.fasta
