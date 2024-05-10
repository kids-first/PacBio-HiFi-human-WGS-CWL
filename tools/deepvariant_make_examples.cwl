class: CommandLineTool
cwlVersion: v1.2
id: deepvariant_make_examples
doc: |
  Original PacBio WDL: https://github.com/PacificBiosciences/wdl-common/blob/fef058b879d04c15c3da2626b320afdd8ace6c2e/wdl/workflows/deepvariant/deepvariant.wdl
requirements:
  - class: ShellCommandRequirement
  - class: InlineJavascriptRequirement
  - class: ResourceRequirement
    coresMin: $(inputs.threads)
    ramMin: $(inputs.tasks_per_shard*4000) # Int mem_gb = tasks_per_shard * 4
  - class: DockerRequirement
    dockerPull: gcr.io/deepvariant-docker/deepvariant:1.5.0
baseCommand: ["/bin/bash", "-c"]
arguments:
  - position: 0
    shellQuote: false
    valueFrom: |
      set -euo pipefail

      mkdir -p example_tfrecords nonvariant_site_tfrecords

      echo "DeepVariant version: 1.5.0"

      seq $(inputs.task_start_index) $(inputs.task_start_index + inputs.tasks_per_shard - 1) | parallel \
        --jobs $(inputs.tasks_per_shard) \
        --halt 2 \
        /opt/deepvariant/bin/make_examples \
          --norealign_reads \
          --vsc_min_fraction_indels 0.12 \
          --pileup_image_width 199 \
          --track_ref_reads \
          --phase_reads \
          --partition_size=25000 \
          --max_reads_per_partition=600 \
          --alt_aligned_pileup=diff_channels \
          --add_hp_channel \
          --sort_by_haplotypes \
          --parse_sam_aux_fields \
          --min_mapping_quality=1 \
          --mode calling \
          --ref $(inputs.reference) \
          --reads $(inputs.aligned_bams.map(file => file.path).join(',')) \
          --examples example_tfrecords/$(inputs.sample_id).examples.tfrecord@$(inputs.total_deepvariant_tasks).gz \
          --gvcf nonvariant_site_tfrecords/$(inputs.sample_id).gvcf.tfrecord@$(inputs.total_deepvariant_tasks).gz \
          --task {} 
      
      tar -zcvf $(inputs.sample_id).$(inputs.task_start_index).example_tfrecords.tar.gz example_tfrecords
      tar -zcvf ~$(inputs.sample_id).$(inputs.task_start_index).nonvariant_site_tfrecords.tar.gz nonvariant_site_tfrecords

inputs:
  sample_id: { type: 'string' }
  aligned_bams: { type: 'File[]', secondaryFiles: [{pattern: ".bai", required: true}] }
  reference: { type: 'File', secondaryFiles: [{pattern: ".fai", required: true}] }
  task_start_index: { type: 'int' }
  tasks_per_shard: { type: 'int' }
  total_deepvariant_tasks: { type: 'int' }
  threads: { type: 'int?', default: 2, doc: "Number of threads to allocate to this task." }

outputs:
  example_tfrecord_tar: { type: 'File', outputBinding: { glob: '*.example_tfrecords.tar.gz' } }
  nonvariant_site_tfrecord_tar: { type: 'File', outputBinding: { glob: '*.nonvariant_site_tfrecords.tar.gz' } }
