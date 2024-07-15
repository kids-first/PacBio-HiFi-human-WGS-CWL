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
  - class: SubworkflowFeatureRequirement

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
  num_shards: { type: 'int?', default: 32 }
  make_examples_cpus_per_job: { type: 'int?', default: 36, doc: "Number of CPUs per job." }
  make_examples_mem_per_job: { type: 'int?', default: 1024, doc: "Memory per job[MB]." }
  custom_model: { type: 'File?', secondaryFiles: [{pattern: "^.index", required: true}, {pattern: "^.meta", required: true}], doc: "Custom TensorFlow model checkpoint to use to evaluate candidate variant calls. If not provided, the model trained by the DeepVariant team will be used." }
  model:
    type:
      - type: enum
        symbols: ["WGS", "WES", "PACBIO", "HYBRID_PACBIO_ILLUMINA", "ONT_R104"]
    doc: "TensorFlow model checkpoint to use to evaluate candidate variant calls."
    default: "PACBIO"
  call_variants_cpus_per_job: { type: 'int?', default: 36, doc: "Number of CPUs per job." }
  call_variants_mem_per_job: { type: 'int?', default: 1024, doc: "Memory per job[MB]." }
  qual_filter: { type: 'float?', doc: "Any variant with QUAL < qual_filter will be filtered in the VCF file." }
  cnn_homref_call_min_gq: { type: 'float?', doc: "All CNN RefCalls whose GQ is less than this value will have ./. genotype instead of 0/0." }
  multi_allelic_qual_filter: { type: 'float?', doc: "The qual value below which to filter multi-allelic variants." }
  postprocess_variants_cpus_per_job: { type: 'int?', default: 36, doc: "Number of CPUs per job." }
  postprocess_variants_mem_per_job: { type: 'int?', default: 1024, doc: "Memory per job[MB]." }
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
  pbsv_call_vcf: { type: 'File', outputSource: pbsv_call/pbsv_vcf }
  # per sample final pahsed variant calls and haplotagged alignments
  phased_deepvariant_vcf: { type: 'File', outputSource: hiphase/phased_deepvariant_vcf }
  phased_pbsv_vcf: { type: 'File?', outputSource: hiphase/phased_pbsv_vcf }
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
    run: ../subworkflows/deepvariant.cwl
    in:
      reads: pbmm2_align/output_bam
      reference: reference_fasta
      sample_name: sample_id
      num_shards: num_shards
      make_examples_cpus_per_job: make_examples_cpus_per_job
      make_examples_mem_per_job: make_examples_mem_per_job
      custom_model: custom_model
      model: model
      call_variants_cpus_per_job: call_variants_cpus_per_job
      call_variants_mem_per_job: call_variants_mem_per_job
      qual_filter: qual_filter
      cnn_homref_call_min_gq: cnn_homref_call_min_gq
      multi_allelic_qual_filter: multi_allelic_qual_filter
      postprocess_variants_cpus_per_job: postprocess_variants_cpus_per_job
      postprocess_variants_mem_per_job: postprocess_variants_mem_per_job
    out: [vcf, gvcf]
  
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
      deepvariant_vcf: deepvariant/vcf
      output_deepvariant_vcf:
        valueFrom: |
          $("./hiphase." + inputs.deepvariant_vcf.basename)
      pbsv_vcf: pbsv_call/pbsv_vcf
      output_pbsv_vcf:
        valueFrom: |
          $("./hiphase." + inputs.pbsv_vcf.basename)
      reference: reference_fasta
      sample_name: sample_id
      ignore_read_groups: ignore_read_groups
      output_bam:
        valueFrom: $(inputs.sample_name + ".hiphase.haplotagged.bam")
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
    out: [phased_deepvariant_vcf, phased_pbsv_vcf, blocks_file_out, summary_file_out, haplotag_file_out, stats_file_out, haplotagged_bam]

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
      phased_vcf: hiphase/phased_deepvariant_vcf
      reference: reference_fasta
      exclude_bed: exclude_bed
      expected_bed_male: expected_bed_male
      expected_bed_female: expected_bed_female
      threads: hificnv_threads
    out: [cnv_vcf, copynum_bedgraph, depth_bw, maf_bw]

$namespaces:
  sbg: https://sevenbridges.com