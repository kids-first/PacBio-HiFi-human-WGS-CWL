class: CommandLineTool
cwlVersion: v1.2
id: cpg_pileup
doc: |
  Original PacBio WDL: https://github.com/PacificBiosciences/HiFi-human-WGS-WDL/blob/main/workflows/sample_analysis/sample_analysis.wdl
requirements:
  - class: ShellCommandRequirement
  - class: InlineJavascriptRequirement
  - class: ResourceRequirement
    coresMin: $(inputs.threads)
    ramMin: $(inputs.threads*4000) # Uses ~4 GB memory / thread
  - class: DockerRequirement
    dockerPull: quay.io/pacbio/pb-cpg-tools@sha256:b95ff1c53bb16e53b8c24f0feaf625a4663973d80862518578437f44385f509b
baseCommand: ["/bin/bash", "-c"]
arguments:
  - position: 0
    shellQuote: false
    valueFrom: |
      set -euo pipefail

      aligned_bam_to_cpg_scores --version

      aligned_bam_to_cpg_scores \
        --threads $(inputs.threads) \
        --bam $(inputs.bam) \
        --ref $(inputs.reference) \
        --output-prefix $(inputs.output_prefix) \
        --min-mapq 1 \
        --min-coverage 10 \
        --model "$PILEUP_MODEL_DIR"/pileup_calling_model.v1.tflite

inputs:
  bam: { type: 'File', secondaryFiles: [{pattern: ".bai", required: true}] }
  reference: { type: 'File', secondaryFiles: [{pattern: ".fai", required: true}] }
  output_prefix: { type: 'string' }
  threads: { type: 'int?', default: 12, doc: "Number of threads to allocate to this task." }

outputs:
  pileup_beds: { type: 'File[]', outputBinding: { glob: '*.bed' } }
  pileup_bigwigs: { type: 'File[]', outputBinding: { glob: '*.bw' } }