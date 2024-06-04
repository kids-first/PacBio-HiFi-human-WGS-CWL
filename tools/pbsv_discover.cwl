class: CommandLineTool
cwlVersion: v1.2
id: pbsv_discover
doc: |
  For each aligned BAM or set of aligned BAMs, identify signatures of structural variation. This reduces all aligned reads to those that are relevant to calling structural variants. 
  The signatures are stored in a .svsig.gz file.
  
  Original PacBio WDL: https://github.com/PacificBiosciences/wdl-common/blob/fef058b879d04c15c3da2626b320afdd8ace6c2e/wdl/tasks/pbsv_discover.wdl
requirements:
  - class: ShellCommandRequirement
  - class: InlineJavascriptRequirement
  - class: ResourceRequirement
    coresMin: $(inputs.cpu)
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

      pbsv discover \
        --log-level INFO \
        --hifi \
        --tandem-repeats $(inputs.reference_tandem_repeat_bed.path) \
        $(inputs.aligned_bam.path) \
        $(inputs.aligned_bam.nameroot).svsig.gz

inputs:
  aligned_bam: { type: 'File', secondaryFiles: [{pattern: ".bai", required: true}] }
  reference_tandem_repeat_bed: { type: 'File' }
  cpu: { type: 'int?', default: 2, doc: "Number of threads to allocate to this task." }
  ram: { type: 'int?', default: 8, doc: "GB size of RAM to allocate to this task." }


outputs:
  svsig: { type: 'File', outputBinding: { glob: '*.gz' } }