class: CommandLineTool
cwlVersion: v1.2
id: deepvariant_postprocess_variants
doc: |
  Original PacBio WDL: https://github.com/PacificBiosciences/wdl-common/blob/fef058b879d04c15c3da2626b320afdd8ace6c2e/wdl/workflows/deepvariant/deepvariant.wdl
requirements:
  - class: ShellCommandRequirement
  - class: InlineJavascriptRequirement
  - class: InitialWorkDirRequirement
    listing:
      - $(inputs.tfrecord)
      - $(inputs.reference)
      - $(inputs.nonvariant_site_tfrecord_tars)
  - class: ResourceRequirement
    coresMin: $(inputs.threads)
    ramMin: $(inputs.ram*1000) 
  - class: DockerRequirement
    dockerPull: gcr.io/deepvariant-docker/deepvariant:1.5.0
baseCommand: ["/bin/bash", "-c"]
arguments:
  - position: 0
    shellQuote: false
    valueFrom: |
      set -euo pipefail

      for nonvariant_site_tfrecord_tar in $(inputs.nonvariant_site_tfrecord_tars); do
        tar -zxvf $nonvariant_site_tfrecord_tar
      done

      echo "DeepVariant version: 1.5.0"

      /opt/deepvariant/bin/postprocess_variants \
        --vcf_stats_report=false \
        --ref $(inputs.reference) \
        --infile $(inputs.tfrecord) \
        --outfile $(inputs.sample_id).$(inputs.reference_name).deepvariant.vcf.gz \
        --nonvariant_site_tfrecord_path "nonvariant_site_tfrecords/$(inputs.sample_id).gvcf.tfrecord@~$(inputs.total_deepvariant_tasks).gz" \
        --gvcf_outfile $(inputs.sample_id).$(inputs.reference_name).deepvariant.g.vcf.gz

inputs:
  sample_id: { type: 'string' }
  tfrecord: { type: 'File' }
  nonvariant_site_tfrecord_tars: { type: 'File[]' }
  reference: { type: 'File', secondaryFiles: [{pattern: ".fai", required: true}] }
  reference_name: { type: 'string' }
  total_deepvariant_tasks: { type: 'int' }
  threads: { type: 'int?', default: 2, doc: "Number of threads to allocate to this task." }
  ram: { type: 'int?', default: 4, doc: "GB size of RAM to allocate to this task." }


outputs:
  vcf: { type: 'File', outputBinding: { glob: '*.vcf.gz' },  secondaryFiles: ['.vcf.gz.tbi'] }
  gvcf: { type: 'File', outputBinding: { glob: '*.g.vcf.gz' },  secondaryFiles: ['.g.vcf.gz.tbi'] }
