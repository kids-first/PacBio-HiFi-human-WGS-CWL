class: CommandLineTool
cwlVersion: v1.2
id: coverage_dropouts
doc: |
  Original PacBio WDL: https://github.com/PacificBiosciences/HiFi-human-WGS-WDL/blob/main/workflows/sample_analysis/sample_analysis.wdl
requirements:
  - class: ShellCommandRequirement
  - class: InlineJavascriptRequirement
  - class: ResourceRequirement
    coresMin: $(inputs.threads)
    ramMin: $(inputs.ram*1000)
  - class: DockerRequirement
    dockerPull: quay.io/pacbio/trgt@sha256:8c9f236eb3422e79d7843ffd59e1cbd9b76774525f20d88cd68ca64eb63054eb
baseCommand: ["/bin/bash", "-c"]
arguments:
  - position: 0
    shellQuote: false
    valueFrom: |
      set -euo pipefail
      
      # Get coverage dropouts
      check_trgt_coverage.py \
        $(inputs.tandem_repeat_bed.path) \
        $(inputs.bam.path) \
      > $(inputs.sample_id).trgt.dropouts.txt

inputs:
  bam: { type: 'File', secondaryFiles: [{pattern: ".bai", required: true}] }
  tandem_repeat_bed: { type: 'File' }
  sample_id: { type: 'string?' }
  threads: { type: 'int?', default: 2, doc: "Number of threads to allocate to this task." }
  ram: { type: 'int?', default: 4, doc: "GB size of RAM to allocate to this task." }

outputs:
  trgt_dropouts: { type: 'File', outputBinding: { glob: '*.txt' } }