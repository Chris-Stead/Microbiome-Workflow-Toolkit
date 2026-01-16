#!/usr/bin/env bash
set -euo pipefail

# directory for the PROJECT folder, all the SAMPLES/RUNS within the PROJECT folder will have their duplicate reads merged without deleting the originals
BASE_DIR="/mnt/seaes01-data01/nixon-microbiome/shared/edinburgh_genomics/27131_Nixon_Sophie/raw_data/20230706/"
echo "Project directory =" $BASE_DIR 
for SAMPLE_DIR in "${BASE_DIR}"/*/; do
    SAMPLE=$(basename "${SAMPLE_DIR}")
    echo "processing $SAMPLE"

    shopt -s nullglob
    FORWARD=("${SAMPLE_DIR}"/*_1.fastq.gz)
    REVERSE=("${SAMPLE_DIR}"/*_2.fastq.gz)
    shopt -u nullglob

    # Skip folder if no FASTQs
    [[ ${#FORWARD[@]} -eq 0 && ${#REVERSE[@]} -eq 0 ]] && continue

    # Merge all forward reads into sample_1.fastq.gz
    if [[ ${#FORWARD[@]} -gt 0 ]]; then
        echo "merging reads ${#FORWARD[@]}" 
        zcat "${FORWARD[@]}" > "${SAMPLE_DIR}/${SAMPLE}_merged_1.fastq.gz"
    fi

    # Merge all reverse reads into sample_2.fastq.gz
    if [[ ${#REVERSE[@]} -gt 0 ]]; then
    echo "merging reads ${#REVERSE[@]}"
        zcat "${REVERSE[@]}" > "${SAMPLE_DIR}/${SAMPLE}_merged_2.fastq.gz"
    fi
done
echo "Merging complete."
