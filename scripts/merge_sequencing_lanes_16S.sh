#!/usr/bin/env bash
set -euo pipefail

# directory for the PROJECT folder, all the SAMPLES/RUNS within the PROJECT folder will have their duplicate reads merged without deleting the originals
BASE_DIR="/mnt/seaes01-data01/nixon-microbiome/shared/Liverpool_genomics/Project_204920_16S_MiSeq_140826/Raw"
echo "Project directory =" $BASE_DIR 
for SAMPLE_DIR in "${BASE_DIR}"/*/; do
    SAMPLE=$(basename "${SAMPLE_DIR}")
    echo "processing $SAMPLE"

    shopt -s nullglob
    FORWARD=("${SAMPLE_DIR}"/*_R1.fastq.gz)
    REVERSE=("${SAMPLE_DIR}"/*_R2.fastq.gz)
    shopt -u nullglob

    # Skip folder if no FASTQs
    [[ ${#FORWARD[@]} -eq 0 && ${#REVERSE[@]} -eq 0 ]] && continue

    # Merge all forward reads into sample_1.fastq.gz
    if [[ ${#FORWARD[@]} -gt 0 ]]; then
        echo "merging reads ${#FORWARD[@]}" 
        cat "${FORWARD[@]}" > "${SAMPLE_DIR}/${SAMPLE}_merged_R1.fastq.gz"
    fi

    # Merge all reverse reads into sample_2.fastq.gz
    if [[ ${#REVERSE[@]} -gt 0 ]]; then
    echo "merging reads ${#REVERSE[@]}"
        cat "${REVERSE[@]}" > "${SAMPLE_DIR}/${SAMPLE}_merged_R2.fastq.gz"
    fi
done
echo "Merging complete."
