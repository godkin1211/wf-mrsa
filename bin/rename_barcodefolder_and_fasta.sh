#!/bin/bash

codebook_excel_file=$1
path2projfolder=$2
outputdir=$3

[ ! -e $codebook_excel_file ] && echo -e "\033[1;31m* Error: please make sure if the codebook file exists!\033[0m" && exit 1

echo -e "\033[1;32m* Extract information from excel file: $codebook_excel_file\033[0m"
echo -e "\033[1m  - Get folder information from Experiment ID and check if these folders exists!\033[0m"

projfolders=($(in2csv $codebook_excel_file | sed '1d' | cut -d ',' -f 1 | uniq))

for folder in ${projfolders[@]}; do
  folder=$path2projfolder/$folder
  [[ ! -d "$folder" ]] && echo -e "\033[1;31m* Error: the folder $folder does not exist!\033[0m" && exit 1
done

# Check if outputdir exists, build it if not exists
if [ -d "$outputdir" ]; then
  echo -e "\033[1;33m* Warning: the output directory has already existed!"
  exit 0
else
  echo -e "\033[1;32m* Build output directory\033[0m" && mkdir -p $outputdir
fi

codebook=($(in2csv $codebook_excel_file | sed '1d'))
echo -e "\033[1;32m* Change the file names and folder into required formats\033[0m"
for cc in ${codebook[@]}; do
  folder=$(echo $cc | cut -d ',' -f 1)
  barcode=$(echo $cc | cut -d ',' -f 2)
  mirlno=$(echo $cc | cut -d ',' -f 3)
  projfolder=$path2projfolder/$folder
  barcodefolder=$projfolder/$barcode
  fastafilelocation=$barcodefolder/homopolish/consensus_homopolished.fasta
  targetfastaname="${outputdir}/${mirlno}.fasta"
  [ -e $fastafilelocation ] && echo -e "  - Move \033[1m$fastafilelocation\033[0m to \033[1m$targetfastaname\033[0m" && cp $fastafilelocation $targetfastaname
done
