import sys
import pandas as pd
import re

# Inputs
tpm_file = sys.argv[1]
gtf_file = sys.argv[2]
sample_name = sys.argv[3]
output_file = sys.argv[4]

# Build gene_id → contig mapping from GTF
gene_to_contig = {}
with open(gtf_file) as gtf:
    for line in gtf:
        if line.startswith("#") or line.strip() == "":
            continue
        parts = line.strip().split("\t")
        if len(parts) < 9:
            continue
        contig = parts[0]
        match = re.search(r'gene_id "?([^";]+)"?', parts[8])
        if match:
            gene_id = match.group(1)
            if gene_id not in gene_to_contig:
                gene_to_contig[gene_id] = contig

# Load and modify TPM table
tpm_df = pd.read_csv(tpm_file, sep="\t")
tpm_df["gene_id"] = tpm_df["gene_id"].apply(
    lambda g: f"{gene_to_contig.get(g, 'UNKNOWN')}_{g}"
)

# Output
tpm_df.to_csv(output_file, sep="\t", index=False)

