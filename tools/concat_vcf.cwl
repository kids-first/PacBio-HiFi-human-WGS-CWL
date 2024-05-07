class: CommandLineTool
cwlVersion: v1.2
id: concat_vcf
doc: |
  Original PacBio WDL: https://github.com/PacificBiosciences/wdl-common/blob/fef058b879d04c15c3da2626b320afdd8ace6c2e/wdl/tasks/concat_vcf.wdl
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

      mkdir -p vcfs

      for input in $(inputs.vcfs); do
        ln -s "$input" vcfs/$(basename "$input")
      done 

      find vcfs -name "*.vcf.gz" > vcf.list

      bcftools --version

      bcftools concat \
        --allow-overlaps \
        --threads ${ return inputs.threads - 1 } \
        --output-type z \
        --output $(inputs.output_vcf_name) \
        --file-list vcf.list

      bcftools index --tbi $(inputs.output_vcf_name)

inputs:
  vcfs:
    type: File[]
    secondaryFiles: ['.tbi']
    inputBinding:
      prefix: ''
      valueFrom: |
        ${
          return inputs.vcfs.map(vcf => {
            return vcf.path;
          }).join(" ");
        }
  output_vcf_name: { type: 'string' }
  threads: { type: 'int?', default: 4, doc: "Number of threads to allocate to this task." }
  ram: { type: 'int?', default: 8, doc: "GB size of RAM to allocate to this task." }

outputs:
  concatenated_vcf: { type: 'File', outputBinding: { glob: '*.gz' }, secondaryFiles: ['.tbi'] }