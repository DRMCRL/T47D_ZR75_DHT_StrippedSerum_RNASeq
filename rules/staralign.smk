rule star_pe:
    input:
        fq1 = "data/trimmed/fastq/{sample}" + r1 + tag + ext,
        fq2 = "data/trimmed/fastq/{sample}" + r2 + tag + ext,
        index = rules.star_index.output
    output:
        bam = temp("data/aligned/bam/{sample}/Aligned.sortedByCoord.out.bam"),
        logs = "data/aligned/bam/{sample}/Log.final.out"
    conda:
        "../envs/star.yml"
    log:
        "logs/star/{sample}.log"
    params:
        extra = config['star']['align_extra']
    threads: 4
    script:
        "../scripts/star_alignment.py"

rule index_bam:
    input:
        rules.star_pe.output.bam
    output:
        temp("data/aligned/bam/{sample}/Aligned.sortedByCoord.out.bam.bai")
    conda:
        "../envs/samtools.yml"
    threads: 1
    shell:
        """
        samtools index "{input}" "{output}"
        """

