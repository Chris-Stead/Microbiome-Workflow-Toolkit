# #Snakemake module for S3 abundance mapping 

rule find_genes:
    input:
        contigs=f"{config['output_dir']}/{{sample}}_assembly/contigs.fasta"
    output:
        genes=temp(f"{config['output_dir']}/{{sample}}_S3/{{sample}}.genes"),
        amino_acid_seq=temp(f"{config['output_dir']}/{{sample}}_S3/{{sample}}_genes.faa"),
        nucleotide_seq=temp(f"{config['output_dir']}/{{sample}}_S3/{{sample}}_genes.fna")
    threads: 1
    singularity: f"{config['containers_dir']}/prodigal/prodigal_2.6.3--h7b50bb2_10"
    benchmark: f"{config['benchmark_dir']}/s3_abundance_find_genes_{{sample}}.tsv"
    shell:
        """
        prodigal -i {input.contigs}  -o {output.genes} -a {output.amino_acid_seq} -d {output.nucleotide_seq} -p meta
        """

rule annotate_aa:
    input:
        amino_acid_seq=f"{config['output_dir']}/{{sample}}_S3/{{sample}}_genes.faa"
    output:
        gene_annotation=f"{config['output_dir']}/{{sample}}_S3/{{sample}}_genes_annotated.txt"
    threads: 10
    singularity: f"{config['containers_dir']}/kofamscan/kofamscan-1.3.0.sif"
    benchmark: f"{config['benchmark_dir']}/s3_abundance_annotate_aa_{{sample}}.tsv"
    shell:
        """
        exec_annotation -o {output.gene_annotation} -p /mnt/seaes01-data01/nixon-microbiome/shared/databases/kofam/profiles -k /mnt/seaes01-data01/nixon-microbiome/shared/databases/kofam/ko_list --cpu {threads} -f mapper-one-line --tmp-dir kofam_tmp {input.amino_acid_seq}
        """
        
rule extract_S3:
    input:
        gene_annotation=f"{config['output_dir']}/{{sample}}_S3/{{sample}}_genes_annotated.txt"
    output:
        S3_genes=f"{config['output_dir']}/{{sample}}_S3/{{sample}}_S3_genes.tsv",
        S3_genes_refined=f"{config['output_dir']}/{{sample}}_S3/{{sample}}_S3_genes_refined.tsv"
    threads: 1
    singularity: f"{config['containers_dir']}/kofamscan/kofamscan-1.3.0.sif"
    benchmark: f"{config['benchmark_dir']}/s3_abundance_extract_s3_{{sample}}.tsv"
    shell:
        """
        grep K02982 {input.gene_annotation} > {output.S3_genes}
        awk '{{print $1}}' {output.S3_genes} > {output.S3_genes_refined}
        """

rule refine_faa:
    input:
        S3_genes_refined=f"{config['output_dir']}/{{sample}}_S3/{{sample}}_S3_genes_refined.tsv",
        amino_acid_seq=f"{config['output_dir']}/{{sample}}_S3/{{sample}}_genes.faa",
    output:
        amino_acid_seq_S3=f"{config['output_dir']}/{{sample}}_S3/{{sample}}_genes_S3.faa",
    threads: 1
    singularity: f"{config['containers_dir']}/seqkit/seqkit_2.9.0--h9ee0642_0"
    benchmark: f"{config['benchmark_dir']}/s3_abundance_refine_faa_{{sample}}.tsv"
    shell:
        """
        seqkit grep -f {input.S3_genes_refined} {input.amino_acid_seq} > {output.amino_acid_seq_S3}
        """
        
#rule cluster_S3:
#    input:
#        amino_acid_seq_S3=f"{config['output_dir']}/{{sample}}_S3/{{sample}}_genes_S3.faa",
#    output:
#        amino_acid_seq_S3_clustered=f"{config['output_dir']}/{{sample}}_S3/{{sample}}_genes_S3_clustered.faa"
#    threads: 1
#    singularity: f"{config['containers_dir']}/cdhit/cd-hit_4.8.1--hdbcaa40_2"
#    shell:
#        """
#        cd-hit -i {input.amino_acid_seq_S3} -o {output.amino_acid_seq_S3_clustered} -c 0.97 -n 5 -T {threads}
#        """

rule filter_150_AA:
    input:
        amino_acid_seq_S3=f"{config['output_dir']}/{{sample}}_S3/{{sample}}_genes_S3.faa",
    output:
        amino_acid_seq_S3_150=f"{config['output_dir']}/{{sample}}_S3/{{sample}}_genes_S3_150.faa",
    threads: 1
    singularity: f"{config['containers_dir']}/seqkit/seqkit_2.9.0--h9ee0642_0"
    benchmark: f"{config['benchmark_dir']}/s3_abundance_filter150_aa_{{sample}}.tsv"
    shell:
        """
        seqkit seq --min-len 150 {input.amino_acid_seq_S3} > {output.amino_acid_seq_S3_150}
        """

rule blast_S3:
    input:
        amino_acid_seq_S3_150=f"{config['output_dir']}/{{sample}}_S3/{{sample}}_genes_S3_150.faa",
    output:
        blast_list=f"{config['output_dir']}/{{sample}}_S3/{{sample}}_blast.txt",
    threads: 5
    singularity: f"{config['containers_dir']}/blast+/blast+-2.3.0.sif"
    benchmark: f"{config['benchmark_dir']}/s3_abundance_blast_S3_{{sample}}.tsv"
    shell:
        """
        blastp -num_threads {threads} \
        -query {input.amino_acid_seq_S3_150} \
        -db /mnt/seaes01-data01/nixon-microbiome/databases/gtdb_markers/fromDropbox/gtdb_markers_bac_arc_prot_db \
        -evalue 1e-5 \
        -outfmt "6 sseqid qseqid pident length mismatch gapopen qstart qend sstart send evalue bitscore qlen slen qcovs" \
        -out {output.blast_list}
        """

