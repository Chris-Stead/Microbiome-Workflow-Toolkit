#!/usr/bin/env python3
# -*- coding: utf-8 -*-
import pandas as pd

# Load TSV file from Snakemake input
df = pd.read_csv(snakemake.input.genomad_out_file, sep="\t")

# Function to classify rows based on score thresholds
def classify_row(row):
    labels = []
    
    if row["chromosome_score"] > 0.8:
        labels.append("chromosome")
    if row["plasmid_score"] > 0.8:
        labels.append("plasmid")
    if row["virus_score"] > 0.8:
        labels.append("virus")

    if len(labels) > 1:
        return "unknown_b"  # Multiple classifications
    elif len(labels) == 1:
        return labels[0]  # Single classification
    else:
        return "unknown_a"  # No valid classification

# Apply classification function to dataframe
df["classification"] = df.apply(classify_row, axis=1)

# Snakemake output paths
output_files = {
    "chromosome": snakemake.output.chromosome_list,
    "plasmid": snakemake.output.plasmid_list,
    "virus": snakemake.output.virus_list,
    "unknown_a": snakemake.output.unknown_a_list,
}

# Create empty files for each classification first
for category, filepath in output_files.items():
    with open(filepath, "w") as file:
        file.write("")  # Ensures the file exists

# Group sequences by classification and write data
for category, filepath in output_files.items():
    seq_list = df[df["classification"] == category]["seq_name"].tolist()

    # Write sequences to respective files
    with open(filepath, "w") as file:
        file.write("\n".join(seq_list))
