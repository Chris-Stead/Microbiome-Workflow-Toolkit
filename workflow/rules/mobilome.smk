#Snakemake module for annotating and pooling mobile from non mobile genetic elements

rule mobilome_genomad:
    input:
        contigs=f"{config['output_dir']}/{{sample}}_contigs_filtered.fa"
    output:
        genomad_out_dir=directory(f"{config['output_dir']}/{{sample}}_genomad"),
        genomad_out_file=f"{config['output_dir']}/{{sample}}_genomad/{{sample}}_contigs_filtered_score_calibration/{{sample}}_contigs_filtered_calibrated_aggregated_classification.tsv"
    #singularity:f"{config['containers_dir']}/genomad/genomad_1.8.0.sif"
    threads: 10
    benchmark: f"{config['benchmark_dir']}/mobilome_genomad_end_to_end_{{sample}}.tsv"
    shell:
        """
        singularity exec /mnt/seaes01-data01/nixon-microbiome/containers/genomad/genomad-1.8.0_EC_build.sif \
        genomad end-to-end --enable-score-calibration --conservative --cleanup --splits 8 {input.contigs} {output.genomad_out_dir} /mnt/data/genomad_db_v1.7
        """

rule categorise_contigs:
    input:
        genomad_out_file=f"{config['output_dir']}/{{sample}}_genomad/{{sample}}_contigs_filtered_score_calibration/{{sample}}_contigs_filtered_calibrated_aggregated_classification.tsv"
    output:
        chromosome_list=f"{config['output_dir']}/{{sample}}_mobilome/chromosome_sequences.tsv",
        virus_list=f"{config['output_dir']}/{{sample}}_mobilome/virus_sequences.tsv",
        plasmid_list=f"{config['output_dir']}/{{sample}}_mobilome/plasmid_sequences.tsv",
        unknown_a_list=f"{config['output_dir']}/{{sample}}_mobilome/unknown_a_sequences.tsv"
    threads: 1
    conda: '../../conda_envs/bioconda_environment.yml'
    benchmark: f"{config['benchmark_dir']}/mobilome_categorise_contigs_{{sample}}.tsv"
    script: '../../scripts/genomad_classify1.py'

rule pools:
    input:
        contigs=f"{config['output_dir']}/{{sample}}_contigs_filtered.fa",
        chromosome_list=f"{config['output_dir']}/{{sample}}_mobilome/chromosome_sequences.tsv",
        virus_list=f"{config['output_dir']}/{{sample}}_mobilome/virus_sequences.tsv",
        plasmid_list=f"{config['output_dir']}/{{sample}}_mobilome/plasmid_sequences.tsv",
        unknown_a_list=f"{config['output_dir']}/{{sample}}_mobilome/unknown_a_sequences.tsv"
    output:
        chromosome_seqs=f"{config['output_dir']}/{{sample}}_mobilome/chromosome_sequences.fasta",
        virus_seqs=f"{config['output_dir']}/{{sample}}_mobilome/virus_sequences.fasta",
        plasmid_seqs=f"{config['output_dir']}/{{sample}}_mobilome/plasmid_sequences.fasta",
        unknown_a_seqs=f"{config['output_dir']}/{{sample}}_mobilome/unknown_a_sequences.fasta"
    threads: 5
    singularity: f"{config['containers_dir']}/seqkit/seqkit_2.9.0--h9ee0642_0"
    benchmark: f"{config['benchmark_dir']}/mobilome_pools_{{sample}}.tsv"
    shell: 
        """
        seqkit grep -f {input.chromosome_list} {input.contigs} > {output.chromosome_seqs}
        seqkit grep -f {input.virus_list} {input.contigs} > {output.virus_seqs}
        seqkit grep -f {input.plasmid_list} {input.contigs} > {output.plasmid_seqs}
        seqkit grep -f {input.unknown_a_list} {input.contigs} > {output.unknown_a_seqs}
        """

rule mobilome_map:
    input:
        forward_paired=f"{config['output_dir']}/{{sample}}_forward_paired.fq",
        rev_paired=f"{config['output_dir']}/{{sample}}_reverse_paired.fq",
        chromosome_seqs=f"{config['output_dir']}/{{sample}}_mobilome/chromosome_sequences.fasta",
        virus_seqs=f"{config['output_dir']}/{{sample}}_mobilome/virus_sequences.fasta",
        plasmid_seqs=f"{config['output_dir']}/{{sample}}_mobilome/plasmid_sequences.fasta",
        unknown_a_seqs=f"{config['output_dir']}/{{sample}}_mobilome/unknown_a_sequences.fasta"
    output:
        mobilome_rel_abundance=f"{config['output_dir']}/{{sample}}_mobilome/{{sample}}_mobilome_relative_abundance.tsv"
    threads: 5
    singularity: f"{config['containers_dir']}/coverm/coverm_0.7.0--hb4818e0_2"
    benchmark: f"{config['benchmark_dir']}/mobilome_mobilome_map_{{sample}}.tsv"
    shell:
        """
        coverm genome  -t {threads} -1 {input.forward_paired} -2 {input.rev_paired} --genome-fasta-files {input.chromosome_seqs} {input.virus_seqs} {input.plasmid_seqs} {input.unknown_a_seqs} -m tpm -o {output.mobilome_rel_abundance}        
        """
