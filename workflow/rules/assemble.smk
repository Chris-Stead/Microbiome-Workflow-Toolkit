#Snakemake module for assembly with spades

# Assemble sub-workflow
rule trimmomatic:
    input:
        forward=f"{config['data_dir']}/{{sample}}_1.fastq.gz",
        rev=f"{config['data_dir']}/{{sample}}_2.fastq.gz"
    output:
        forward_paired=f"{config['output_dir']}/{{sample}}_forward_paired.fq",
        forward_unpaired=f"{config['output_dir']}/{{sample}}_forward_unpaired.fq",
        reverse_paired=f"{config['output_dir']}/{{sample}}_reverse_paired.fq",
        reverse_unpaired=f"{config['output_dir']}/{{sample}}_reverse_unpaired.fq"
    log:
        trimmomatic_log=f"{config['output_dir']}/{{sample}}_trimmomatic.log"
    singularity: f"{config['containers_dir']}/trimmomatic/trimmomatic-0.39.sif"
    threads: config["max_threads"]
    benchmark: f"{config['benchmark_dir']}/assemble_trimmomatic_{{sample}}.tsv"
    shell:
        "java -jar /trimmomatic/Trimmomatic-0.39/trimmomatic-0.39.jar PE -phred33 -threads {threads} {input.forward} {input.rev} {output.forward_paired} {output.forward_unpaired} {output.reverse_paired} {output.reverse_unpaired} ILLUMINACLIP:/mnt/seaes01-data01/nixon-microbiome/shared/bioinformatic_toolkit/trimmomatic_adapters/Nextera_Truseq_Adapters:2:30:10 LEADING:30 TRAILING:30 SLIDINGWINDOW:4:15 MINLEN:36"

rule fastqc:
    input:
        forward=f"{config['output_dir']}/{{sample}}_forward_paired.fq",
        rev=f"{config['output_dir']}/{{sample}}_reverse_paired.fq"
    output:
        fastqc_dir=directory(f"{config['output_dir']}/{{sample}}_fastqc/")
    singularity: f"{config['containers_dir']}/fastqc/fastqc-0.11.9.sif"
    threads: config["max_threads"]
    benchmark: f"{config['benchmark_dir']}/assemble_fastqc_{{sample}}.tsv"
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
        contig=f"{config['output_dir']}/{{sample}}_assembly/contigs.fasta"
    threads: config["max_threads"]
    singularity: f"{config['containers_dir']}/spades/spades-3.15.5.sif"
    benchmark: f"{config['benchmark_dir']}/assemble_spades_{{sample}}.tsv"
    shell:
        """
        metaspades.py -m 2000 -1 {input.forward} -2 {input.rev} -o {output.o} -t {threads}
        """
        
#cut contig names to avoid errors with prokka
rule cut: 
    input: 
        contig=f"{config['output_dir']}/{{sample}}_assembly/contigs.fasta"
    output: f"{config['output_dir']}/{{sample}}_contigs_IDs_trimmed.fasta"
    threads: config["max_threads"] 
    benchmark: f"{config['benchmark_dir']}/assemble_cut_{{sample}}.tsv"
    shell: "cut -d 'l' -f1 {input.contig} > {output}"

#choose only contigs over ? bp
rule filter_seq_contigs:
    input: f"{config['output_dir']}/{{sample}}_contigs_IDs_trimmed.fasta"
    output: f"{config['output_dir']}/{{sample}}_contigs_filtered.fa"
    threads: config["max_threads"]
    benchmark: f"{config['benchmark_dir']}/assemble_filter_seq_contigs_{{sample}}.tsv"
    params:
        minlen = config["min_contig_len"]
    shell: 'python /mnt/seaes01-data01/nixon-microbiome/shared/scripts/pullseq_python3.py -i {input} -o {output} -m {params.minlen}'
        
rule metaquast:
    input:f"{config['output_dir']}/{{sample}}_assembly/contigs.fasta"
    output:
        quast_report=directory(f"{config['output_dir']}/{{sample}}_quast_report")
    singularity: f"{config['containers_dir']}/quast/quast-5.2.0.sif"
    threads: config["max_threads"]
    log: f"{config['output_dir']}/{{sample}}_quast.log"
    benchmark: f"{config['benchmark_dir']}/assemble_metaquast_{{sample}}.tsv"
    shell:
        """
        metaquast.py --threads {threads} --max-ref-number 0 -o {output.quast_report} {input}
        """
