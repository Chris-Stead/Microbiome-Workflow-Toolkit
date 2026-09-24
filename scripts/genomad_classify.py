#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Wed Mar  5 10:16:01 2025

@author: mqbpqcs2
"""

import pandas as pd

# Load TSV file
#df = pd.read_csv("TalikLake_DNA_contigs_filtered_calibrated_aggregated_classification.tsv", sep='\t')
df = snakemake.input.genomad_classification

# Function to classify rows based on score thresholds
def classify_row(row):
    labels = []
    
    if row["chromosome_score"] > 0.7:
        labels.append("chromosome")
    if row["plasmid_score"] > 0.7:
        labels.append("plasmid")
    if row["virus_score"] > 0.7:
        labels.append("virus")

    if len(labels) > 1:
        return "unknown_b"  # Multiple classifications
    elif len(labels) == 1:
        return labels[0]  # Single classification
    else:
        return "unknown_a"  # No valid classification

# Apply classification function to dataframe
df["classification"] = df.apply(classify_row, axis=1)

# List of all possible classifications
classification_types = ["chromosome", "plasmid", "virus", "unknown_a", "unknown_b"]

# Create empty files for each classification first
for category in classification_types:
    open(f"{category}_sequences.tsv", "w").close()  # Ensures file exists, even if empty

# Group sequences by classification and write data
for category in classification_types:
    seq_list = df[df["classification"] == category]["seq_name"].tolist()

    # Write sequences to respective files (empty files are already created)
    with open(f"{category}_sequences.tsv", "w") as file:
        file.write("\n".join(seq_list))
