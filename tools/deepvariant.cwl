class: CommandLineTool
cwlVersion: v1.2
id: deepvariant_single_command
doc: |
  This script currently provides the most common use cases and standard models.
  If you want to access more flags that are available in `make_examples`,
  `call_variants`, and `postprocess_variants`, you can also call them separately
  using the binaries in the Docker image.

  For more details, see:
  https://github.com/google/deepvariant/blob/r1.5/docs/deepvariant-quick-start.md
requirements:
  - class: ShellCommandRequirement
  - class: InlineJavascriptRequirement
  - class: ResourceRequirement
    coresMin: $(inputs.num_shards)
  - class: DockerRequirement
    dockerPull: gcr.io/deepvariant-docker/deepvariant:1.5.0
baseCommand: [/opt/deepvariant/bin/run_deepvariant]
arguments:
    - position: 99
      prefix: ''
      shellQuote: false
      valueFrom: |
        1>&2

inputs:
  # Required arguments
  reads: { type: 'File', inputBinding: { prefix: "--reads", position: 40 }, doc: "Aligned, sorted, indexed BAM file containing the reads we want to call. Should be aligned to a reference genome compatible with --ref." }
  ref: { type: 'File', inputBinding: { prefix: "--ref", position: 50 }, doc: "Genome reference to use. Must have an associated FAI index as well. Supports text or gzipped references. Should match the reference used to align the BAM file provided to --reads." }
  sample_name: { type: 'string', inputBinding: { prefix: "--sample_name", position: 60 }, doc: "This flag is used for both make_examples and postprocess_variants." }
  model_type:
    type:
      - type: enum
        name: model_type
        symbols: ["WGS","WES","PACBIO", "ONT_R104", "HYBRID_PACBIO_ILLUMINA"]
    inputBinding:
      prefix: "--model_type"
      position: 70
    doc: |
      Required. Type of model to use for variant calling. Set this flag to use the default model
      associated with each type, and it will set necessary flags corresponding to
      each model. If you want to use a customized model, add --customized_model
      flag in addition to this flag.
  output_vcf: { type: 'string?', default: "deepvariant_output.vcf.gz", inputBinding: { prefix: "--output_vcf", position: 80 } }
  output_gvcf: { type: 'string?', default: "deepvariant_output.gvcf.gz", inputBinding: { prefix: "--output_gvcf", position: 90 } }

# Optional arguments
  call_variants_extra_args: { type: 'File?', inputBinding: { prefix: "--call_variants_extra_args", position: 1 }, doc: "A comma-separated list of flag_name=flag_value. 'flag_name' has to be valid flags for call_variants.py. If the flag_value is boolean, it has to be flag_name=true or flag_name=false." }
  customized_model: { type: 'File?', inputBinding: { prefix: "--customized_model", position: 1 }, doc: "A path to a model checkpoint to load for the 'call_variants' step. If not set, the default for each --model_type will be used" }
  dry_run: { type: 'boolean?', inputBinding: { prefix: "--[no]dry_run", position: 1 }, doc: "If True, only prints out commands without executing them. (default: 'false')" }
  intermediate_results_dir: { type: 'string?', inputBinding: { prefix: "--intermediate_results_dir", position: 1 }, doc: "If specified, this should be an existing directory that is visible insider docker, and will be used to to store intermediate outputs." }
  logging_dir: { type: 'string?', inputBinding: { prefix: "--logging_dir", position: 1 }, doc: "Directory where we should write log files for each stage and optionally runtime reports." }
  make_examples_extra_args: { type: 'File?', inputBinding: { prefix: "--make_examples_extra_args", position: 1 }, doc: "A comma-separated list of flag_name=flag_value. 'flag_name' has to be valid flags for make_examples.py. If the flag_value is boolean, it has to be flag_name=true or flag_name=false." }
  num_shards: { type: 'int?', inputBinding: { prefix: "--num_shards", position: 1 }, doc: "Number of shards for make_examples step. (default: '1')" }
  postprocess_variants_extra_args: { type: 'File?', inputBinding: { prefix: "--postprocess_variants_extra_args", position: 1 }, doc: "A comma-separated list of flag_name=flag_value. 'flag_name' has to be valid flags for postprocess_variants.py. If the flag_value is boolean, it has to be flag_name=true or flag_name=false." }
  regions: { type: ['null', File, string], inputBinding: { prefix: "--regions", position: 1 }, doc: "Space-separated list of regions we want to process. Elements can be region literals (e.g., chr20:10-20) or paths to BED/BEDPE files." }
  runtime_report: { type: 'boolean?', inputBinding: { prefix: "--[no]runtime_report", position: 1 }, doc: "Output make_examples runtime metrics and create a visual runtime report using runtime_by_region_vis. Only works with --logging_dir. (default: 'false')" }
  vcf_stats_report: { type: 'boolean?', inputBinding: { prefix: "--[no]vcf_stats_report", position: 1 }, doc: "Output a visual report (HTML) of statistics about the output VCF. (default: 'true')" }

outputs:
  vcf: { type: 'File', outputBinding: { glob: '*.output.vcf.gz' }, secondaryFiles: ['.tbi'], doc: "NanoCount returns a file containing count data per transcript. By default only transcripts with at least one read mapped are included in the output. This can be changed to include all transcripts with the option extra_tx_info" }
  gvcf: { type: 'File', outputBinding: { glob: '*.g.vcf.gz' }, secondaryFiles: ['.tbi'], doc: "NanoCount returns a file containing count data per transcript. By default only transcripts with at least one read mapped are included in the output. This can be changed to include all transcripts with the option extra_tx_info" }
  visual_report: { type: 'File?', outputBinding: { glob: '*.html' }, doc: "https://github.com/google/deepvariant/blob/r1.6.1/docs/deepvariant-vcf-stats-report.md" }
