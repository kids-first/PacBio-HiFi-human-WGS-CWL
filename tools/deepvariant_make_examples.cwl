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
    ramMin: $(inputs.ram*1000) 
  - class: DockerRequirement
    dockerPull: gcr.io/deepvariant-docker/deepvariant:1.5.0
baseCommand: ["/bin/bash", "-c"]
arguments:


inputs:
  sample_id: { type: 'string' }
  aligned_bam: { type: 'File', secondaryFiles: [{pattern: ".bai", required: true}] }
  reference: { type: 'File', secondaryFiles: [{pattern: ".fai", required: true}] }
  task_start_index: { type: 'int' }
  tasks_per_shard: { type: 'int' }
  total_deepvariant_tasks: { type: 'int' }
  threads: { type: 'int?', default: 4, doc: "Number of threads to allocate to this task." }
  ram: { type: 'int?', default: 8, doc: "GB size of RAM to allocate to this task." }

outputs:
  example_tfrecord_tar: { type: 'File', outputBinding: { glob: '*.example_tfrecords.tar.gz' } }
  nonvariant_site_tfrecord_tar: { type: 'File', outputBinding: { glob: '*.nonvariant_site_tfrecords.tar.gz' } }
