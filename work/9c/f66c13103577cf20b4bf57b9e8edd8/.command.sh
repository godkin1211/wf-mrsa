#!/bin/bash -euo pipefail
species=$(echo Staphylococcus aureus | tr '[:upper:]' '[:lower:]' | sed 's/ /_/')
mv input.fasta sau027.fasta
staramr search --pointfinder-organism $species                    --output-summary sau027_summary.tsv                    --output-detailed-summary sau027_detailed_summary.tsv                    --output-resfinder sau027_resfinder.tsv                    --output-pointfinder sau027_pointfinder.tsv                    --output-plasmidfinder sau027_plasmidfinder.tsv                    --output-settings sau027_settings.txt                    --output-excel sau027_results.xlsx                    --output-hits-dir sau027_hits                    --output-mlst sau027_mlst.tsv                    sau027.fasta
