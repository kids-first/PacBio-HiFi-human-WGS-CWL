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
  reads: { type: 'File', secondaryFiles: [{pattern: "^.bai", required: false}, {pattern: ".bai", required: false}, {pattern: "^.crai", required: false}, {pattern: ".crai", required: false}], doc: "Aligned, sorted, indexed BAM/CRAM file containing the reads we want to call. Should be aligned to a reference genome compatible with the FASTA provided on the 'ref' input." }
  num_shards: { type: 'int?', default: 32 }
  sample_name: { type: 'string' }
  # make_examples
  make_examples_cpu: { type: 'int?', default: 36, doc: "CPUs to allocate to this task" }
  make_examples_ram: { type: 'int?', default: 40, doc: "GB of RAM to allocate to this task." }
  # call_variants
  custom_model: { type: 'File?', secondaryFiles: [{pattern: "^.index", required: true}, {pattern: "^.meta", required: true}], doc: "Custom TensorFlow model checkpoint to use to evaluate candidate variant calls. If not provided, the model trained by the DeepVariant team will be used." }
  model:
    type:
      - type: enum
        symbols: ["WGS", "WES", "PACBIO", "HYBRID_PACBIO_ILLUMINA", "ONT_R104"]
    doc: "TensorFlow model checkpoint to use to evaluate candidate variant calls."
    default: "PACBIO"
  call_variants_cpu: { type: 'int?', default: 36, doc: "CPUs to allocate to this task" }
  call_variants_ram: { type: 'int?', default: 60, doc: "GB of RAM to allocate to this task." }
  # postprocess_variants
  qual_filter: { type: 'float?', doc: "Any variant with QUAL < qual_filter will be filtered in the VCF file." }
  cnn_homref_call_min_gq: { type: 'float?', doc: "All CNN RefCalls whose GQ is less than this value will have ./. genotype instead of 0/0." }
  multi_allelic_qual_filter: { type: 'float?', doc: "The qual value below which to filter multi-allelic variants." }
  postprocess_variants_cpu: { type: 'int?', default: 36, doc: "CPUs to allocate to this task" }
  postprocess_variants_ram: { type: 'int?', default: 40, doc: "GB of RAM to allocate to this task." }

outputs:
  vcf: { type: 'File?', outputSource: postprocess_variants/output_vcf }
  gvcf: { type: 'File?', outputSource: postprocess_variants/output_gvcf }

steps:
  make_examples:
    run: ../tools/deepvariant_make_examples.cwl
    in: 
      reference: reference
      reads: reads
      cpu: make_examples_cpu
      n_shards: num_shards
      ram: make_examples_ram
    out: [example_tfrecord_tar, nonvariant_site_tfrecord_tar]

  call_variants:
    run: ../tools/deepvariant_call_variants.cwl
    in: 
      example_tfrecord_tar: make_examples/example_tfrecord_tar
      custom_model: custom_model
      model: model
      cpu: call_variants_cpu
      n_shards: num_shards
      ram: call_variants_ram
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
      cpu: postprocess_variants_cpu
      n_shards: num_shards
      ram: postprocess_variants_ram
    out: [output_vcf, output_gvcf]

