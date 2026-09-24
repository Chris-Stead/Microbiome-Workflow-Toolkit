#Snakemake module for MAC/MAG assembly

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
    threads: 1
    benchmark: f"{config['benchmark_dir']}/mags_symlink_reads_{{sample}}.tsv"
    shell:
        """
       # mkdir -p {{config['output_dir']}}/temp
        ln -sf {input.forward_paired} {output.forward_symlink}
        ln -sf {input.rev_paired} {output.rev_symlink}
        """

# Rule for MAGs binning using MetaWrap
rule metawrap_bin:
    input:
        contigs=f"{config['output_dir']}/{{sample}}_contigs_filtered.fa",
        forward_symlink=f"{config['output_dir']}/temp/{{sample}}_sym_1.fastq",
        rev_symlink=f"{config['output_dir']}/temp/{{sample}}_sym_2.fastq"
    output:
        mag_folder=directory(f"{config['output_dir']}/{{sample}}_mags_bins"),
	concoct_dir=directory(f"{config['output_dir']}/{{sample}}_mags_bins/concoct_bins"),
        maxbin2_dir=directory(f"{config['output_dir']}/{{sample}}_mags_bins/maxbin2_bins"),
        metabat_dir=directory(f"{config['output_dir']}/{{sample}}_mags_bins/metabat2_bins")
    singularity:f"{config['containers_dir']}/metawrap/metawrap-1.3.0_EC_build.sif"
    threads: 5
    benchmark: f"{config['benchmark_dir']}/mags_metawrap_bin_{{sample}}.tsv"
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
	refined_mag_directory_bins=directory(f"{config['output_dir']}/{{sample}}_refined_mag_directory/metawrap_70_10_bins")
    singularity:f"{config['containers_dir']}/metawrap/metawrap-1.3.0_EC_build.sif"
    benchmark: f"{config['benchmark_dir']}/mags_bin_refinment_{{sample}}.tsv"
    threads: 5
    shell:
        """
        metawrap bin_refinement -o {output.refined_mag_directory} -t {threads} -A {input.concoct} -B {input.maxbin2} -C {input.metabat} -c 70 -x 10
        """
    
# Rule for GTDB-Tk classification (CONFIGURED LONG FILE PATHS REMOVED AS THEY CAUSE ERRORS)
rule gtdbtk_folder:
    output:
        gtdbtk_temp=directory(f"{config['output_dir']}/{{sample}}_gtdbtk_temporary_directory")
    shell:
        """
        mkdir -p {output.gtdbtk_temp}
        """

rule gtdbtk:
    input: 
        refined_mag_directory_bins=f"{config['output_dir']}/{{sample}}_refined_mag_directory/metawrap_70_10_bins",
        gtdbtk_temp=f"{config['output_dir']}/{{sample}}_gtdbtk_temporary_directory"
    output:
        taxonomy=directory(f"{config['output_dir']}/{{sample}}_gtdbtk"),
	mash_db=f"{config['output_dir']}/{{sample}}_gtdbtk_mash_db"
    singularity: f"{config['containers_dir']}/gtdbtk/gtdbtk_2.4.1--pyhdfd78af_1"
    threads: 5
    shell:
        """
        gtdbtk classify_wf \
         --genome_dir {input.refined_mag_directory_bins} \
         --extension .fa \
         --tmpdir /mnt/seaes01-data01/nixon-microbiome/shared/tmp \
         --out_dir {output.taxonomy} \
         --cpus {threads} \
	     --mash_db {output.mash_db}
         --pplacer_cpus 1
        """

# Rule for CoverM genome coverage
rule coverm:
    input:
        forward=f"{config['output_dir']}/{{sample}}_forward_paired.fq",
        rev=f"{config['output_dir']}/{{sample}}_reverse_paired.fq",
        refined_mag_directory=f"{config['output_dir']}/{{sample}}_refined_mag_directory",
	refined_mag_directory_bins=f"{config['output_dir']}/{{sample}}_refined_mag_directory/metawrap_70_10_bins"
    output:
        coverage=f"{config['output_dir']}/{{sample}}_coverm_coverage.tsv"
    singularity: f"{config['containers_dir']}/coverm/coverm.sif"
    threads: 5
    benchmark: f"{config['benchmark_dir']}/mags_coverm_{{sample}}.tsv"
    shell:
        """
        coverm genome -1 {input.forward} -2 {input.rev} --genome-fasta-directory {input.refined_mag_directory_bins} \
        --genome-fasta-extension .fa --output-file {output.coverage} --threads {threads}
        """

#provirus
#rule find_provirus:
#    input:
#        bin=glob_wildcards(f"{config['output_dir']}/{{sample}}_refined_mag_directory/metawrap_70_10_bins/{{bin}}.fa").bin
#    output:
#        provirus_dir=directory(f"{config['output_dir']}/{{sample}}_refined_mag_directory/provirus_in_bins/{{sample}}_provirus/{{bin}}_provirus")
#    threads: 5
#    shell:
#        """
#        singularity exec /mnt/seaes01-data01/nixon-microbiome/containers/genomad/genomad-1.8.0_EC_build.sif \
#        genomad find-provirus --cleanup {input.bin} {output.provirus_dir} /mnt/data/genomad_db_v1.7
#        """

#spacers
#rule crispr_spacers:
#    input:
#        bin=glob_wildcards(f"{config['output_dir']}/{{sample}}_refined_mag_directory/metawrap_70_10_bins/{{bin}}.fa").bin
#    output:
#        crispr_gff=f"{config['output_dir']}/{{sample}}_refined_mag_directory/crispr_in_bins/{{bin}}_crispr/crispr_spacers.gff",
#        crispr_txt=f"{config['output_dir']}/{{sample}}_refined_mag_directory/crispr_in_bins/{{bin}}_crispr/crispr_spacers.txt"
#    singularity:
#        f"{config['containers_dir']}/minced/minced_0.4.2--hdfd78af_1"
#    threads: 5
#    shell:
#        """
#        mkdir -p $(dirname {output.crispr_gff})
#        minced -gff {input.bin} {output.crispr_txt} {output.crispr_gff}
#        """
