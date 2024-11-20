# Load the configuration file
configfile: "config.yaml"

rule genomad_end_to_end:
    input:
        contigs=f"{config['output_dir']}/{{sample}}_assembly/contigs.fasta"
    output:
        genomad_out_dir=directory(f"{config['output_dir']}/{{sample}}_genomad")
    singularity: "/opt/containers/genomad/genomad_1.8.0.sif" 
    threads: config["max_threads"]
    shell:
        """
        genomad end-to-end --enable-score-calibration --cleanup --splits 8 {input.contigs} {output.genomad_out_dir} /mnt/data/genomad_db_v1.7
        """
