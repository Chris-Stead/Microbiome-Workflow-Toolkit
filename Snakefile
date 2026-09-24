# Globals
SAMPLES = config["samples"]
OUTPUT_DIR = config["output_dir"]
CONTAINERS_DIR = config["containers_dir"]
MAX_THREADS = config["max_threads"]

# Conditional imports for each sub-analysis(DO NOT MODIFY)
if config["sub_analyses"].get("assemble", False):
    include: "workflow/rules/assemble.smk"
if config["sub_analyses"].get("assemble_megahit", False):
    include: "workflow/rules/assemble_megahit.smk"
#if config["sub_analyses"].get("assemble_megahit", False):
#    include: "workflow/rules/assemble_megahit_only.smk"
if config["sub_analyses"].get("mags", False):
    include: "workflow/rules/mags.smk"
if config["sub_analyses"].get("mags_euk", False):
    include: "workflow/rules/mags_euk.smk"
if config["sub_analyses"].get("kaiju", False):
    include: "workflow/rules/kaiju.smk"
if config["sub_analyses"].get("kaiju_only", False):
    include: "workflow/rules/kaiju_only.smk"
if config["sub_analyses"].get("tpm", False):
    include: "workflow/rules/tpm.smk"
if config["sub_analyses"].get("tpm_1", False):
    include: "workflow/rules/tpm_1.smk"
if config["sub_analyses"].get("tpm_high_diversity", False):
    include: "workflow/rules/tpm_high_diversity.smk"
if config["sub_analyses"].get("viruses", False):
    include: "workflow/rules/viruses.smk"
if config["sub_analyses"].get("bgc", False):
    include: "workflow/rules/bgc.smk"
if config["sub_analyses"].get("diversity", False):
    include: "workflow/rules/diversity.smk"
if config["sub_analyses"].get("metabolic", False):
    include: "workflow/rules/metabolic.smk"
if config["sub_analyses"].get("s3_abundance", False):
    include: "workflow/rules/s3_abundance3.smk"
if config["sub_analyses"].get("mobilome", False):
    include: "workflow/rules/mobilome.smk"
if config["sub_analyses"].get("qc_report", False):
    include: "workflow/rules/qc_report.smk"
