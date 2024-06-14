class: CommandLineTool
cwlVersion: v1.2
id: bcftools_index
doc: |
  Zip and index a VCF file. 
requirements:
  - class: ShellCommandRequirement
  - class: InlineJavascriptRequirement
  - class: ResourceRequirement
    coresMin: $(inputs.threads)
    ramMin: $(inputs.ram*1000) 
  - class: DockerRequirement
    dockerPull: quay.io/pacbio/bcftools@sha256:36d91d5710397b6d836ff87dd2a924cd02fdf2ea73607f303a8544fbac2e691f
baseCommand: ["/bin/bash", "-c"]
arguments:
  - position: 0
    shellQuote: false
    valueFrom: |
      set -euo pipefail

      bgzip -c $(inputs.vcf.path) > $(inputs.vcf.nameroot).vcf.gz

      bcftools index --tbi $(inputs.vcf.nameroot).vcf.gz

inputs:
  vcf: { type: 'File' }
  threads: { type: 'int?', default: 2, doc: "Number of threads to allocate to this task." }
  ram: { type: 'int?', default: 4, doc: "GB size of RAM to allocate to this task." }

outputs:
  zipped_vcf: { type: 'File', outputBinding: { glob: '*.gz' }, secondaryFiles: ['.tbi'] }