# Load the configuration file
configfile: "config.yaml"

# Assemble sub-workflow
rule trimmomatic:
    input:
        forward=f"{config['data_dir']}/{{sample}}_1.fastq",
        rev=f"{config['data_dir']}/{{sample}}_2.fastq"
    output:
        forward_paired=f"{config['output_dir']}/{{sample}}_forward_paired.fq",
        forward_unpaired=f"{config['output_dir']}/{{sample}}_forward_unpaired.fq",
        reverse_paired=f"{config['output_dir']}/{{sample}}_reverse_paired.fq",
        reverse_unpaired=f"{config['output_dir']}/{{sample}}_reverse_unpaired.fq"
    log:
        trimmomatic_log=f"{config['output_dir']}/{{sample}}_trimmomatic.log"
    singularity: f"{config['containers_dir']}/trimmomatic/trimmomatic-0.39.sif"
    threads: config["max_threads"]
    shell:
        "java -jar /trimmomatic/Trimmomatic-0.39/trimmomatic-0.39.jar PE -phred33 -threads {threads} {input.forward} {input.rev} {output.forward_paired} {output.forward_unpaired} {output.reverse_paired} {output.reverse_unpaired} ILLUMINACLIP:/trimmomatic/Trimmomatic-0.39/adapters/TruSeq3-PE.fa:2:30:10 LEADING:30 TRAILING:30 SLIDINGWINDOW:4:15 MINLEN:36"

rule fastqc:
    input:
        forward=f"{config['output_dir']}/{{sample}}_forward_paired.fq",
        rev=f"{config['output_dir']}/{{sample}}_reverse_paired.fq"
    output:
        fastqc_dir=directory(f"{config['output_dir']}/{{sample}}_fastqc/")
    singularity: f"{config['containers_dir']}/fastqc/fastqc-0.11.9.sif"
    threads: config["max_threads"]
    shell:
        """
        mkdir {output.fastqc_dir}
        fastqc -o {output.fastqc_dir} {input.forward} -t {threads} {input.rev}
        """

rule spades:
    input:
        forward=f"{config['output_dir']}/{{sample}}_forward_paired.fq",
        rev=f"{config['output_dir']}/{{sample}}_reverse_paired.fq"
    output:
        o=directory(f"{config['output_dir']}/{{sample}}_assembly"),
        contigs=f"{config['output_dir']}/{{sample}}_assembly/contigs.fasta"
    threads: config["max_threads"]
    singularity: f"{config['containers_dir']}/spades/spades-3.15.5.sif"
    shell:
        """
        metaspades.py -m 2000 -1 {input.forward} -2 {input.rev} -o {output.o} -t {threads}
        """

rule metaquast:
    input:
        contigs=f"{config['output_dir']}/{{sample}}_assembly/contigs.fasta"
    output:
        quast_report=directory(f"{config['output_dir']}/{{sample}}_quast_report")
    singularity: f"{config['containers_dir']}/quast/quast-5.2.0.sif"
    threads: config["max_threads"]
    shell:
        """
        metaquast.py --threads {threads} -o {output.quast_report} {input.contigs}
        """

rule prokka:
    input:
        contigs=f"{config['output_dir']}/{{sample}}_assembly/contigs.fasta"
    output:
        gff=f"{config['output_dir']}/{{sample}}_prokka/{{sample}}_annotated.gff",
        tsv=f"{config['output_dir']}/{{sample}}_prokka/{{sample}}_annotated.tsv",
        faa=f"{config['output_dir']}/{{sample}}_prokka/{{sample}}_annotated.faa"
    singularity: f"{config['containers_dir']}/prokka/prokka-1.14.6.sif"
    threads: config["max_threads"]
    shell:
        """
        prokka --outdir {wildcards.sample}_prokka \
               --prefix {wildcards.sample}_annotated \
               --force --centre X --compliant --cpus {threads} --metagenome {input.contigs}
        """

