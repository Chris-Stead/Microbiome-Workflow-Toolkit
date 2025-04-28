	# Load the configuration file
configfile: "config.yaml"

# Step 2.1 - cut contig names  
#rule cut_IDs: 
#    input: f"{config['output_dir']}/{{sample}}_assembly/contigs.fasta"
#    output: f"{config['output_dir']}/{{sample}}_tpm/{{sample}}_contigs_IDs_cut.fasta"
#    threads: workflow.cores 
#    shell: 
#        "cut -d 'l' -f1 {input} > {output}"

# Step 3 - annotation
#select contig size filter
rule filter_seq:
    input: f"{config['output_dir']}/{{sample}}_assembly/contigs.fasta"
    output: f"{config['output_dir']}/{{sample}}_tpm/{{sample}}_scaffold_filtered.fa"
    threads: workflow.cores
    shell: 
        'python /mnt/seaes01-data01/nixon-microbiome/shared/scripts/pullseq_python3.py -i {input} -o {output} -m 1000'

rule tpm_metaprokka:
    input:
        contigs=f"{config['output_dir']}/{{sample}}_tpm/{{sample}}_scaffold_filtered.fa"
    output:
        prokka_folder=directory(f"{config['output_dir']}/{{sample}}_tpm/{{sample}}_tpm_prokka"),
        gff=f"{config['output_dir']}/{{sample}}_tpm/{{sample}}_tpm_prokka/{{sample}}_filtered_prokka.gff",
        tsv=f"{config['output_dir']}/{{sample}}_tpm/{{sample}}_tpm_prokka/{{sample}}_filtered_prokka.tsv",
        faa=f"{config['output_dir']}/{{sample}}_tpm/{{sample}}_tpm_prokka/{{sample}}_filtered_prokka.faa"
    singularity: f"{config['containers_dir']}/metaprokka/metaprokka_1.15.0"
    threads: 10
    shell:
        """
        metaprokka --force --dbdir /mnt/seaes01-data01/nixon-microbiome/shared/databases1/prokka_database/prokka/db \
        --outdir {output.prokka_folder} \
        --prefix {wildcards.sample}_filtered_prokka \
        --force --cpus {threads} --metagenome {input.contigs} \
        """

rule get_gtf:
    input: f"{config['output_dir']}/{{sample}}_tpm/{{sample}}_tpm_prokka/{{sample}}_filtered_prokka.gff"
    output: f"{config['output_dir']}/{{sample}}_tpm/{{sample}}_tpm_prokka/{{sample}}_filtered_prokka.gtf"
    threads: 10
    shell: 
        'bash /mnt/seaes01-data01/nixon-microbiome/shared/scripts/prokkagff2gtf.sh {input} > {output}'

rule kofam:
    input:
        f"{config['output_dir']}/{{sample}}_tpm/{{sample}}_tpm_prokka/{{sample}}_filtered_prokka.faa"
    output:
        kofam=f"{config['output_dir']}/{{sample}}_tpm/{{sample}}_kofam_oneline.txt",
        kofam_tmpdir=directory(f"{config['output_dir']}/{{sample}}_tpm/{{sample}}_kofam_tmpdir")
    singularity: f"{config['containers_dir']}/kofamscan/kofamscan-1.3.0.sif"
    threads: 10
    shell: 
        'exec_annotation -o {output.kofam} -p /mnt/seaes01-data01/nixon-microbiome/shared/databases/kofam/profiles -k /mnt/seaes01-data01/nixon-microbiome/shared/databases/kofam/ko_list --cpu {threads} -f mapper-one-line --tmp-dir {output.kofam_tmpdir} {input}'

# Step 5 - Mapping
rule bowtie_build:
    input: 
        scaffolds=f"{config['output_dir']}/{{sample}}_tpm/{{sample}}_scaffold_filtered.fa"
    singularity: f"{config['containers_dir']}/bowtie2/bowtie-2.4.5.sif"
    threads: 10
    output: f"{config['output_dir']}/{{sample}}_tpm/{{sample}}_index.done"
    shell: 
        'bowtie2-build {input.scaffolds} {input.scaffolds} && echo done > {output}'

rule bowtie_map:
    input: 
        indexfile=f"{config['output_dir']}/{{sample}}_tpm/{{sample}}_index.done",
        scaffolds=f"{config['output_dir']}/{{sample}}_tpm/{{sample}}_scaffold_filtered.fa",
        fwd=f"{config['output_dir']}/{{sample}}_forward_paired.fq",
        rev=f"{config['output_dir']}/{{sample}}_reverse_paired.fq"
    output: temp(f"{config['output_dir']}/{{sample}}_tpm/{{sample}}_filtered.map.sam")
    singularity: f"{config['containers_dir']}/bowtie2/bowtie-2.4.5.sif"
    threads: 10
    log: f"{config['output_dir']}/{{sample}}_tpm/logs/bowtie/{{sample}}.log"
    shell: 
        'bowtie2 -p {threads} -x {input.scaffolds} -1 {input.fwd} -2 {input.rev} -S {output} 2> {log}'

rule samtools:
    input: f"{config['output_dir']}/{{sample}}_tpm/{{sample}}_filtered.map.sam"
    output: f"{config['output_dir']}/{{sample}}_tpm/{{sample}}_filtered.map.sorted.bam"
    singularity: f"{config['containers_dir']}/samtools/samtools-1.16.1.sif"
    threads: 10
    shell: 
        'samtools sort -o {output} -O bam {input}'

