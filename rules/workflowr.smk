rule create_site_yaml:
    output: "analysis/_site.yml"
    conda: "../envs/workflowr.yml"
    log: "logs/workflowr/create_site_yaml.log"
    threads: 1
    script: "../scripts/generateSiteYAML.R"

rule make_rproj:
    output: os.path.basename(os.getcwd() + ".Rproj")
    threads: 1
    shell:
        """
        if [[ ! -f {output} ]]; then
          echo -e "Version: 1.0\n" > {output}
          echo -e "RestoreWorkspace: Default\nSaveWorkspace: Default\nAlwaysSaveHistory: Default\n" >> {output}
          echo -e "EnableCodeIndexing: Yes\nUseSpacesForTab: Yes\nNumSpacesForTab: 2\nEncoding: UTF-8\n" >> {output}
          echo -e "RnwWeave: knitr\nLaTeX: pdfLaTeX\n" >> {output}
          echo -e "AutoAppendNewline: Yes\nStripTrailingWhitespace: Yes" >> {output}
        fi
        """

rule build_wflow_description:
    input:
        yaml = rules.create_site_yaml.output,
        dot = rules.make_rulegraph.output.dot,
        rmd = "analysis/description.Rmd",
        rproj = rules.make_rproj.output
    output:
        html = "docs/description.html"
    conda:
        "../envs/workflowr.yml"
    log:
        "logs/workflowr/description.log"
    threads: 1
    shell:
       """
       R -e "workflowr::wflow_build('{input.rmd}')" 2>&1 > {log}
       """

rule build_qc_raw:
    input:
        yaml = rules.create_site_yaml.output,
        fqc = expand(["data/raw/FastQC/{run}/{sample}{reads}{tag}_fastqc.zip"],
                     tag = tag, run = runs, reads = [r1, r2], sample = sample_id),
        rmd = "analysis/qc_raw.Rmd",
        rproj = rules.make_rproj.output
    output:
        html = "docs/qc_raw.html"
    conda:
        "../envs/workflowr.yml"
    log:
        "logs/workflowr/qc_raw.log"
    threads: 1
    shell:
       """
       R -e "workflowr::wflow_build('{input.rmd}')" 2>&1 > {log}
       """

rule build_qc_trimmed:
    input:
        yaml = rules.create_site_yaml.output,
        fqc = expand(["data/trimmed/FastQC/{run}/{sample}{reads}{tag}_fastqc.zip"],
                     tag = tag, reads = [r1, r2], run = runs, sample = sample_id),
        rmd = "analysis/qc_trimmed.Rmd",
        rproj = rules.make_rproj.output
    output:
        html = "docs/qc_trimmed.html"
    conda:
        "../envs/workflowr.yml"
    log:
        "logs/workflowr/qc_trimmed.log"
    threads: 1
    shell:
       """
       R -e "workflowr::wflow_build('{input.rmd}')" 2>&1 > {log}
       """

rule build_qc_aligned:
    input:
        yaml = rules.create_site_yaml.output,
        counts = rules.merge_counts.output,
        aln_logs = expand(["data/aligned/bam/{run}/{sample}/Log.final.out"],
                          run = runs, sample = sample_id),
        rmd = "analysis/qc_aligned.Rmd",
        rproj = rules.make_rproj.output
    output:
        html = "docs/qc_aligned.html",
        rds = "output/genesGR.rds"
    conda:
        "../envs/workflowr.yml"
    log:
        "logs/workflowr/qc_aligned.log"
    threads: 1
    shell:
       """
       R -e "workflowr::wflow_build('{input.rmd}')" 2>&1 > {log}
       """

rule build_dge_analysis:
    input:
        yaml = rules.create_site_yaml.output,
        counts = rules.merge_counts.output,
        rds = rules.build_qc_aligned.output.rds,
        rmd = "analysis/{cellline}_dge_analysis.Rmd",
        rproj = rules.make_rproj.output
    output:
        html = "docs/{cellline}_dge_analysis.html",
        toptab = "output/{cellline}_DHT_StrippedSerum_RNASeq_topTable.tsv",
        cpm =  "output/{cellline}_DHT_StrippedSerum_RNASeq_logCPM.tsv",
        rds = "ouput/{cellline}_dge.rds"
    conda:
        "../envs/workflowr.yml"
    log:
        "logs/workflowr/{cellline}_dge_analysis.log"
    threads: 2
    shell:
       """
       R -e "workflowr::wflow_build('{input.rmd}')" 2>&1 > {log}
       """
       

rule build_enrichment_analysis:
    input:
        toptab = rules.build_dge_analysis.output.toptab,
        rds = rules.build_dge_analysis.output.rds,
        rmd = "analysis/{cellline}_enrichment.Rmd"
    output:
        html = "docs/{cellline}_enrichment.html"
    conda:
        "../envs/workflowr.yml"
    log:
        "logs/workflowr/{cellline}_enrichment.log"
    threads: 2
    shell:
       """
       R -e "workflowr::wflow_build('{input.rmd}')" 2>&1 > {log}
       """       

rule build_wflow_site_index:
    input:
        yaml = rules.create_site_yaml.output,
        rmd = "analysis/index.Rmd",
        desc = rules.build_wflow_description.output.html,
        raw = rules.build_qc_raw.output.html,
        trimmed = rules.build_qc_trimmed.output.html,
        aligned = rules.build_qc_aligned.output.html,
        dge = expand(["docs/{cellline}_dge_analysis.html"], cellline = ['t47d', 'zr75']),
        enrich = expand(["docs/{cellline}_enrichment.html"], cellline = ['t47d', 'zr75']),
        rproj = rules.make_rproj.output
    output:
        html = "docs/index.html"
    conda:
        "../envs/workflowr.yml"
    log:
        "logs/workflowr/index.log"
    threads: 1
    shell:
       """
       R -e "workflowr::wflow_build('{input.rmd}')" 2>&1 > {log}
       """
