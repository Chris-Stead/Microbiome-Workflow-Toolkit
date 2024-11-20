# Load the configuration file
configfile: "config.yaml"

rule antismash:
    input:
        contigs=f"{config['output_dir']}/{{sample}}_assembly/contigs.fasta"
    output:
        antismash_out_dir=directory(f"{config['output_dir']}/{{sample}}_antismash/"),
        knownclusterblast=f"{config['output_dir']}/{{sample}}_antismash/knownclusterblastoutput.txt"
    singularity: "/mnt/seaes01-data01/nixon-microbiome/containers/antismash/antismash-6.1.1.sif"
    threads: config["max_threads"]
    shell:
        """
        antismash --cpus {threads} \
                  --genefinding-tool prodigal \
                  --allow-long-headers \
                  --cb-knownclusters \
                  --output-dir {output.antismash_out_dir} \
                  {input.contigs}
        """
