class: CommandLineTool
cwlVersion: v1.2
id: pbmm2_align
doc: |
  pbmm2 is a SMRT C++ wrapper for minimap2's C API. Its purpose is to support
  native PacBio in- and output, provide sets of recommended parameters, generate
  sorted output on-the-fly, and postprocess alignments. Sorted output can be used
  directly for polishing using GenomicConsensus, if BAM has been used as input to
  pbmm2. Benchmarks show that pbmm2 outperforms BLASR in sequence identity,
  number of mapped bases, and especially runtime. pbmm2 is the official
  replacement for BLASR.

  Original PacBio WDL: https://github.com/PacificBiosciences/HiFi-human-WGS-WDL/blob/main/workflows/sample_analysis/sample_analysis.wdl
requirements:
  - class: ShellCommandRequirement
  - class: InlineJavascriptRequirement
  - class: ResourceRequirement
    coresMin: $(inputs.threads)
    ramMin: ${
      return Math.ceil(inputs.threads * 4)
     } 
  - class: DockerRequirement
    dockerPull: quay.io/pacbio/pbmm2@sha256:1013aa0fd5fb42c607d78bfe3ec3d19e7781ad3aa337bf84d144c61ed7d51fa1
baseCommand: ["/bin/bash", "-c"]
arguments:
  - position: 0
    shellQuote: false
    valueFrom: |
      set -euo pipefail

      pbmm2 --version

      pbmm2 align \
        --num-threads $(inputs.threads) \
        --sort-memory 4G \
        --preset HIFI \
        --sample $(inputs.sample_id) \
        --log-level INFO \
        --sort \
        --unmapped \
        $(inputs.reference) \
        $(inputs.bam) \
        $(inputs.sample_id).$(inputs.bam.nameroot).$(inputs.reference_name).aligned.bam

      # movie stats
      extract_read_length_and_qual.py \
        $(inputs.bam) \
      > $(inputs.sample_id).$(inputs.bam.nameroot).read_length_and_quality.tsv

      awk '{{ b=int($2/1000); b=(b>39?39:b); print 1000*b "\t" $2; }}' \
        $(inputs.sample_id).$(inputs.bam.nameroot).read_length_and_quality.tsv \
        | sort -k1,1g \
        | datamash -g 1 count 1 sum 2 \
        | awk 'BEGIN {{ for(i=0;i<=39;i++) {{ print 1000*i"\t0\t0"; }} }} {{ print; }}' \
        | sort -k1,1g \
        | datamash -g 1 sum 2 sum 3 \
      > $(inputs.sample_id).$(inputs.bam.nameroot).read_length_summary.tsv

      awk '{{ print ($3>50?50:$3) "\t" $2; }}' \
            $(inputs.sample_id).$(inputs.bam.nameroot).read_length_and_quality.tsv \
        | sort -k1,1g \
        | datamash -g 1 count 1 sum 2 \
        | awk 'BEGIN {{ for(i=0;i<=60;i++) {{ print i"\t0\t0"; }} }} {{ print; }}' \
        | sort -k1,1g \
        | datamash -g 1 sum 2 sum 3 \
      > $(inputs.sample_id).$(inputs.bam.nameroot).read_quality_summary.tsv

inputs:
  sample_id: { type: 'string' }
  bam: { type: 'File' }
  reference: { type: 'File', secondaryFiles: [{pattern: ".fai", required: true}] }
  reference_name: { type: 'string' }
  threads: { type: 'int?', default: 24, doc: "Number of threads to allocate to this task." }

outputs:
  output_bam: { type: 'File', outputBinding: { glob: '*.bam' }, secondaryFiles: ['.bai'] }
  bam_stats: { type: 'File', outputBinding: { glob: '*.read_length_and_quality.tsv' } }
  read_length_summary: { type: 'File', outputBinding: { glob: '*.read_length_summary.tsv' } }
  read_quality_summary: { type: 'File', outputBinding: { glob: '*.read_quality_summary.tsv' } }
