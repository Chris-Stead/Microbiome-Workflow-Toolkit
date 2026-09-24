#Snakemake module for nonpareil

# Step 1 - Convert fastQ to fastA
rule nonpareil_convert:
    input:
        fwd=f"{config['output_dir']}/{{sample}}_forward_paired.fq"
    output:
        fasta_convert=f"{config['output_dir']}/{{sample}}_diversity/{{sample}}_alignment.fasta"
    threads: 5
    benchmark: f"{config['benchmark_dir']}/diversity_nonpareil_convert_{{sample}}.tsv"
    shell:
        """
        cat {input.fwd} | paste - - - - | \
        awk 'BEGIN{{FS="\\t"}}{{print ">"substr($1,2)"\\n"$2}}' > {output.fasta_convert}
        """

# Step 2 - Kmer Analysis
rule nonpareil_kmer:
    input:
        fasta_convert=f"{config['output_dir']}/{{sample}}_diversity/{{sample}}_alignment.fasta"
    output:
        kmer_output=f"{config['output_dir']}/{{sample}}_diversity/{{sample}}_nonpareil_output"
    threads: 5
    singularity: f"{config['containers_dir']}/nonpareil/nonpareil-3.4.1_EC_build.sif"
    benchmark: f"{config['benchmark_dir']}/diversity_nonpareil_kmer_{{sample}}.tsv"
    shell:
        """
        nonpareil -s {input.fasta_convert} -t {threads} -T kmer -f fasta -b {output.kmer_output}
        """

# Step 3 - Alignment
rule nonpareil_alignment:
    input:
        fasta_convert=f"{config['output_dir']}/{{sample}}_diversity/{{sample}}_alignment.fasta"
    output:
        alignment_output=f"{config['output_dir']}/{{sample}}_diversity/{{sample}}_alignment.npo"
    threads: 5
    singularity: f"{config['containers_dir']}/nonpareil/nonpareil-3.4.1_EC_build.sif"
    benchmark: f"{config['benchmark_dir']}/diversity_nonpareil_alignments_{{sample}}.tsv"
    shell:
        """
        nonpareil -s {input.fasta_convert} -t {threads} -T alignment -f fasta -b {output.alignment_output}
        """
