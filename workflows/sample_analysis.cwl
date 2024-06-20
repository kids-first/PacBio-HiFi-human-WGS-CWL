cwlVersion: v1.2
class: Workflow
id: sample-analysis
doc: | 
  Run for each sample in the cohort. Aligns reads from each movie to the reference genome, then calls and phases small and structural variants.
  
  WDL: 
  https://github.com/PacificBiosciences/HiFi-human-WGS-WDL/blob/main/workflows/sample_analysis/sample_analysis.wdl

requirements:
  - class: MultipleInputFeatureRequirement
  - class: StepInputExpressionRequirement
  - class: InlineJavascriptRequirement

inputs: 
  sample_id: { type: 'string' }
  # references
  reference_fasta: { type: 'File', secondaryFiles: [{pattern: ".fai", required: true}] }
  reference_tandem_repeat_bed: { type: 'File', doc: "human_GRCh38_no_alt_analysis_set.trf.be" }
  trgt_tandem_repeat_bed: { type: 'File', doc: "human_GRCh38_no_alt_analysis_set.trgt.v0.3.4.bed" }
  # pbmm2_align
  bam: { type: 'File' }
  pbmm2_threads: { type: 'int?', default: 24, doc: "Number of threads to allocate to this task." }
  # pbsv_discover
  pbsv_discover_cpu: { type: 'int?', default: 2, doc: "Number of threads to allocate to this task." }
  pbsv_discover_ram: { type: 'int?', default: 8, doc: "GB size of RAM to allocate to this task." }
  # deepvariant
  model_type:
    type:
      - type: enum
        name: model_type
        symbols: ["WGS","WES","PACBIO", "ONT_R104", "HYBRID_PACBIO_ILLUMINA"]
    doc: |
      Required. Type of model to use for variant calling. Set this flag to use the default model
      associated with each type, and it will set necessary flags corresponding to
      each model. If you want to use a customized model, add --customized_model
      flag in addition to this flag.
  call_variants_extra_args: { type: 'File?', doc: "A comma-separated list of flag_name=flag_value. 'flag_name' has to be valid flags for call_variants.py. If the flag_value is boolean, it has to be flag_name=true or flag_name=false." }
  customized_model: { type: 'File?', doc: "A path to a model checkpoint to load for the 'call_variants' step. If not set, the default for each --model_type will be used" }
  dry_run: { type: 'boolean?', doc: "If True, only prints out commands without executing them. (default: 'false')" }
  intermediate_results_dir: { type: 'string?', doc: "If specified, this should be an existing directory that is visible insider docker, and will be used to to store intermediate outputs." }
  logging_dir: { type: 'string?', doc: "Directory where we should write log files for each stage and optionally runtime reports." }
  make_examples_extra_args: { type: 'File?', doc: "A comma-separated list of flag_name=flag_value. 'flag_name' has to be valid flags for make_examples.py. If the flag_value is boolean, it has to be flag_name=true or flag_name=false." }
  num_shards: { type: 'int?', default: 32, doc: "Number of shards for make_examples step." }
  postprocess_variants_extra_args: { type: 'File?', doc: "A comma-separated list of flag_name=flag_value. 'flag_name' has to be valid flags for postprocess_variants.py. If the flag_value is boolean, it has to be flag_name=true or flag_name=false." }
  deepvariant_regions: { type: ['null', File, string], doc: "Space-separated list of regions we want to process. Elements can be region literals (e.g., chr20:10-20) or paths to BED/BEDPE files." }
  runtime_report: { type: 'boolean?', doc: "Output make_examples runtime metrics and create a visual runtime report using runtime_by_region_vis. Only works with --logging_dir. (default: 'false')" }
  vcf_stats_report: { type: 'boolean?', doc: "Output a visual report (HTML) of statistics about the output VCF. (default: 'true')" }
  deepvariant_ram: { type: 'int?', default: 4 }
  # bcftools
  bcftools_threads: { type: 'int?', default: 2 }
  bcftools_ram: { type: 'int?', default: 4 }
  # pbsv_call
  pbsv_call_threads: { type: 'int?', default: 8 }
  pbsv_call_ram: { type: 'int?', default: 64, doc: "Int mem_gb = if select_first([sample_count, 1]) > 3 then 96 else 64" }
  ignore_read_groups: { type: 'boolean?', doc: "Ignore BAM file read group IDs" }
  io_threads: { type: 'int?', doc: "Number of threads for BAM I/O (default: copy `--threads`)" }
  min_vcf_qual: { type: 'int?', doc: "Sets a minimum genotype quality (GQ) value to include a variant in the phasing [default: 0]" }
  min_mapq: { type: 'int?', doc: "Sets a minimum MAPQ to include a read in the phasing [default: 5]" }
  min_matched_alleles: { type: 'int?', doc: "Sets a minimum number of matched variants required for a read to get included in the scoring [default: 2]" }
  min_spanning_reads: { type: 'int?', doc: "Sets a minimum number of reads to span two adjacent variants to join a phase block [default: 1]" }
  no_supplemental_joins: { type: 'boolean?', doc: "Disables the use of supplemental mappings to join phase blocks" }
  phase_singletons: { type: 'boolean?', doc: "Enables the phasing and haplotagging of singleton phase blocks" }
  max_reference_buffer: { type: 'int?', doc: "Sets a maximum reference buffer for local realignment [default: 15]" }
  global_realignment_cputime: { type: 'int?', doc: "Enables global realignment with a maximum allowed CPU time before fallback to local realignment [default: 0]" }
  global_pruning_distance: { type: 'int?', doc: "Sets a pruning threshold on global realignment, set to 0 to disable pruning [default: 500]" }
  phase_min_queue_size: { type: 'int?', doc: "Sets the minimum queue size for the phasing algorithm [default: 1000]" }
  phase_queue_increment: { type: 'int?', doc: "Sets the queue size increment per variant in a phase block [default: 3]" }
  hiphase_threads: { type: 'int?', default: 2 }
  hiphase_ram: { type: 'int?', default: 2 }
  # mosdepth
  mosdepth_threads: { type: 'int?', default: 4 }
  mosdepth_ram: { type: 'int?', default: 8 }
  # trgt 
  sex: { type: 'string?' }
  trgt_threads: { type: 'int?', default: 4 }
  trgt_ram: { type: 'int?', default: 4 }
  # coverage_dropouts
  coverage_dropouts_threads: { type: 'int?', default: 2 }
  coverage_dropouts_ram: { type: 'int?', default: 4 }
  # cpg_pileup
  cpg_pileup_threads: { type: 'int?', default: 12 }
  # paraphase
  paraphase_threads: { type: 'int?', default: 4 }
  paraphase_ram: { type: 'int?', default: 4 }
  # hificnv
  exclude_bed: { type: 'File', secondaryFiles: [{pattern: ".tbi", required: true}], doc: "cnv.excluded_regions.common_50.hg38.bed.gz" }
  expected_bed_male: { type: 'File', doc: "expected_cn.hg38.XY.bed" }
  expected_bed_female: { type: 'File', doc: "expected_cn.hg38.XX.bed" }
  hificnv_threads: { type: 'int?', default: 8 }

