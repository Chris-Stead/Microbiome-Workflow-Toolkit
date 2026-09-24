#Snakemake module for multiqc reports

SAMPLES = config["samples"]
OUTPUT_DIR = config["output_dir"]
CONTAINERS_DIR = config["containers_dir"]

# Determine which QC results should exist
ASSEMBLY_ENABLED = config["sub_analyses"].get("assemble", False) or config["sub_analyses"].get("assemble_megahit", False)
FASTQC_DIRS = (
    [f"{OUTPUT_DIR}/{sample}_fastqc/" for sample in SAMPLES] if ASSEMBLY_ENABLED else []
)
QUAST_DIRS = (
    [f"{OUTPUT_DIR}/{sample}_quast_report" for sample in SAMPLES] if ASSEMBLY_ENABLED else []
)

rule multiqc_report:
    input:
        fastqc=FASTQC_DIRS,
        quast=QUAST_DIRS
    output:
        report_data=directory(f"{OUTPUT_DIR}/multiqc_data")
    threads: 10
    singularity: f"{CONTAINERS_DIR}/multiqc/multiqc_1.9--pyh9f0ad1d_0"
    benchmark: f"{config['benchmark_dir']}/qc_report_multiqc_report_{{sample}}.tsv"
    shell:
        """
        multiqc {OUTPUT_DIR} --outdir {output.report_data} --filename multiqc_data
        """
