rule count:
    input:
        bams = expand(["data/aligned/bam/{run}/{sample}/Aligned.sortedByCoord.out.bam"],
                      run = runs,
                      sample = sample_id),
        gtf = rules.get_annotation.output
    output:
        counts_file
    conda:
        "../envs/subread.yml"
    threads: 4
    params:
        fracOverlap = config['featureCounts']['fracOverlap'],
        q = config['featureCounts']['minQual'],
        s = config['featureCounts']['strandedness'],
        extra = config['featureCounts']['extra']
    shell:
       """
       featureCounts \
         {params.extra} \
         -Q {params.q} \
         -s {params.s} \
         --fracOverlap {params.fracOverlap} \
         -T {threads} \
         -a {input.gtf} \
         -o {output} \
         "{input.bams}"
       """
