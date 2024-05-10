cwlVersion: v1.2
class: Workflow
id: deepvariant
doc: | 
  Call variants using DeepVariant. 
  https://github.com/PacificBiosciences/wdl-common/blob/fef058b879d04c15c3da2626b320afdd8ace6c2e/wdl/workflows/deepvariant/deepvariant.wdl
requirements:
- class: ScatterFeatureRequirement
- class: MultipleInputFeatureRequirement
- class: SubworkflowFeatureRequirement
- class: InlineJavascriptRequirement

inputs: 
  sample_id: { type: 'string', doc: "Sample ID; used for naming files" } 
  aligned_bams: { type: 'File[]', secondaryFiles: [{pattern: ".bai", required: true}], doc: "Bam and index aligned to the reference genome for each movie associated with all samples in the cohort" } 
  reference_fasta: { type: 'File', secondaryFiles: [{pattern: ".fai", required: true}], doc: "Reference genome data" }
  deepvariant_model: { type: 'File?', doc: "Optional deepvariant model file to use" }
  total_deepvariant_tasks: { type: 'int?', default: 64}
  num_shards: { type: 'int?', default: 8 }
  # allocations
  make_examples_threads: { type: 'int?', default: 2 }
  call_variant_threads: { type: 'int?', default: 2 }
  postprocess_threads: { type: 'int?', default: 2 }
  postprocess_ram: { type: 'int?', default: 4 }

outputs:
  vcf: { type: 'File', outputSource: postprocess_variants/vcf }
  gvcf: { type: 'File', outputSource: postprocess_variants/gvcf }

steps:
  prepare_indices:
    run: ../tools/prepare_indices.cwl
    in:
      total_deepvariant_tasks: total_deepvariant_tasks
      num_shards: num_shards
    out: [task_indices]

  make_examples:
    run: ../tools/deepvariant_make_examples.cwl
    in: 
      sample_id: sample_id
      aligned_bams: aligned_bams
      reference: reference_fasta
      task_start_index: prepare_indices/task_indices
      tasks_per_shard: 
        valueFrom: $(inputs.total_deepvariant_tasks / inputs.num_shards)
      total_deepvariant_tasks: total_deepvariant_tasks
      threads: make_examples_threads
    scatter: [aligned_bams, task_start_index]
    scatterMethod: flat_crossproduct
    out: [example_tfrecord_tar, nonvariant_site_tfrecord_tar]

  call_variants:
    run: ../tools/deepvariant_call_variants.cwl
    in:
      sample_id: sample_id
      reference_name: 
        valueFrom: $(inputs.reference_fasta.nameroot)
      deepvariant_model: deepvariant_model
      example_tfrecord_tars: make_examples/example_tfrecord_tar
      total_deepvariant_tasks: total_deepvariant_tasks
      threads: call_variant_threads
    out: [tfrecord]

  postprocess_variants:
    run: ../tools/deepvariant_postprocess_variants.cwl
    in:
      sample_id: sample_id
      tfrecord: call_variants/tfrecord
      nonvariant_site_tfrecord_tars: make_examples/nonvariant_site_tfrecord_tar
      reference: reference_fasta
      reference_name:
        valueFrom: $(inputs.reference_fasta.nameroot)
      total_deepvariant_tasks: total_deepvariant_tasks
      threads: postprocess_threads
      ram: postprocess_ram
    out: [vcf, gvcf]

$namespaces:
  sbg: https://sevenbridges.com