#!/usr/bin/env bash
set -euo pipefail
source "$HOME/miniconda3/etc/profile.d/conda.sh"

# directory for the PROJECT folder, all the SAMPLES/RUNS within the PROJECT folder will have their duplicate reads merged without deleting the originals
PROJECT_FOLDER="/mnt/seaes01-data01/nixon-microbiome/shared/novogene/20261020_LW_metagenomics"
BASE_DIR=$(realpath "$PROJECT_FOLDER")

echo "Project directory =" $BASE_DIR 
for SAMPLE_DIR in "${BASE_DIR}"/*/01.RawData/*/; do
    SAMPLE=$(basename "${SAMPLE_DIR}")
    echo "processing $SAMPLE"

    shopt -s nullglob
        FORWARD=("${SAMPLE_DIR}"/*_L[0-9]*_1.f*q.gz)
        REVERSE=("${SAMPLE_DIR}"/*_L[0-9]*_2.f*q.gz)
    shopt -u nullglob

        OUT_R1="${SAMPLE_DIR}/${SAMPLE}_merged_1.fastq.gz"
        OUT_R2="${SAMPLE_DIR}/${SAMPLE}_merged_2.fastq.gz"

    # Skip samples where both outputs already exist
    if [[ -f "$OUT_R1" && -f "$OUT_R2" ]]; then
    echo "Skipping $SAMPLE: both merged files exist"
    continue
    fi

    # Stop if only one output exists
    if [[ -f "$OUT_R1" || -f "$OUT_R2" ]]; then
    echo "ERROR: Only one merged file exists for $SAMPLE"
    exit 1
    fi

    # Skip folder if no FASTQs
    [[ ${#FORWARD[@]} -eq 0 && ${#REVERSE[@]} -eq 0 ]] && continue
        if [[ ${#FORWARD[@]} -ne ${#REVERSE[@]} ]]; then
    echo "ERROR: Unequal R1/R2 file counts for $SAMPLE"
    exit 1
        fi

    # Merge all forward reads into sample_1.fastq.gz
    conda activate pigz 
        if [[ ${#FORWARD[@]} -gt 0 ]]; then
        echo "merging reads ${#FORWARD[@]}" 
        zcat "${FORWARD[@]}" | pigz -p 5 > "${SAMPLE_DIR}/${SAMPLE}_merged_1.fastq.gz"
    fi

    # Merge all reverse reads into sample_2.fastq.gz
    if [[ ${#REVERSE[@]} -gt 0 ]]; then
    echo "merging reads ${#REVERSE[@]}"
        zcat "${REVERSE[@]}" | pigz -p 5 > "${SAMPLE_DIR}/${SAMPLE}_merged_2.fastq.gz"
    fi
	conda activate seqkit
    seqkit stats "${FORWARD[@]}" "$OUT_R1"
    seqkit stats "${REVERSE[@]}" "$OUT_R2"
done

echo "Merging complete."
