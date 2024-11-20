# Load the configuration file
configfile: "config.yaml"

# Load necessary modules
import glob

# Rule for creating symbolic links for paired reads
rule symlink_reads:
    input:
        forward_paired=f"{config['output_dir']}/{{sample}}_forward_paired.fq",
        rev_paired=f"{config['output_dir']}/{{sample}}_reverse_paired.fq"
    output:
        forward_symlink=temp(f"{config['output_dir']}/temp/{{sample}}_sym_1.fastq"),
        rev_symlink=temp(f"{config['output_dir']}/temp/{{sample}}_sym_2.fastq")
    shell:
        """
        mkdir -p {{config['output_dir']}}/temp
        ln -sf {input.forward_paired} {output.forward_symlink}
        ln -sf {input.rev_paired} {output.rev_symlink}
        """

# Rule for MAGs binning using MetaWrap
rule metawrap_bin:
    input:
        contigs=f"{config['output_dir']}/{{sample}}_assembly/contigs.fasta",
        forward_symlink=f"{config['output_dir']}/temp/{{sample}}_sym_1.fastq",
        rev_symlink=f"{config['output_dir']}/temp/{{sample}}_sym_2.fastq"
    output:
        mag_folder=directory(f"{config['output_dir']}/{{sample}}_mags_bins"),
	concoct_dir=directory(f"{config['output_dir']}/{{sample}}_mags_bins/concoct_bins"),
        maxbin2_dir=directory(f"{config['output_dir']}/{{sample}}_mags_bins/maxbin2_bins"),
        metabat_dir=directory(f"{config['output_dir']}/{{sample}}_mags_bins/metabat2_bins")
    singularity:"/opt/containers/metawrap/metawrap-1.3.0.sif"
    threads: config["max_threads"]
    shell:
        """
	checkm data setRoot /mnt/seaes01-data01/nixon-microbiome/shared/databases1/checkm        
	metawrap binning -o {output.mag_folder} -a {input.contigs} -t {threads} \
        --maxbin2 --metabat2 --concoct --universal {input.forward_symlink} {input.rev_symlink}
        """


rule bin_refinement:
    input: 
        concoct=f"{config['output_dir']}/{{sample}}_mags_bins/concoct_bins",
        maxbin2=f"{config['output_dir']}/{{sample}}_mags_bins/maxbin2_bins",
        metabat=f"{config['output_dir']}/{{sample}}_mags_bins/metabat2_bins"
    output: 
        refined_mag_directory=directory(f"{config['output_dir']}/{{sample}}_refined_mag_directory"),
	refined_mag_directory_bins=directory(f"{config['output_dir']}/{{sample}}_refined_mag_directory/metawrap_50_10_bins")

    singularity:"/opt/containers/metawrap/metawrap-1.3.0.sif"
    threads: config["max_threads"]
    shell:
        """
        metawrap bin_refinement -o {output.refined_mag_directory} -t {threads} -A {input.concoct} -B {input.maxbin2} -C {input.metabat} -c 50 -x 10
        """
    
# Rule for GTDB-Tk classification
rule gtdbtk_folder:
    output:
        gtdbtk_temp=directory(f"{config['output_dir']}/{{sample}}_gtdbtk_temp")
    shell:
        """
        mkdir -p {output.gtdbtk}
        """

rule gtdbtk:
    input: 
        refined_mag_directory=f"{config['output_dir']}/{{sample}}_refined_mag_directory",
	refined_mag_directory_bins=f"{config['output_dir']}/{{sample}}_refined_mag_directory/metawrap_50_10_bins",
	gtdbtk_temp=f"{config['output_dir']}/{{sample}}_gtdbtk_temp"
    output:
        taxonomy=directory(f"{config['output_dir']}/{{sample}}_gtdbtk")
    singularity: f"{config['containers_dir']}/gtdbtk/gtdbtk_2.4.0.sif"
    threads: config["max_threads"]
    shell:
        """
        export GTDBTK_DATA_PATH="/mnt/seaes01-data01/nixon-microbiome/databases/gtdbtk_data/release220"
	gtdbtk classify_wf --genome_dir {input.refined_mag_directory_bins} --mash_db {input.gtdbtk_temp} --extension .fa --out_dir {output.taxonomy} --cpus {threads}
        """

# Rule for CoverM genome coverage
rule coverm:
    input:
        forward=f"{config['output_dir']}/{{sample}}_forward_paired.fq",
        rev=f"{config['output_dir']}/{{sample}}_reverse_paired.fq",
        refined_mag_directory=f"{config['output_dir']}/{{sample}}_refined_mag_directory",
	refined_mag_directory_bins=f"{config['output_dir']}/{{sample}}_refined_mag_directory/metawrap_50_10_bins"
    output:
        coverage=f"{config['output_dir']}/{{sample}}_coverm_coverage.tsv"
    singularity: f"{config['containers_dir']}/coverm/coverm.sif"
    threads: config["max_threads"]
    shell:
        """
        coverm genome -1 {input.forward} -2 {input.rev} --genome-fasta-directory {input.refined_mag_directory_bins} \
        --genome-fasta-extension .fa --output-file {output.coverage} --threads {threads}
        """
