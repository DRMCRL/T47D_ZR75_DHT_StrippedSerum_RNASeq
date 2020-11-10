import pandas as pd
import os.path
import re

configfile: "config/config.yml"

##########################################
## Config information for the reference ##
##########################################
species = config['ref']['species']
build = config['ref']['build']
release = str(config['ref']['release'])
seqtype = config['ref']['seqtype']

# Define the path for the reference
ens_full = "ensembl-release-" + release
ref_root = os.path.join(config['ref']['root'], ens_full, species)
ref_fa = species.capitalize() + "." + build + "." + "dna." + seqtype + ".fa"
ref_path = os.path.join(ref_root, 'dna', ref_fa)

# Define the path for the GTF annotation
# By default, the wrapper will extract the file
gtf = species.capitalize() + "." + build + "." + release + ".gtf"
gtf_path = os.path.join(ref_root, gtf)
star_dir = os.path.join(ref_root, 'dna', 'star')

########################################
## Config information for the samples ##
########################################
ext = config['ext']
tag = config['tags']['tag']
r1 = config['tags']['r1']
r2 = config['tags']['r2']
samples = pd.read_table(config["samples"])
samples['id'] = samples['id'].apply(str)
sample_id = samples['id'] + "/" + samples['sample']
runs = re.split(r" ", config['runs'])
counts_file = "data/aligned/counts/counts.out"
merged_counts = "data/aligned/counts/merged_counts.out"

########################
## Define all outputs ##
########################
ALL_RULEGRAPH = expand(["rules/rulegraph.{suffix}"],
                       suffix = ['dot', 'pdf'])
ALL_REFS = [ref_path, gtf_path, star_dir]
ALL_TRIMMED = expand(["data/trimmed/fastq/{run}/{sample}{reads}" + tag + ext],
                      run = runs,
                      reads = [r1, r2],
                      sample = sample_id)
ALL_FQC = expand(["data/{step}/FastQC/{run}/{sample}{reads}{tag}_fastqc.{suffix}"],
                 suffix = ['zip', 'html'],
                 tag = tag,
                 reads = [r1, r2],
                 sample = sample_id,
                 run = runs,
                 step = ['raw', 'trimmed'])
ALL_ALN = expand(["data/aligned/bam/{run}/{sample}/{file}"],
                 run = runs,
                 file = ['Aligned.sortedByCoord.out.bam','Log.final.out'],
                 sample = sample_id)
ALL_WORKFLOWR = expand(["docs/{step}.html"],
                      step = ['description', 'index', 'qc_raw', 'qc_trimmed', 'qc_aligned'])
ALL_ANALYSIS = expand(["docs/{cellline}_{file}"],
                      cellline = ['t47d', 'zr75'],
                      file = ['dge_analysis.html', 'DHT_StrippedSerum_RNASeq_topTable.tsv',
                              'DHT_StrippedSerum_RNASeq_logCPM.tsv'])                     

## Collect them into a single object
ALL_OUTPUTS = []
ALL_OUTPUTS.extend(ALL_RULEGRAPH)
ALL_OUTPUTS.extend(ALL_REFS)
ALL_OUTPUTS.extend(ALL_TRIMMED)
ALL_OUTPUTS.extend(ALL_FQC)
ALL_OUTPUTS.extend(ALL_ALN)
ALL_OUTPUTS.extend([merged_counts])
ALL_OUTPUTS.extend(ALL_WORKFLOWR)
ALL_OUTPUTS.extend(ALL_ANALYSIS)

# And the rules
rule all:
    input:
        ALL_OUTPUTS

include: "rules/refs.smk"
include: "rules/rulegraph.smk"
include: "rules/qc.smk"
include: "rules/trimming.smk"
include: "rules/staralign.smk"
include: "rules/count.smk"
include: "rules/workflowr.smk"
