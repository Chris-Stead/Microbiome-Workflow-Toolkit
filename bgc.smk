#Snakemake module for antismash

rule antismash:
    input:f"{config['output_dir']}/{{sample}}_contigs_filtered.fa"
    output:
        antismash_out_dir=directory(f"{config['output_dir']}/{{sample}}_antismash/"),
        knownclusterblast=f"{config['output_dir']}/{{sample}}_antismash/knownclusterblastoutput.txt"
    singularity: f"{config['containers_dir']}/antismash/antismash-6.1.1.sif"
    threads: config["max_threads"]
    benchmark: f"{config['benchmark_dir']}/bgc_antismash_{{sample}}.tsv"
    shell:
        """
        antismash --cpus {threads} \
                  --genefinding-tool prodigal \
                  --allow-long-headers \
                  --cb-knownclusters \
                  --output-dir {output.antismash_out_dir} \
                  {input}
        """