rule picard:
    input: f"{config['output_dir']}/{{sample}}_tpm/{{sample}}_filtered.map.sorted.bam"
    output: 
        markdup=f"{config['output_dir']}/{{sample}}_tpm/{{sample}}_filtered.map.markdup.bam",
        metrics=f"{config['output_dir']}/{{sample}}_tpm/{{sample}}_filtered.map.markdup.metrics"
    singularity: f"{config['containers_dir']}/picard/picard-2.27.5.sif"
    threads: 10
    shell: 
        'java -Xms2g -Xmx32g -jar /picard/picard.jar MarkDuplicates INPUT={input} OUTPUT={output.markdup} METRICS_FILE={output.metrics} AS=TRUE VALIDATION_STRINGENCY=LENIENT MAX_FILE_HANDLES_FOR_READ_ENDS_MAP=2500 REMOVE_DUPLICATES=TRUE'

rule htseq:
    input: 
        mk=f"{config['output_dir']}/{{sample}}_tpm/{{sample}}_filtered.map.markdup.bam",
        gtf=f"{config['output_dir']}/{{sample}}_tpm/{{sample}}_tpm_prokka/{{sample}}_filtered_prokka.gtf"
    output: f"{config['output_dir']}/{{sample}}_tpm/{{sample}}.counts"
    singularity: f"{config['containers_dir']}/htseq/htseq-2.0.2.sif"
    threads: 10
    shell: 
        'htseq-count -r pos -t CDS -f bam {input.mk} {input.gtf} > {output}'

rule read_length:
    input: fwd=f"{config['output_dir']}/{{sample}}_forward_paired.fq"
    output: f"{config['output_dir']}/{{sample}}_tpm/{{sample}}.readlength"
    threads: 1
    shell: 
        "awk 'NR%4==2{{sum+=length($0)}}END{{print sum/(NR/4)}}' {input.fwd} > {output}"

rule gene_length:
    input: f"{config['output_dir']}/{{sample}}_tpm/{{sample}}_tpm_prokka/{{sample}}_filtered_prokka.gtf"
    output: f"{config['output_dir']}/{{sample}}_tpm/{{sample}}.genelength"
    threads: 1
    shell: 
        'bash /mnt/seaes01-data01/nixon-microbiome/shared/scripts/get_genelengths.sh {input} {output}'

rule tpm_table:
    input:  
        readlength=f"{config['output_dir']}/{{sample}}_tpm/{{sample}}.readlength",
        genelength=f"{config['output_dir']}/{{sample}}_tpm/{{sample}}.genelength",
        counts=f"{config['output_dir']}/{{sample}}_tpm/{{sample}}.counts"
    output: f"{config['output_dir']}/{{sample}}_tpm/{{sample}}.tpm"
    threads: 1
    shell: 
        'python /mnt/seaes01-data01/nixon-microbiome/shared/scripts/calculate_tpm.py -c {input.counts} -r {input.readlength} -l {input.genelength} -o {output}'

rule merge_tpm_annotation:
    input:  
        tpm=f"{config['output_dir']}/{{sample}}_tpm/{{sample}}.tpm",
        kofam=f"{config['output_dir']}/{{sample}}_tpm/{{sample}}_kofam_oneline.txt",
        prokka=f"{config['output_dir']}/{{sample}}_tpm/{{sample}}_tpm_prokka/{{sample}}_filtered_prokka.tsv"
    output: csv=f"{config['output_dir']}/{{sample}}_tpm/{{sample}}_tpm_annotated.txt"
    threads: workflow.cores
    run:
        import pandas as pd 
        tpm = pd.read_table(input.tpm, header=0, index_col=None)
        kofam_file = pd.read_table(input.kofam, header=None, usecols=[0,1], names=['locus_tag', 'Kofam'], index_col=None)
        prokka_file = pd.read_table(input.prokka, header=0, index_col=None)
        df = pd.merge(tpm, kofam_file, left_on='gene_id', right_on='locus_tag').merge(prokka_file, on='locus_tag')
        df.drop('locus_tag', axis=1, inplace=True)
        df.to_csv(output.csv, sep='\t', index=False)

rule kofam_summary_table:
    input: tpm=f"{config['output_dir']}/{{sample}}_tpm/{{sample}}_tpm_annotated.txt"
    output: summary=f"{config['output_dir']}/{{sample}}_tpm/{{sample}}_kofam_tpm_summary.txt"
    threads: 10
    run:
        import pandas as pd
        df = pd.read_table(input.tpm, header=0, usecols=[0,1,2], index_col=None)
        df_grouped = df.groupby(by="Kofam")["TPM"].sum().reset_index()
        df_grouped.to_csv(output.summary, sep='\t', index=False)

rule collate_outputs_annotation:
    input: expand(f"{config['output_dir']}/{{sample}}_tpm/{{sample}}_tpm_annotated.txt", sample=SAMPLES)
    output: f"{config['output_dir']}/{{sample}}_tpm/all_files_tpm_annotated.txt"
    threads: 10
    run:
        with open(output[0], 'w') as out:
            for i in input:
                sample = i.split('.')[0]
                for line in open(i):
                    out.write(sample + ' ' + line)
