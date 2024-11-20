# Load the configuration file
configfile: "config.yaml"

# kaiju.smk

rule kaiju_refseq:
    input:
        forward_paired=f"{config['output_dir']}/{{sample}}_forward_paired.fq",
        reverse_paired=f"{config['output_dir']}/{{sample}}_reverse_paired.fq"
    output:
        refseq=f"{config['output_dir']}/{{sample}}_kaiju_refseq"
    singularity: f"{config['containers_dir']}/kaiju/kaiju-1.9.0.sif"
    threads: config["max_threads"]
    shell:
        """
        kaiju -v -z {threads} \
              -t /mnt/seaes01-data01/nixon-microbiome/shared/kaiju_databases/kaiju_db_nr_euk_2023-05-10/nodes.dmp \
              -f /mnt/seaes01-data01/nixon-microbiome/shared/kaiju_databases/kaiju_db_nr_euk_2023-05-10/kaiju_db_nr_euk.fmi \
              -i {input.forward_paired} \
              -j {input.reverse_paired} \
              -o {output.refseq}
        """

rule kaiju_table_Class:
    input:
        refseq=f"{config['output_dir']}/{{sample}}_kaiju_refseq"
    output:
        mem_table=f"{config['output_dir']}/{{sample}}_CLASS_kaiju.table"
    singularity: f"{config['containers_dir']}/kaiju/kaiju-1.9.0.sif"
    threads: config["max_threads"]
    shell:
        """
        kaiju2table -t /mnt/seaes01-data01/nixon-microbiome/shared/kaiju_databases/kaiju_db_nr_euk_2023-05-10/nodes.dmp \
                    -n /mnt/seaes01-data01/nixon-microbiome/shared/kaiju_databases/kaiju_db_nr_euk_2023-05-10/names.dmp \
                    -r class -u -o {output.mem_table} {input.refseq}
        """

rule kaiju_table_Genus:
    input:
        refseq=f"{config['output_dir']}/{{sample}}_kaiju_refseq"
    output:
        mem_table=f"{config['output_dir']}/{{sample}}_GENUS_kaiju.table"
    singularity: f"{config['containers_dir']}/kaiju/kaiju-1.9.0.sif"
    threads: config["max_threads"]
    shell:
        """
        kaiju2table -t /mnt/seaes01-data01/nixon-microbiome/shared/kaiju_databases/kaiju_db_nr_euk_2023-05-10/nodes.dmp \
                    -n /mnt/seaes01-data01/nixon-microbiome/shared/kaiju_databases/kaiju_db_nr_euk_2023-05-10/names.dmp \
                    -r genus -u -o {output.mem_table} {input.refseq}
        """
