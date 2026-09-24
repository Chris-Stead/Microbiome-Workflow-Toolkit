# Snakemake module for binning eukaryotic MAGs/MACs

# Eukrep
rule Eukrep:
    input:
        contigs=f"{config['output_dir']}/{{sample}}_contigs_filtered.fa",
    output:
        euk_contigs=f"{config['output_dir']}/{{sample}}_eukaryotes/{{sample}}_euk_contigs/euk_contigs.fa",
        pro_contigs=f"{config['output_dir']}/{{sample}}_eukaryotes/{{sample}}_pro_contigs/pro_contigs.fa"
    singularity: f"{config['containers_dir']}/eukrep/eukrep_0.6.7--pyh864c0ab_1"
    threads: 5
    benchmark: f"{config['benchmark_dir']}/mags_euk_eukrep_{{sample}}.tsv"
    shell:
        """
        EukRep -i {input.contigs} -o {output.euk_contigs} --prokarya {output.pro_contigs}
        """

#Eukrep symlinks for metawrap
rule eukrep_symlink_reads:
    input:
        forward_paired=f"{config['output_dir']}/{{sample}}_forward_paired.fq",
        rev_paired=f"{config['output_dir']}/{{sample}}_reverse_paired.fq"
    output:
        euk_forward_symlink=temp(f"{config['output_dir']}/temp/{{sample}}_eukaryotes/{{sample}}_eukrep_sym_1.fastq"),
        euk_rev_symlink=temp(f"{config['output_dir']}/temp/{{sample}}_eukaryotes/{{sample}}_eukrep_sym_2.fastq")
    threads: 1
    benchmark: f"{config['benchmark_dir']}/mags_euk_symlink_reads_{{sample}}.tsv"
    shell:
        """
        #mkdir -p {{config['output_dir']}}/temp
        ln -sf {input.forward_paired} {output.euk_forward_symlink}
        ln -sf {input.rev_paired} {output.euk_rev_symlink}
        """
# Concoct binning 
# Concoct binning (MetaWRAP) with Snakemake-managed cleanup of work_files/
rule euk_metawrap_bin:
    input:
        euk_contigs = f"{config['output_dir']}/{{sample}}_eukaryotes/{{sample}}_euk_contigs/euk_contigs.fa",
        euk_forward_symlink = f"{config['output_dir']}/temp/{{sample}}_eukaryotes/{{sample}}_eukrep_sym_1.fastq",
        euk_rev_symlink = f"{config['output_dir']}/temp/{{sample}}_eukaryotes/{{sample}}_eukrep_sym_2.fastq",
    output:
        euk_mag_folder = directory(f"{config['output_dir']}/{{sample}}_eukaryotes/{{sample}}_euk_mags_bins"),
        euk_bin = directory(f"{config['output_dir']}/{{sample}}_eukaryotes/{{sample}}_euk_mags_bins/concoct_bins"),
        work_files = temp(directory(f"{config['output_dir']}/{{sample}}_eukaryotes/{{sample}}_euk_mags_bins/work_files")),
    singularity:
        f"{config['containers_dir']}/metawrap/metawrap-1.3.0_EC_build.sif"
    threads: 10
    benchmark:
        f"{config['benchmark_dir']}/mags_euk_metawrap_bin_{{sample}}.tsv"
    shell:
        """
        checkm data setRoot /mnt/seaes01-data01/nixon-microbiome/shared/databases1/checkm
        metawrap binning \
          -o {output.euk_mag_folder} \
          -a {input.euk_contigs} \
          -t {threads} \
          --concoct --universal \
          {input.euk_forward_symlink} {input.euk_rev_symlink}
        """


# BAT taxonomic identification of bins
rule cat_bins:
    input:
        euk_bin=f"{config['output_dir']}/{{sample}}_eukaryotes/{{sample}}_euk_mags_bins/concoct_bins"
    output:
        cat_tax_id=f"{config['output_dir']}/{{sample}}_eukaryotes/{{sample}}_cat_taxid.bin2classification.txt"
    params:
        out_prefix=f"{config['output_dir']}/{{sample}}_eukaryotes/{{sample}}_cat_taxid"
    singularity: f"{config['containers_dir']}/cat/cat_6.0.1--hdfd78af_1"
    threads: 5
    benchmark: f"{config['benchmark_dir']}/mags_euk_cat_bins_{{sample}}.tsv"
    shell:
        r"""
        CAT_pack bins \
          -n {threads} \
          -b {input.euk_bin} \
          -d /mnt/seaes01-data01/nixon-microbiome/shared/databases1/NCBI_nr/20241212_CAT_nr_website/db/ \
          -t /mnt/seaes01-data01/nixon-microbiome/shared/databases1/NCBI_nr/20241212_CAT_nr_website/tax/ \
          -s .fa \
          -o {params.out_prefix}
        """

rule cat_names:
    input:
        cat_tax_id=f"{config['output_dir']}/{{sample}}_eukaryotes/{{sample}}_cat_taxid.bin2classification.txt"
    output:
        cat_output_named=f"{config['output_dir']}/{{sample}}_eukaryotes/{{sample}}_cat_taxonomy_named.txt"
    singularity: f"{config['containers_dir']}/cat/cat_6.0.1--hdfd78af_1"
    threads: 1
    benchmark: f"{config['benchmark_dir']}/mags_euk_cat_names_{{sample}}.tsv"
    shell:
        r"""
        CAT_pack add_names \
          -i {input.cat_tax_id} \
          -o {output.cat_output_named} \
          -t /mnt/seaes01-data01/nixon-microbiome/shared/databases1/NCBI_nr/20241212_CAT_nr_website/tax/ \
          --only_official --force
        """
