#Snakemake module for genomad

rule genomad_end_to_end:
    input:
        contigs=f"{config['output_dir']}/{{sample}}_contigs_filtered.fa"
    output:
        genomad_out_dir=directory(f"{config['output_dir']}/{{sample}}_genomad")
    #singularity:f"{config['containers_dir']}/genomad/genomad_1.8.0.sif"
    threads: 5
    benchmark: f"{config['benchmark_dir']}/virus_genomad_end_to_end_{{sample}}.tsv"
    shell:
        """
        singularity exec /mnt/seaes01-data01/nixon-microbiome/containers/genomad/genomad-1.8.0_EC_build.sif \
        genomad end-to-end --enable-score-calibration --cleanup --splits 8 {input.contigs} {output.genomad_out_dir} /mnt/data/genomad_db_v1.7
        """
