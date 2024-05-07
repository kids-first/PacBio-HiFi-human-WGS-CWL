class: CommandLineTool
cwlVersion: v1.2
id: merge_bams
doc: |
  Original PacBio WDL: https://github.com/PacificBiosciences/HiFi-human-WGS-WDL/blob/main/workflows/sample_analysis/sample_analysis.wdl
requirements:
  - class: ShellCommandRequirement
  - class: InlineJavascriptRequirement
  - class: ResourceRequirement
    coresMin: $(inputs.threads)
    ramMin: $(inputs.ram*1000)
  - class: DockerRequirement
    dockerPull: quay.io/pacbio/samtools@sha256:cbe496e16773d4ad6f2eec4bd1b76ff142795d160f9dd418318f7162dcdaa685
baseCommand: ["/bin/bash", "-c"]
arguments:
  - position: 0
    shellQuote: false
    valueFrom: |
      set -euo pipefail

      samtools --version

      samtools merge \
        -@ ${ return inputs.threads - 1 } \
        -o $(inputs.output_bam_name) \
        $(inputs.bams_to_merge)

      samtools index $(inputs.output_bam_name)

inputs:
  bams_to_merge: { type: 'File[]' }
  output_bam_name: { type: 'string' }
  threads: { type: 'int?', default: 8, doc: "Number of threads to allocate to this task." }
  ram: { type: 'int?', default: 4, doc: "GB size of RAM to allocate to this task." }

outputs:
  merged_bam: { type: 'File', outputBinding: { glob: '*.bam' }, secondaryFiles: ['.bai'] }
