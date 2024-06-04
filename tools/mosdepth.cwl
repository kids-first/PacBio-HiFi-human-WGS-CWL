class: CommandLineTool
cwlVersion: v1.2
id: mosdepth
doc: |
  Calculate summary stats using mosdepth

  Original PacBio WDL: https://github.com/PacificBiosciences/wdl-common/blob/fef058b879d04c15c3da2626b320afdd8ace6c2e/wdl/tasks/mosdepth.wdl
requirements:
  - class: ShellCommandRequirement
  - class: InlineJavascriptRequirement
  - class: ResourceRequirement
    coresMin: $(inputs.threads)
    ramMin: $(inputs.ram*1000)
  - class: DockerRequirement
    dockerPull: quay.io/pacbio/mosdepth@sha256:35d5e02facf4f38742e5cae9e5fdd3807c2b431dd8d881fd246b55e6d5f7f600
baseCommand: ["/bin/bash", "-c"]
arguments:
  - position: 0
    shellQuote: false
    valueFrom: |
      set -euo pipefail

      mosdepth --version

      mosdepth \
        --threads ${ return inputs.threads - 1 } \
        --by 500 \
        --no-per-base \
        --use-median \
        $(inputs.aligned_bam.nameroot) \
        $(inputs.aligned_bam.path)

inputs:
  aligned_bam: { type: 'File', secondaryFiles: [{pattern: ".bai", required: true}] }
  threads: { type: 'int?', default: 4, doc: "Number of threads to allocate to this task." }
  ram: { type: 'int?', default: 8, doc: "GB size of RAM to allocate to this task." }

outputs:
  summary: { type: 'File', outputBinding: { glob: '*.summary.txt' } }
  region_bed: { type: 'File', outputBinding: { glob: '*.bed.gz' } }