# Rule to combine all final outputs from each sub-analysis
rule all:
        input:
                # Outputs for "assemble"
                expand(f"{OUTPUT_DIR}/{{sample}}_forward_paired.fq", sample=SAMPLES) if config["sub_analyses"].get("assemble", False) or config["sub_analyses"].get("assemble_megahit", False) else [],
                expand(f"{OUTPUT_DIR}/{{sample}}_reverse_paired.fq", sample=SAMPLES) if config["sub_analyses"].get("assemble", False) or config["sub_analyses"].get("assemble_megahit", False) else [],
                expand(f"{OUTPUT_DIR}/{{sample}}_fastqc/", sample=SAMPLES) if config["sub_analyses"].get("assemble", False) or config["sub_analyses"].get("assemble_megahit", False) else [],
                expand(f"{OUTPUT_DIR}/{{sample}}_assembly/contigs.fasta", sample=SAMPLES) if config["sub_analyses"].get("assemble", False) else [],
                expand(f"{OUTPUT_DIR}/{{sample}}_assembly/contigs.fasta", sample=SAMPLES) if config["sub_analyses"].get("assemble_megahit", False) else [],
                expand(f"{OUTPUT_DIR}/{{sample}}_quast_report", sample=SAMPLES) if config["sub_analyses"].get("assemble", False) or config["sub_analyses"].get("assemble_megahit", False) else [],
                # Outputs for "mags"
                expand(f"{OUTPUT_DIR}/{{sample}}_mags_bins/concoct_bins", sample=SAMPLES) if config["sub_analyses"].get("mags", False) else [],
                expand(f"{OUTPUT_DIR}/{{sample}}_mags_bins/maxbin2_bins", sample=SAMPLES) if config["sub_analyses"].get("mags", False) else [],
                expand(f"{OUTPUT_DIR}/{{sample}}_mags_bins/metabat2_bins", sample=SAMPLES) if config["sub_analyses"].get("mags", False) else [],
                expand(f"{OUTPUT_DIR}/{{sample}}_refined_mag_directory", sample=SAMPLES) if config["sub_analyses"].get("mags", False) else [],
                # Outputs for "mags"
                expand(f"{OUTPUT_DIR}/{{sample}}_coverm_coverage.tsv", sample=SAMPLES) if config["sub_analyses"].get("mags", False) else [],
		        #expand(f"{config['output_dir']}/{{sample}}_refined_mag_directory/provirus_in_bins", sample=config["samples"]) if config["sub_analyses"].get("mags", False) else [],
		        #expand(f"{config['output_dir']}/{{sample}}_refined_mag_directory/crispr_in_bins", sample=config["samples"]) if config["sub_analyses"].get("mags", False) else [],
		        # Outputs for "mags_euk"
                expand(f"{OUTPUT_DIR}/{{sample}}_eukaryotes/{{sample}}_cat_taxonomy_named.txt", sample=SAMPLES) if config["sub_analyses"].get("mags_euk", False) else [],
                #kaiju
                expand(f"{config['output_dir']}/{{sample}}_CLASS_kaiju.table", sample=config["samples"]) if config["sub_analyses"].get("kaiju", False) else [],
                expand(f"{config['output_dir']}/{{sample}}_GENUS_kaiju.table", sample=config["samples"]) if config["sub_analyses"].get("kaiju", False) else [],
                expand(f"{config['output_dir']}/{{sample}}_PHYLUM_kaiju.table", sample=config["samples"]) if config["sub_analyses"].get("kaiju", False) else [],
                expand(f"{config['output_dir']}/{{sample}}_FAMILY_kaiju.table", sample=config["samples"]) if config["sub_analyses"].get("kaiju", False) else [],
                expand(f"{config['output_dir']}/{{sample}}_kaiju.html", sample=config["samples"]) if config["sub_analyses"].get("kaiju", False) else [],
                #kaiju_only
                expand(f"{config['output_dir']}/{{sample}}_CLASS_kaiju.table", sample=config["samples"]) if config["sub_analyses"].get("kaiju_only", False) else [],
                expand(f"{config['output_dir']}/{{sample}}_GENUS_kaiju.table", sample=config["samples"]) if config["sub_analyses"].get("kaiju_only", False) else [],
                expand(f"{config['output_dir']}/{{sample}}_PHYLUM_kaiju.table", sample=config["samples"]) if config["sub_analyses"].get("kaiju_only", False) else [],
                expand(f"{config['output_dir']}/{{sample}}_FAMILY_kaiju.table", sample=config["samples"]) if config["sub_analyses"].get("kaiju_only", False) else [],
                expand(f"{config['output_dir']}/{{sample}}_kaiju.html", sample=config["samples"]) if config["sub_analyses"].get("kaiju_only", False) else [],
                #tpm
                expand(f"{OUTPUT_DIR}/{{sample}}_tpm/{{sample}}_tpm_annotated.txt", sample=SAMPLES) if config["sub_analyses"].get("tpm", False) else [],
                expand(f"{OUTPUT_DIR}/{{sample}}_tpm/{{sample}}_kofam_tpm_summary.txt", sample=SAMPLES) if config["sub_analyses"].get("tpm", False) else [],
                expand(f"{OUTPUT_DIR}/{{sample}}_tpm/{{sample}}_tpm_annotated.txt", sample=SAMPLES) if config["sub_analyses"].get("tpm_1", False) else [],
                expand(f"{OUTPUT_DIR}/{{sample}}_tpm/{{sample}}_kofam_tpm_summary.txt", sample=SAMPLES) if config["sub_analyses"].get("tpm_1", False) else [],
                #viruses
                expand(f"{OUTPUT_DIR}/{{sample}}_genomad/", sample=SAMPLES) if config["sub_analyses"].get("viruses", False) else [],
                #BGC
                expand(f"{OUTPUT_DIR}/{{sample}}_antismash/knownclusterblastoutput.txt", sample=SAMPLES) if config["sub_analyses"].get("bgc", False) else [],
                #Diversity
                expand(f"{config['output_dir']}/{{sample}}_diversity/{{sample}}_alignment.npo", sample=config["samples"]) if config["sub_analyses"].get("diversity", False) else [],
                #Metabolic
                expand(f"{OUTPUT_DIR}/{{sample}}_metabolic", sample=SAMPLES) if config["sub_analyses"].get("metabolic", False) else [],
		        #S3 abundance
                expand(f"{OUTPUT_DIR}/{{sample}}_S3/{{sample}}_S3_gene_abundance.tsv", sample=SAMPLES) if config["sub_analyses"].get("s3_abundance", False) else [],
		        #mobilome
                expand(f"{OUTPUT_DIR}/{{sample}}_mobilome/{{sample}}_mobilome_relative_abundance.tsv", sample=SAMPLES) if config["sub_analyses"].get("mobilome", False) else [],