outputs: 
  # per movie stats, alignments, and svsigs
  bam_stats: { type: 'File', outputSource: pbmm2_align/bam_stats }
  read_length_summary: { type: 'File', outputSource: pbmm2_align/read_length_summary }
  read_quality_summary: { type: 'File', outputSource: pbmm2_align/read_quality_summary }
  aligned_bam: { type: 'File', outputSource: pbmm2_align/output_bam }
  svsig: { type: 'File', outputSource: pbsv_discover/svsig }
  # per sample small variant calls
  deepvariant_vcf: { type: 'File', outputSource: deepvariant/vcf }
  deepvariant_gvcf: { type: 'File', outputSource: deepvariant/gvcf }
  deepvariant_vcf_stats: { type: 'File', outputSource: bcftools/vcf_stats }
  deepvariant_roh_out: { type: 'File', outputSource: bcftools/roh_out }
  deepvariant_roh_bed: { type: 'File', outputSource: bcftools/roh_bed }
  # per sample final pahsed variant calls and haplotagged alignments
  phased_vcf: { type: 'File[]', outputSource: hiphase/phased_vcf }
  phased_summary: { type: 'File', outputSource: hiphase/summary_file_out } 
  hiphase_stats: { type: 'File', outputSource: hiphase/stats_file_out }
  hiphase_blocks: { type: 'File', outputSource: hiphase/blocks_file_out }
  hiphase_haplotags: { type: 'File', outputSource: hiphase/haplotag_file_out }
  hiphase_bams: { type: 'File', outputSource: hiphase/haplotagged_bam }
  haplotagged_bam_mosdepth_summary: { type: 'File', outputSource: mosdepth/summary }
  haplotagged_bam_mosdepth_region_bed: { type: 'File', outputSource: mosdepth/region_bed }
  # per sample trgt outputs
  trgt_spanning_reads: { type: 'File', outputSource: trgt/spanning_reads }
  trgt_repeat_vcf: { type: 'File', outputSource: trgt/repeat_vcf }
  # per sample cpg outputs
  cpg_pileup_beds: { type: 'File[]', outputSource: cpg_pileup/pileup_beds }
  cpg_pileup_bigwigs: { type: 'File[]', outputSource: cpg_pileup/pileup_bigwigs }
  # per sample paraphase outputs
  paraphase_output_json: { type: 'File', outputSource: paraphase/output_json }
  paraphase_realigned_bams: { type: 'File', outputSource: paraphase/realigned_bam }
  paraphase_vcfs: { type: 'File[]', outputSource: paraphase/paraphase_vcfs }
  # per sample hificnv outputs
  hificnv_vcf: { type: 'File', outputSource: hificnv/cnv_vcf }
  hificnv_copynum_bedgraph: { type: 'File', outputSource: hificnv/copynum_bedgraph }
  hificnv_depth_bw: { type: 'File', outputSource: hificnv/depth_bw }
  hificnv_maf_bw: { type: 'File', outputSource: hificnv/maf_bw }


