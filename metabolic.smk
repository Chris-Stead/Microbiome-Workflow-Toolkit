#Snakemake module for METABOLIC

rule create_bin_symlinks_with_fasta:
    input:
        refined_mag_directory_bins = f"{config['output_dir']}/{{sample}}_refined_mag_directory/metawrap_70_10_bins"
    output:
        symlink_dir = directory(f"{config['output_dir']}/{{sample}}_refined_mag_directory/metawrap_70_10_bins_symlinks")
    shell:
        """
        mkdir -p {output.symlink_dir}
        echo "Creating symlinks with .fasta extensions for sample {wildcards.sample}..."
        for file in {input.refined_mag_directory_bins}/*.fa; do
            if [[ -f "$file" ]]; then
                ln -s "$(realpath "$file")" "{output.symlink_dir}/$(basename ${{file%.fa}}.fasta)"
            fi
        done
        """

rule create_read_symlinks_with_fastq:
    input:
        forward_paired = f"{config['output_dir']}/{{sample}}_forward_paired.fq",
        reverse_paired = f"{config['output_dir']}/{{sample}}_reverse_paired.fq"
    output:
        forward_symlink = f"{config['output_dir']}/{{sample}}_metabolic_fastq_symlink_reads/{{sample}}_1.fastq",
        reverse_symlink = f"{config['output_dir']}/{{sample}}_metabolic_fastq_symlink_reads/{{sample}}_2.fastq"
    shell:
        """
        mkdir -p {config[output_dir]}/{{sample}}_metabolic_fastq_symlink_reads

        echo "Creating forward symlink for sample {wildcards.sample}..."
        ln -s "$(realpath {input.forward_paired})" {output.forward_symlink}

        echo "Creating reverse symlink for sample {wildcards.sample}..."
        ln -s "$(realpath {input.reverse_paired})" {output.reverse_symlink}
        """

rule metabolic_reads_list:
    input:
        forward_fastq = f"{config['output_dir']}/{{sample}}_metabolic_fastq_symlink_reads/{{sample}}_1.fastq",
        rev_fastq = f"{config['output_dir']}/{{sample}}_metabolic_fastq_symlink_reads/{{sample}}_2.fastq"
    output:
        reads_list = f"{config['output_dir']}/{{sample}}_metabolic_list.txt"
    shell:
        """
        echo -n "{input.forward_fastq},{input.rev_fastq}" > {output.reads_list}
        """

rule metabolic:
    input:
        reads_list = f"{config['output_dir']}/{{sample}}_metabolic_list.txt",
        symlink_dir = f"{config['output_dir']}/{{sample}}_refined_mag_directory/metawrap_70_10_bins_symlinks",
    output:
        metabolic_dir = directory(f"{config['output_dir']}/{{sample}}_metabolic")
    threads: config["max_threads"]
    singularity: "/mnt/seaes01-data01/nixon-microbiome/containers/metabolic-c/metabolic_4.0_EC_build.sif"
    benchmark: f"{config['benchmark_dir']}/metabolic_metabolic_{{sample}}.tsv"
    shell:
        """
        cd /mnt/seaes01-data01/nixon-microbiome/shared/METABOLIC_running_folder/METABOLIC/
        perl METABOLIC-C.pl -in-gn {input.symlink_dir} -t {threads} -rt metaG -r {input.reads_list} -o {output.metabolic_dir}
        cd /mnt/seaes01-data01/nixon-microbiome/shared/bioinformatic_toolkit
        """
