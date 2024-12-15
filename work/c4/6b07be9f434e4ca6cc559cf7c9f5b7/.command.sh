#!/bin/bash -euo pipefail
sed -i '116s#_")#-")#' /usr/local/lib/python3.9/site-packages/staramr/blast/results/pointfinder/nucleotide/PointfinderHitHSPPromoter.py
species=$(echo Staphylococcus aureus | tr '[:upper:]' '[:lower:]' | sed 's/ /_/')
mv input.fasta WGS-001.fasta
staramr search --pointfinder-organism $species                    --output-summary WGS-001_summary.tsv                    --output-detailed-summary WGS-001_detailed_summary.tsv                    --output-resfinder WGS-001_resfinder.tsv                    --output-pointfinder WGS-001_pointfinder.tsv                    --output-plasmidfinder WGS-001_plasmidfinder.tsv                    --output-settings WGS-001_settings.txt                    --output-excel WGS-001_results.xlsx                    --output-hits-dir WGS-001_hits                    --output-mlst WGS-001_mlst.tsv                    WGS-001.fasta
