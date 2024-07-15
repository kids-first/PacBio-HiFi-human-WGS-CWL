cwlVersion: v1.2
class: Workflow
id: deepvariant
doc: | 
  Call variants using DeepVariant. 
  https://github.com/PacificBiosciences/wdl-common/blob/fef058b879d04c15c3da2626b320afdd8ace6c2e/wdl/workflows/deepvariant/deepvariant.wdl
requirements:
  - class: MultipleInputFeatureRequirement
  - class: SubworkflowFeatureRequirement
  - class: InlineJavascriptRequirement
  - class: StepInputExpressionRequirement

inputs:
  reference: { type: 'File', secondaryFiles: [{pattern: ".fai", required: false}, {pattern: ".gzi", required: false}], doc: "Genome reference FASTA to use. Must have an associated FAI index as well. Supports text or gzipped references. Should match the reference used to align the BAM file provided to the 'reads' input." }
  reads: { type: 'File', secondaryFiles: [{pattern: "^.bai", required: false}, {pattern: ".bai", required: false}], doc: "Aligned, sorted, indexed BAM file containing the reads we want to call. Should be aligned to a reference genome compatible with the FASTA provided on the 'ref' input." }
  num_shards: { type: 'int?', default: 32 }
  sample_name: { type: 'string' }
  # make_examples
  make_examples_cpus_per_job: { type: 'int?', default: 36, doc: "Number of CPUs per job." }
  make_examples_mem_per_job: { type: 'int?', default: 1024, doc: "Memory per job[MB]." }
  # call_variants
  custom_model: { type: 'File?', secondaryFiles: [{pattern: "^.index", required: true}, {pattern: "^.meta", required: true}], doc: "Custom TensorFlow model checkpoint to use to evaluate candidate variant calls. If not provided, the model trained by the DeepVariant team will be used." }
  model:
    type:
      - type: enum
        symbols: ["WGS", "WES", "PACBIO", "HYBRID_PACBIO_ILLUMINA", "ONT_R104"]
    doc: "TensorFlow model checkpoint to use to evaluate candidate variant calls."
    default: "PACBIO"
  call_variants_cpus_per_job: { type: 'int?', default: 36, doc: "Number of CPUs per job." }
  call_variants_mem_per_job: { type: 'int?', default: 1024, doc: "Memory per job[MB]." }
  # postprocess_variants
  qual_filter: { type: 'float?', doc: "Any variant with QUAL < qual_filter will be filtered in the VCF file." }
  cnn_homref_call_min_gq: { type: 'float?', doc: "All CNN RefCalls whose GQ is less than this value will have ./. genotype instead of 0/0." }
  multi_allelic_qual_filter: { type: 'float?', doc: "The qual value below which to filter multi-allelic variants." }
  postprocess_variants_cpus_per_job: { type: 'int?', default: 36, doc: "Number of CPUs per job." }
  postprocess_variants_mem_per_job: { type: 'int?', default: 1024, doc: "Memory per job[MB]." }

outputs:
  vcf: { type: 'File?', outputSource: postprocess_variants/output_vcf }
  gvcf: { type: 'File?', outputSource: postprocess_variants/output_gvcf }

steps:
  make_examples:
    run: ../tools/deepvariant_make_examples.cwl
    in: 
      reference: reference
      reads: reads
      cpus_per_job: make_examples_cpus_per_job
      n_shards: num_shards
      mem_per_job: make_examples_mem_per_job
    out: [example_tfrecord_tar, nonvariant_site_tfrecord_tar]

  call_variants:
    run: ../tools/deepvariant_call_variants.cwl
    in: 
      example_tfrecord_tar: make_examples/example_tfrecord_tar
      custom_model: custom_model
      model: model
      cpus_per_job: call_variants_cpus_per_job
      n_shards: num_shards
      mem_per_job: call_variants_mem_per_job
    out: [variants]

  postprocess_variants:
    run: ../tools/deepvariant_postprocess_variants.cwl
    in:
      variants: call_variants/variants
      sample_name: sample_name
      reference: reference
      qual_filter: qual_filter
      cnn_homref_call_min_gq: cnn_homref_call_min_gq
      multi_allelic_qual_filter: multi_allelic_qual_filter
      nonvariant_site_tfrecord: make_examples/nonvariant_site_tfrecord_tar
      cpus_per_job: postprocess_variants_cpus_per_job
      n_shards: num_shards
      mem_per_job: postprocess_variants_mem_per_job
    out: [output_vcf, output_gvcf]

