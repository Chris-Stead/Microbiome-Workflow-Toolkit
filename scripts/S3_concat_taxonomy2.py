import pandas as pd
from Bio import SeqIO
import sys
import os
# Define file paths
blast_file = snakemake.input.blast_list_sorted_bitscore_csv  # Your BLAST result file
fna_file = snakemake.input.nucleotide_seq                    # Your FASTA file with sequences
output_fasta = snakemake.output.annotated_s3_genes           # Output file

# --- Handle empty BLAST files gracefully ---
if os.stat(blast_file).st_size == 0:
    print(f"Warning: {blast_file} is empty. Writing empty FASTA output.")
    open(output_fasta, "w").close()
    sys.exit(0)

# Load BLAST results
df = pd.read_csv(blast_file, sep=",", header=None)

# Assign column names (now with qcovs added)
columns = [
    "taxon_ID", "S3_Gene", "percent_ID", "Alignment_Length", "Mismatch", "Gap",
    "Q_Start", "Q_End", "S_Start", "S_End", "E_value", "Bit_Score",
    "qlen", "slen", "qcovs", "Taxonomy", "strain"
]
df.columns = columns

# Keep top hit per S3 gene based on previous sorting
top_hits = df.groupby("S3_Gene").head(1)

# Create a dictionary of taxonomic annotations
fasta_entries = {}
for gene, group in top_hits.groupby("S3_Gene"):
    taxonomy_info = ";".join([
        f"{row['Taxonomy']}(%_homology={row['percent_ID']},BitScore={row['Bit_Score']},E_value={row['E_value']},qcovs={row['qcovs']})"
        for _, row in group.iterrows()
    ])
    fasta_entries[gene] = taxonomy_info

# Parse the sequences from the .fna file
sequences = {record.id: str(record.seq) for record in SeqIO.parse(fna_file, "fasta")}

# Write the new annotated FASTA file
with open(output_fasta, "w") as f:
    for gene, description in fasta_entries.items():
        sequence = sequences.get(gene, "NNNNN")  # Default to NNNNN if not found
        f.write(f">{gene} {description}\n{sequence}\n\n")

print(f"Annotated FASTA file generated: {output_fasta}")
