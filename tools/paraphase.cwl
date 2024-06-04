class: CommandLineTool
cwlVersion: v1.2
id: paraphase
doc: |
  Original PacBio WDL: https://github.com/PacificBiosciences/HiFi-human-WGS-WDL/blob/main/workflows/sample_analysis/sample_analysis.wdl
requirements:
  - class: ShellCommandRequirement
  - class: InlineJavascriptRequirement
  - class: ResourceRequirement
    coresMin: $(inputs.threads)
    ramMin: $(inputs.ram*1000)
  - class: DockerRequirement
    dockerPull: quay.io/pacbio/pb-cpg-tools@paraphase@sha256:186dec5f6dabedf8c90fe381cd8f934d31fe74310175efee9ca4f603deac954d
baseCommand: ["/bin/bash", "-c"]
arguments:
  - position: 0
    shellQuote: false
    valueFrom: |
      set -euo pipefail

      paraphase --version

      paraphase \
        --threads $(inputs.threads) \
        --bam $(inputs.bam.path) \
        --reference $(inputs.reference.path) 

inputs:
  bam: { type: 'File', secondaryFiles: [{pattern: ".bai", required: true}] }
  reference: { type: 'File', secondaryFiles: [{pattern: ".fai", required: true}] }
  sample_id: { type: 'string' }
  threads: { type: 'int?', default: 4, doc: "Number of threads to allocate to this task." }
  ram: { type: 'int?', default: 4, doc: "GB size of RAM to allocate to this task." }

outputs:
  output_json: { type: 'File', outputBinding: { glob: '*.json' } }
  realigned_bam: { type: 'File', outputBinding: { glob: '*.bam' }, secondaryFiles: ['.bai'] }
  paraphase_vcfs: { type: 'File[]', outputBinding: { glob: '*.vcf' } }