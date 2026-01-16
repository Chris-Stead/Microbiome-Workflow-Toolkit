import sys
import re

gtf_file = sys.argv[1]
files_to_fix = sys.argv[2:]

# Step 1: Build gene_id → contig/bin mapping from GTF
gene_to_bin = {}

with open(gtf_file) as gtf:
    for line in gtf:
        if line.startswith("#") or line.strip() == "":
            continue
        parts = line.strip().split("\t")
        if len(parts) < 9:
            continue
        contig = parts[0]
        attr = parts[8]
        match = re.search(r'gene_id "?([^";]+)"?', attr)
        if match:
            gene_id = match.group(1)
            gene_to_bin[gene_id] = contig

# Step 2: Fix each Prokka output file
for file in files_to_fix:
    output = file + ".renamed"
    with open(file, "r") as fin, open(output, "w") as fout:
        if file.endswith((".faa", ".ffn")):
            for line in fin:
                if line.startswith(">"):
                    parts = line.strip().split(" ", 1)
                    gene_id = parts[0][1:]  # Remove ">"
                    desc = parts[1] if len(parts) > 1 else ""
                    contig = gene_to_bin.get(gene_id, "UNKNOWN")
                    fout.write(f">{contig}_{gene_id} {desc}\n")
                else:
                    fout.write(line)

        elif file.endswith(".gff"):
            for line in fin:
                if line.startswith("#"):
                    fout.write(line)
                    continue
                fields = line.strip().split("\t")
                if len(fields) < 9:
                    fout.write(line)
                    continue
                attributes = fields[8]
                match = re.search(r'locus_tag=([^;]+)', attributes)
                if match:
                    gene_id = match.group(1)
                    contig = gene_to_bin.get(gene_id, fields[0])
                    new_tag = f"{contig}_{gene_id}"
                    attributes = re.sub(r'locus_tag=[^;]+', f'locus_tag={new_tag}', attributes)
                    attributes = re.sub(r'ID=[^;]+', f'ID={new_tag}', attributes)
                    fields[8] = attributes
                fout.write("\t".join(fields) + "\n")

        elif file.endswith(".tsv"):
            lines = fin.readlines()
            if not lines:
                continue  # skip empty file
            header = lines[0].strip().split("\t")
            if header[0] != "locus_tag":
                header[0] = "locus_tag"
            fout.write("\t".join(header) + "\n")

            for line in lines[1:]:
                fields = line.strip().split("\t")
                if not fields or len(fields) < 1:
                    continue
                gene_id = fields[0]
                contig = gene_to_bin.get(gene_id, "UNKNOWN")
                fields[0] = f"{contig}_{gene_id}"
                fout.write("\t".join(fields) + "\n")
