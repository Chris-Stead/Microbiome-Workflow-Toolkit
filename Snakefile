# Load the configuration file
#configfile: "config.yaml"
# Globals
SAMPLES = config["samples"]
OUTPUT_DIR = config["output_dir"]
CONTAINERS_DIR = config["containers_dir"]
MAX_THREADS = config["max_threads"]

# Conditional imports for each sub-analysis(DO NOT MODIFY)
if config["sub_analyses"].get("assemble", False):
    include: "assemble.smk"
if config["sub_analyses"].get("assemble_megahit", False):
    include: "assemble_megahit.smk"
#if config["sub_analyses"].get("assemble_megahit", False):
#    include: "assemble_megahit_only.smk"
if config["sub_analyses"].get("mags", False):
    include: "mags.smk"
if config["sub_analyses"].get("kaiju", False):
    include: "kaiju.smk"
if config["sub_analyses"].get("kaiju_only", False):
    include: "kaiju_only.smk"
if config["sub_analyses"].get("tpm", False):
    include: "tpm.smk"
if config["sub_analyses"].get("tpm_1", False):
    include: "tpm_1.smk"
if config["sub_analyses"].get("tpm_high_diversity", False):
    include: "tpm_high_diversity.smk"
if config["sub_analyses"].get("viruses", False):
    include: "viruses.smk"
if config["sub_analyses"].get("bgc", False):
    include: "bgc.smk"
if config["sub_analyses"].get("diversity", False):
    include: "diversity.smk"
if config["sub_analyses"].get("metabolic", False):
    include: "metabolic.smk"
if config["sub_analyses"].get("s3_abundance", False):
    include: "s3_abundance3.smk"
if config["sub_analyses"].get("mobilome", False):
    include: "mobilome.smk"
if config["sub_analyses"].get("qc_report", False):
    include: "qc_report.smk"
# Rule to combine all final outputs from each sub-analysis
rule all:
        input:
                # Outputs for "assemble"
                expand(f"{OUTPUT_DIR}/{{sample}}_forward_paired.fq", sample=SAMPLES) if config["sub_analyses"].get("assemble", False) or config["sub_analyses"].get("assemble_megahit", False) else [],
                expand(f"{OUTPUT_DIR}/{{sample}}_reverse_paired.fq", sample=SAMPLES) if config["sub_analyses"].get("assemble", False) or config["sub_analyses"].get("assemble_megahit", False) else [],
                expand(f"{OUTPUT_DIR}/{{sample}}_fastqc/", sample=SAMPLES) if config["sub_analyses"].get("assemble", False) or config["sub_analyses"].get("assemble_megahit", False) else [],
                expand(f"{OUTPUT_DIR}/{{sample}}_assembly/contigs.fasta", sample=SAMPLES) if config["sub_analyses"].get("assemble", False) else [],
                expand(f"{OUTPUT_DIR}/{{sample}}_assembly/contigs.fasta", sample=SAMPLES) if config["sub_analyses"].get("assemble_megahit", False) else [],
		        #expand(f"{OUTPUT_DIR}/{{sample}}_assembly/contigs.fasta", sample=SAMPLES) if config["sub_analyses"].get("assemble_megahit_only", False) else [],
                #expand(f"{OUTPUT_DIR}/{{sample}}_prokka/{{sample}}_annotated.gff", sample=SAMPLES) if config["sub_analyses"].get("assemble", False) or config["sub_analyses"].get("assemble_megahit", False) else [],
                #expand(f"{OUTPUT_DIR}/{{sample}}_prokka/{{sample}}_annotated.tsv", sample=SAMPLES) if config["sub_analyses"].get("assemble", False) or config["sub_analyses"].get("assemble_megahit", False) else [],
                #expand(f"{OUTPUT_DIR}/{{sample}}_prokka/{{sample}}_annotated.faa", sample=SAMPLES) if config["sub_analyses"].get("assemble", False) or config["sub_analyses"].get("assemble_megahit", False) else [],
                expand(f"{OUTPUT_DIR}/{{sample}}_quast_report", sample=SAMPLES) if config["sub_analyses"].get("assemble", False) or config["sub_analyses"].get("assemble_megahit", False) else [],
                # Outputs for "mags"
                expand(f"{OUTPUT_DIR}/{{sample}}_mags_bins/concoct_bins", sample=SAMPLES) if config["sub_analyses"].get("mags", False) else [],
                expand(f"{OUTPUT_DIR}/{{sample}}_mags_bins/maxbin2_bins", sample=SAMPLES) if config["sub_analyses"].get("mags", False) else [],
                expand(f"{OUTPUT_DIR}/{{sample}}_mags_bins/metabat2_bins", sample=SAMPLES) if config["sub_analyses"].get("mags", False) else [],
                expand(f"{OUTPUT_DIR}/{{sample}}_refined_mag_directory", sample=SAMPLES) if config["sub_analyses"].get("mags", False) else [],
                #expand(f"{OUTPUT_DIR}/{{sample}}_gtdbtk_temporary_directory", sample=SAMPLES) if config["sub_analyses"].get("mags", False) else [],
                #expand(f"{OUTPUT_DIR}/{{sample}}_gtdbtk", sample=SAMPLES) if config["sub_analyses"].get("mags", False) else [],
                #expand(f"{OUTPUT_DIR}/{{sample}}_gtdbtk/gtdbtk.ar53.summary.tsv", sample=SAMPLES) if config["sub_analyses"].get("mags", False) else [],
                #expand(f"{OUTPUT_DIR}/{{sample}}_gtdbtk/gtdbtk.bac120.summary.tsv", sample=SAMPLES) if config["sub_analyses"].get("mags", False) else [],
                expand(f"{OUTPUT_DIR}/{{sample}}_coverm_coverage.tsv", sample=SAMPLES) if config["sub_analyses"].get("mags", False) else [],
		        #expand(f"{config['output_dir']}/{{sample}}_refined_mag_directory/provirus_in_bins", sample=config["samples"]) if config["sub_analyses"].get("mags", False) else [],
		        #expand(f"{config['output_dir']}/{{sample}}_refined_mag_directory/crispr_in_bins", sample=config["samples"]) if config["sub_analyses"].get("mags", False) else [],
		        # Dynamically gather bin outputs from bin refinement
	            #lambda wildcards: glob.glob(f"{config['output_dir']}/{wildcards.sample}_refined_mag_directory/metawrap_70_10_bins/*.fa"), 
		        # Provirus and CRISPR results (dynamically collected per sample)
		        #lambda wildcards: glob.glob(f"{config['output_dir']}/{wildcards.sample}_refined_mag_directory/provirus_in_bins/{wildcards.sample}_provirus/*.fa"),
		        #lambda wildcards: glob.glob(f"{config['output_dir']}/{wildcards.sample}_refined_mag_directory/crispr_in_bins/{wildcards.sample}_crispr/*.gff"),
		        #lambda wildcards: glob.glob(f"{config['output_dir']}/{wildcards.sample}_refined_mag_directory/crispr_in_bins/{wildcards.sample}_crispr/*.txt"),
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
                #qc report
                #expand(f"{OUTPUT_DIR}/reports/qc/multiqc_report.html", sample=SAMPLES) if config["sub_analyses"].get("qc_report", False) else [],
