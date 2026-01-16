import pandas as pd

# Inputs from Snakemake
blast_file = snakemake.input.blast_list_sorted
taxonomy_file = snakemake.input.taxonomy_file
output_file = snakemake.output.blast_list_sorted_matched

# Define column names (assuming you're using the expanded BLAST outfmt we designed)
blast_cols = [
    "taxon_ID", "S3_Gene", "percent_ID", "Alignment_Length", "Mismatch", "Gap",
    "Q_Start", "Q_End", "S_Start", "S_End", "E_value", "Bit_Score",
    "qlen", "slen", "qcovs"
]

# Load BLAST results, force all columns to string
blast = pd.read_csv(blast_file, sep=r"\s+", names=blast_cols, dtype=str)

# Load taxonomy file, force all columns to string
taxonomy = pd.read_csv(taxonomy_file, sep="\t", names=["taxon_ID", "Taxonomy", "strain"], dtype=str)

# Merge (left join keeps all BLAST hits, even unmatched ones)
merged = pd.merge(blast, taxonomy, how="left", on="taxon_ID")

# Fill missing taxonomy with placeholder
merged['Taxonomy'].fillna('Unclassified', inplace=True)
merged['strain'].fillna('NA', inplace=True)

# Output as space-delimited file (to match your downstream pipeline format)
merged.to_csv(output_file, sep=" ", header=False, index=False)

print(f"Merged BLAST + Taxonomy written to: {output_file}")

