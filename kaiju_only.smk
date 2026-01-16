#Snakemake module for kaiju from already trimmed data

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
    threads: 5
    benchmark: f"{config['benchmark_dir']}/kaiju_only_kaiju_refseq_{{sample}}.tsv"
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
    benchmark: f"{config['benchmark_dir']}/kaiju_only_kaiju_tables_class_{{sample}}.tsv"
    threads: 5
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
    benchmark: f"{config['benchmark_dir']}/kaiju_only_kaiju_table_genus_{{sample}}.tsv"
    threads: 5
    shell:
        """
        kaiju2table -t /mnt/seaes01-data01/nixon-microbiome/shared/kaiju_databases/kaiju_db_nr_euk_2023-05-10/nodes.dmp \
                    -n /mnt/seaes01-data01/nixon-microbiome/shared/kaiju_databases/kaiju_db_nr_euk_2023-05-10/names.dmp \
                    -r genus -u -o {output.mem_table} {input.refseq}
        """

rule kaiju_table_phylum:
    input:
        refseq=f"{config['output_dir']}/{{sample}}_kaiju_refseq"
    output:
        mem_table=f"{config['output_dir']}/{{sample}}_PHYLUM_kaiju.table"
    singularity: f"{config['containers_dir']}/kaiju/kaiju-1.9.0.sif"
    threads: 5
    benchmark: f"{config['benchmark_dir']}/kaiju_only_kaiju_table_phylum_{{sample}}.tsv"
    shell:
        """
        kaiju2table -t /mnt/seaes01-data01/nixon-microbiome/shared/kaiju_databases/kaiju_db_nr_euk_2023-05-10/nodes.dmp \
                    -n /mnt/seaes01-data01/nixon-microbiome/shared/kaiju_databases/kaiju_db_nr_euk_2023-05-10/names.dmp \
                    -r phylum -u -p -o {output.mem_table} {input.refseq}
        """

rule kaiju_table_family:
    input:
        refseq=f"{config['output_dir']}/{{sample}}_kaiju_refseq"
    output:
        mem_table=f"{config['output_dir']}/{{sample}}_FAMILY_kaiju.table"
    singularity: f"{config['containers_dir']}/kaiju/kaiju-1.9.0.sif"
    threads: 5
    benchmark: f"{config['benchmark_dir']}/kaiju_only_kaiju_table_family_{{sample}}.tsv"
    shell:
        """
        kaiju2table -t /mnt/seaes01-data01/nixon-microbiome/shared/kaiju_databases/kaiju_db_nr_euk_2023-05-10/nodes.dmp \
                    -n /mnt/seaes01-data01/nixon-microbiome/shared/kaiju_databases/kaiju_db_nr_euk_2023-05-10/names.dmp \
                    -r family -u -o {output.mem_table} {input.refseq}
        """
