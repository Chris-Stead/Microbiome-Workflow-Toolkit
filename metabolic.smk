# Load the configuration file
configfile: "config.yaml"

# Rule for creating fasta files from paired reads for METABOLIC analysis
rule metabolic_fasta_reads:
    input:
        forward_paired=f"{config['output_dir']}/{{sample}}_forward_paired.fq",
        rev_paired=f"{config['output_dir']}/{{sample}}_reverse_paired.fq"
    output:
        fasta_reads_dir=directory(f"{config['output_dir']}/{{sample}}_metabolic_fasta_reads"),
        forward_fasta=f"{config['output_dir']}/{{sample}}_metabolic_fasta_reads/{{sample}}_1.fasta",
        rev_fasta=f"{config['output_dir']}/{{sample}}_metabolic_fasta_reads/{{sample}}_2.fasta"
    shell:
        """
        mkdir -p {output.fasta_reads_dir}
        awk '(NR-1) % 4 == 0 {{print ">" substr($0, 2)}} (NR-2) % 4 == 0 {{print $0}}' {input.forward_paired} > {output.forward_fasta}
        awk '(NR-1) % 4 == 0 {{print ">" substr($0, 2)}} (NR-2) % 4 == 0 {{print $0}}' {input.rev_paired} > {output.rev_fasta}
        """

# Rule for running METABOLIC analysis
rule metabolic:
    input:
        refined_mag_directory_bins=f"{config['output_dir']}/{{sample}}_refined_mag_directory/metawrap_50_10_bins",
        fasta_reads_dir=f"{config['output_dir']}/{{sample}}_metabolic_fasta_reads"
    output:
        metabolic_dir=directory(f"{config['output_dir']}/{{sample}}_metabolic")
    threads: config["max_threads"]
    singularity: "/mnt/seaes01-data01/nixon-microbiome/containers/metabolic-c/metabolic_4.0_EC_build.sif"
    shell:
        """
        cd /mnt/seaes01-data01/nixon-microbiome/shared/METABOLIC_running_folder/METABOLIC/
        perl METABOLIC-C.pl -in-gn {input.refined_mag_directory_bins} -t {threads} -r {input.fasta_reads_dir} -o {output.metabolic_dir}
        cd /mnt/seaes01-data01/nixon-microbiome/shared/bioinformatic_toolkit
        """