steps:
  pbmm2_align:
    run: ../tools/pbmm2_align.cwl
    in:
      sample_id: sample_id
      bam: bam
      reference: reference_fasta
      threads: pbmm2_threads
    out: [output_bam, bam_stats, read_length_summary, read_quality_summary]
  
  pbsv_discover: 
    run: ../tools/pbsv_discover.cwl
    in:
      aligned_bam: pbmm2_align/output_bam
      reference_tandem_repeat_bed: reference_tandem_repeat_bed
      cpu: pbsv_discover_cpu
      ram: pbsv_discover_ram
    out: [svsig]
  
  deepvariant:
    run: ../tools/deepvariant.cwl
    in:
      reads: pbmm2_align/output_bam
      ref: reference_fasta
      sample_name: sample_id
      model_type: model_type
      output_vcf: 
        valueFrom: $(inputs.sample_name + ".deepvariant.vcf.gz")
      output_gvcf: 
        valueFrom: $(inputs.sample_name + ".deepvariant.g.vcf.gz")
      call_variants_extra_args: call_variants_extra_args
      customized_model: customized_model
      dry_run: dry_run
      intermediate_results_dir: intermediate_results_dir
      logging_dir: logging_dir
      make_examples_extra_args: make_examples_extra_args
      num_shards: num_shards
      postprocess_variants_extra_args: postprocess_variants_extra_args
      regions: deepvariant_regions
      runtime_report: runtime_report
      vcf_stats_report: vcf_stats_report
      ram: deepvariant_ram
    out: [vcf, gvcf, visual_report]
  
  bcftools:
    run: ../tools/bcftools.cwl
    in:
      vcf: deepvariant/vcf
      reference: reference_fasta
      sample_id: sample_id
      threads: bcftools_threads
      ram: bcftools_ram
    out: [vcf_stats, roh_out, roh_bed]
  
  pbsv_call:
    run: ../tools/pbsv_call.cwl
    in:
      svsigs: pbsv_discover/svsig
      reference: reference_fasta
      sample_id: sample_id
      threads: pbsv_call_threads
      ram: pbsv_call_ram
    out: [pbsv_vcf]
  
  hiphase:
    run: ../tools/hiphase.cwl
    in: 
      bam: pbmm2_align/output_bam
      vcf: [deepvariant/vcf, pbsv_call/pbsv_vcf]
      reference: reference_fasta
      sample_name: sample_id
      output_vcf: 
        valueFrom: |
          $(inputs.vcf.map(function(e) { return "./hiphase." + e.basename }))
      output_bam:
        valueFrom: $(inputs.sample_name + ".hiphase.haplotagged.bam")
      ignore_read_groups: ignore_read_groups
      summary_file: 
        valueFrom: $(inputs.sample_name + ".hiphase.summary.tsv")
      stats_file: 
        valueFrom: $(inputs.sample_name + ".hiphase.stats.tsv")
      blocks_file:
        valueFrom: $(inputs.sample_name + ".hiphase.blocks.tsv")
      haplotag_file:
        valueFrom: $(inputs.sample_name + ".hiphase.haplotags.tsv")
      io_threads: io_threads
      min_vcf_qual: min_vcf_qual
      min_mapq: min_mapq
      min_matched_alleles: min_matched_alleles
      min_spanning_reads: min_spanning_reads
      no_supplemental_joins: no_supplemental_joins
      phase_singletons: phase_singletons
      max_reference_buffer: max_reference_buffer
      global_realignment_cputime: global_realignment_cputime
      global_pruning_distance: global_pruning_distance
      phase_min_queue_size: phase_min_queue_size
      phase_queue_increment: phase_queue_increment
      threads: hiphase_threads
      ram: hiphase_ram
    out: [phased_vcf, blocks_file_out, summary_file_out, haplotag_file_out, stats_file_out, haplotagged_bam]

  mosdepth:
    run: ../tools/mosdepth.cwl
    in:
      aligned_bam: hiphase/haplotagged_bam
      sample_id: sample_id
      threads: mosdepth_threads
      ram: mosdepth_ram
    out: [summary, region_bed]

  trgt:
    run: ../tools/trgt.cwl
    in:
      sample_id: sample_id
      sex: sex
      bam: hiphase/haplotagged_bam
      reference: reference_fasta
      tandem_repeat_bed: trgt_tandem_repeat_bed
      threads: trgt_threads
      ram: trgt_ram
    out: [spanning_reads, repeat_vcf]
  
  coverage_dropouts:
    run: ../tools/coverage_dropouts.cwl
    in:
      bam: hiphase/haplotagged_bam
      tandem_repeat_bed: trgt_tandem_repeat_bed
      sample_id: sample_id
      threads: coverage_dropouts_threads
      ram: coverage_dropouts_ram
    out: [trgt_dropouts]

  cpg_pileup:
    run: ../tools/cpg_pileup.cwl
    in:
      bam: hiphase/haplotagged_bam
      reference: reference_fasta
      sample_id: sample_id
      threads: cpg_pileup_threads
    out: [pileup_beds, pileup_bigwigs]
  
  paraphase:
    run: ../tools/paraphase.cwl
    in: 
      bam: hiphase/haplotagged_bam
      reference: reference_fasta
      sample_id: sample_id
      threads: paraphase_threads
      ram: paraphase_ram
    out: [output_json, realigned_bam, paraphase_vcfs]

  hificnv:
    run: ../tools/hificnv.cwl
    in: 
      sample_id: sample_id
      sex: sex
      bam: hiphase/haplotagged_bam
      phased_vcf: 
        source: hiphase/phased_vcf
        valueFrom: $(self[0])
      reference: reference_fasta
      exclude_bed: exclude_bed
      expected_bed_male: expected_bed_male
      expected_bed_female: expected_bed_female
      threads: hificnv_threads
    out: [cnv_vcf, copynum_bedgraph, depth_bw, maf_bw]

$namespaces:
  sbg: https://sevenbridges.com