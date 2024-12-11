# Load the configuration file
configfile: "config.yaml"

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
if config["sub_analyses"].get("mags", False):
    include: "mags.smk"
if config["sub_analyses"].get("kaiju", False):
    include: "kaiju.smk"
if config["sub_analyses"].get("tpm", False):
    include: "tpm.smk"
if config["sub_analyses"].get("viruses", False):
    include: "viruses.smk"
if config["sub_analyses"].get("bgc", False):
    include: "bgc.smk"
if config["sub_analyses"].get("diversity", False):
    include: "diversity.smk"
if config["sub_analyses"].get("metabolic", False):
    include: "metabolic.smk"

# Rule to combine all final outputs from each sub-analysis
rule all:
	input:
		# Outputs for "assemble"
		expand(f"{OUTPUT_DIR}/{{sample}}_forward_paired.fq", sample=SAMPLES),
		expand(f"{OUTPUT_DIR}/{{sample}}_reverse_paired.fq", sample=SAMPLES),
		expand(f"{OUTPUT_DIR}/{{sample}}_fastqc/", sample=SAMPLES),
		expand(f"{OUTPUT_DIR}/{{sample}}_assembly/contigs.fasta", sample=SAMPLES)if config["sub_analyses"].get("assemble", False) else [],
		expand(f"{OUTPUT_DIR}/{{sample}}_assembly/contigs.fasta", sample=SAMPLES) if config["sub_analyses"].get("assemble_megahit", False) else [],
		expand(f"{OUTPUT_DIR}/{{sample}}_prokka/{{sample}}_annotated.gff", sample=SAMPLES),
		expand(f"{OUTPUT_DIR}/{{sample}}_prokka/{{sample}}_annotated.tsv", sample=SAMPLES),
		expand(f"{OUTPUT_DIR}/{{sample}}_prokka/{{sample}}_annotated.faa", sample=SAMPLES), 
		expand(f"{OUTPUT_DIR}/{{sample}}_quast_report", sample=SAMPLES),
		# Outputs for "mags"
		expand(f"{OUTPUT_DIR}/{{sample}}_mags_bins/concoct_bins", sample=SAMPLES) if config["sub_analyses"].get("mags", False) else [],
		expand(f"{OUTPUT_DIR}/{{sample}}_mags_bins/maxbin2_bins", sample=SAMPLES) if config["sub_analyses"].get("mags", False) else [],
		expand(f"{OUTPUT_DIR}/{{sample}}_mags_bins/metabat2_bins", sample=SAMPLES) if config["sub_analyses"].get("mags", False) else [],
		expand(f"{OUTPUT_DIR}/{{sample}}_refined_mag_directory", sample=SAMPLES) if config["sub_analyses"].get("mags", False) else [],
		expand(f"{OUTPUT_DIR}/{{sample}}_gtdbtk_temporary_directory", sample=SAMPLES) if config["sub_analyses"].get("mags", False) else [],
		expand(f"{OUTPUT_DIR}/{{sample}}_gtdbtk", sample=SAMPLES) if config["sub_analyses"].get("mags", False) else [],
		expand(f"{OUTPUT_DIR}/{{sample}}_coverm_coverage.tsv", sample=SAMPLES) if config["sub_analyses"].get("mags", False) else [],
		#kaiju
		expand(f"{config['output_dir']}/{{sample}}_CLASS_kaiju.table", sample=config["samples"]) if config["sub_analyses"].get("kaiju", False) else [],
	        expand(f"{config['output_dir']}/{{sample}}_GENUS_kaiju.table", sample=config["samples"]) if config["sub_analyses"].get("kaiju", False) else [],
		#tpm
		expand(f"{OUTPUT_DIR}/{{sample}}_tpm/{{sample}}_tpm_annotated.txt", sample=SAMPLES) if config["sub_analyses"].get("tpm", False) else [],
		expand(f"{OUTPUT_DIR}/{{sample}}_tpm/{{sample}}_kofam_tpm_summary.txt", sample=SAMPLES) if config["sub_analyses"].get("tpm", False) else [],
		#viruses
		expand(f"{OUTPUT_DIR}/{{sample}}_genomad/", sample=SAMPLES) if config["sub_analyses"].get("viruses", False) else [],
		#BGC
		expand(f"{OUTPUT_DIR}/{{sample}}_antismash/knownclusterblastoutput.txt", sample=SAMPLES) if config["sub_analyses"].get("bgc", False) else [],
                #Diversity
		expand(f"{config['output_dir']}/{{sample}}_diversity/{{sample}}_alignment.npo", sample=config["samples"]) if config["sub_analyses"].get("diversity", False) else [],
		#Metabolic
		expand(f"{OUTPUT_DIR}/{{sample}}_metabolic", sample=SAMPLES) if config["sub_analyses"].get("metabolic", False) else [],