rule blast_S3_sort:
    input:
        blast_list=f"{config['output_dir']}/{{sample}}_S3/{{sample}}_blast.txt"
    output:
        blast_list_sorted=f"{config['output_dir']}/{{sample}}_S3/{{sample}}_blast_sorted.txt"
    threads: 1
    benchmark: f"{config['benchmark_dir']}/s3_abundance_blast_s3_sort_{{sample}}.tsv"
    shell:
        """
        sort -k2,2 {input.blast_list} > {output.blast_list_sorted}
        """

rule blast_S3_merge:
    input:
        blast_list_sorted=f"{config['output_dir']}/{{sample}}_S3/{{sample}}_blast_sorted.txt",
        taxonomy_file="/mnt/seaes01-data01/nixon-microbiome/shared/databases1/gtdb/sorted_gtdb_taxonomy.tsv"
    output:
        blast_list_sorted_matched=f"{config['output_dir']}/{{sample}}_S3/{{sample}}_blast_sorted_matched.txt"
    threads: 1
    benchmark: f"{config['benchmark_dir']}/s3_abundance_blast_s3_merge_{{sample}}.tsv"
    conda: '../../conda_envs/python_pandas.yml'
    script: '../../scripts/blast_merge_taxonomy.py'

rule gene_ID_sort:
    input:
        blast_list_sorted_matched=f"{config['output_dir']}/{{sample}}_S3/{{sample}}_blast_sorted_matched.txt"
    output:
        blast_list_sorted_bitscore=f"{config['output_dir']}/{{sample}}_S3/{{sample}}_blast_sorted_bitscore.txt"
    threads: 1
    singularity: f"{config['containers_dir']}/blast+/blast+-2.3.0.sif"
    benchmark: f"{config['benchmark_dir']}/s3_abundance_gene_ID_sort_{{sample}}.tsv"
    shell:
        """
        sort -k2,2 -k12,12gr {input.blast_list_sorted_matched} > {output.blast_list_sorted_bitscore}
        """

rule ammened_fasta_names:
    input:
        blast_list_sorted_bitscore=f"{config['output_dir']}/{{sample}}_S3/{{sample}}_blast_sorted_bitscore.txt"
    output:
        blast_list_sorted_bitscore_csv=f"{config['output_dir']}/{{sample}}_S3/{{sample}}_blast_sorted_bitscore.csv"
    threads: 1
    benchmark: f"{config['benchmark_dir']}/s3_abundance_ammend_fasta_names_{{sample}}.tsv"
    shell:
        """
        sed 's/ \+/,/g' {input.blast_list_sorted_bitscore} > {output.blast_list_sorted_bitscore_csv}
        """

rule ammened_fasta_names1:
    input:
        blast_list_sorted_bitscore_csv=f"{config['output_dir']}/{{sample}}_S3/{{sample}}_blast_sorted_bitscore.csv",
        nucleotide_seq=f"{config['output_dir']}/{{sample}}_S3/{{sample}}_genes.fna"
    output:
        annotated_s3_genes=f"{config['output_dir']}/{{sample}}_S3/{{sample}}_annotated_s3_genes.fasta"
    threads: 1
    benchmark: f"{config['benchmark_dir']}/s3_abundance_ammend_fasta_names1_{{sample}}.tsv"
    conda: '../../conda_envs/bioconda_environment.yml'
    script: '../../scripts/S3_concat_taxonomy2.py'

rule ammened_fasta_names2:
    input:
        annotated_s3_genes=f"{config['output_dir']}/{{sample}}_S3/{{sample}}_annotated_s3_genes.fasta"
    output:
        annotated_s3_genes_nospace=f"{config['output_dir']}/{{sample}}_S3/{{sample}}_annotated_s3_genes_nospace.fasta"
    threads: 1
    benchmark: f"{config['benchmark_dir']}/s3_abundance_ammend_fasta_names2_{{sample}}.tsv"
    shell:
        """
        awk '{{gsub(/ /,"|"); print}}' {input.annotated_s3_genes} > {output.annotated_s3_genes_nospace}
        """

rule S3_read_mapping:
    input:
        forward_paired=f"{config['output_dir']}/{{sample}}_forward_paired.fq",
        reverse_paired=f"{config['output_dir']}/{{sample}}_reverse_paired.fq",
        annotated_s3_genes_nospace=f"{config['output_dir']}/{{sample}}_S3/{{sample}}_annotated_s3_genes_nospace.fasta"

    output:
        S3_gene_abundance=f"{config['output_dir']}/{{sample}}_S3/{{sample}}_S3_gene_abundance.tsv"
    threads: 5
    benchmark: f"{config['benchmark_dir']}/s3_abundance_S3_read_mapping_{{sample}}.tsv"
    singularity: f"{config['containers_dir']}/coverm/coverm_0.7.0--hb4818e0_2"
    shell:
        """
        coverm contig -t {threads} -1 {input.forward_paired} -2 {input.reverse_paired} --reference {input.annotated_s3_genes_nospace} -m tpm -o {output.S3_gene_abundance}
        """
