class: CommandLineTool
cwlVersion: v1.2
id: pbsv_call
doc: |
  Detect and annotate structural variants

  Original PacBio WDL: https://github.com/PacificBiosciences/wdl-common/blob/fef058b879d04c15c3da2626b320afdd8ace6c2e/wdl/tasks/pbsv_call.wdl
requirements:
  - class: ShellCommandRequirement
  - class: InlineJavascriptRequirement
  - class: ResourceRequirement
    coresMin: $(inputs.threads)
    ramMin: $(inputs.ram*1000)
  - class: DockerRequirement
    dockerPull: quay.io/pacbio/pbsv@sha256:d78ee6deb92949bdfde98d3e48dab1d871c177d48d8c87c73d12c45bdda43446
baseCommand: ["/bin/bash", "-c"]
arguments:
  - position: 0
    shellQuote: false
    valueFrom: |
      set -euo pipefail
      
      pbsv --version

      pbsv call \
        --hifi \
        --min-sv-length 20 \
        --log-level INFO \
        --num-threads $(inputs.threads) \
        $(inputs.reference.path) \
        $(inputs.svsigs.path) \
        $(inputs.sample_id).pbsv_call.vcf

      bgzip --version

      bgzip $(inputs.sample_id).pbsv_call.vcf

      tabix --version

      tabix -p vcf $(inputs.sample_id).pbsv_call.vcf.gz

inputs:
  svsigs: { type: 'File', doc: "SV signatures from one or more samples. Can be svsig.gz file or file of filenames." }
  sample_id: { type: 'string' }
  reference: { type: 'File', secondaryFiles: [{pattern: ".fai", required: true}] }
  threads: { type: 'int?', default: 2, doc: "Number of threads to allocate to this task." }
  ram: { type: 'int?', default: 4 }

outputs:
  pbsv_vcf: { type: 'File', outputBinding: { glob: '*.gz' }, secondaryFiles: ['.tbi'] }
