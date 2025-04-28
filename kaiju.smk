# Load the configuration file
configfile: "config.yaml"

rule trimmomatic_kaiju:
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
    threads: 5
    shell:
        "java -jar /trimmomatic/Trimmomatic-0.39/trimmomatic-0.39.jar PE -phred33 -threads {threads} {input.forward} {input.rev} {output.forward_paired} {output.forward_unpaired} {output.reverse_paired} {output.reverse_unpaired} ILLUMINACLIP:/mnt/seaes01-data01/nixon-microbiome/shared/bioinformatic_toolkit/trimmomatic_adapters/Nextera_Truseq_Adapters:2:30:10 LEADING:30 TRAILING:30 SLIDINGWINDOW:4:15 MINLEN:36"

# kaiju.smk
rule kaiju_refseq:
    input:
        forward_paired=f"{config['output_dir']}/{{sample}}_forward_paired.fq",
        reverse_paired=f"{config['output_dir']}/{{sample}}_reverse_paired.fq"
    output:
        refseq=f"{config['output_dir']}/{{sample}}_kaiju_refseq"
    singularity: f"{config['containers_dir']}/kaiju/kaiju-1.9.0.sif"
    threads: 5
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
    shell:
        """
        kaiju2table -t /mnt/seaes01-data01/nixon-microbiome/shared/kaiju_databases/kaiju_db_nr_euk_2023-05-10/nodes.dmp \
                    -n /mnt/seaes01-data01/nixon-microbiome/shared/kaiju_databases/kaiju_db_nr_euk_2023-05-10/names.dmp \
                    -r family -u -o {output.mem_table} {input.refseq}
        """
