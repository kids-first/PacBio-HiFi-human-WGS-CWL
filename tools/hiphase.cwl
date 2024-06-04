class: CommandLineTool
cwlVersion: v1.2
id: hiphase
doc: |
  A tool for jointly phasing small, structural, and tandem repeat variants for PacBio sequencing data

  For more details, see:
  https://github.com/PacificBiosciences/HiPhase/tree/main
requirements:
  - class: ShellCommandRequirement
  - class: InlineJavascriptRequirement
  - class: ResourceRequirement
    ramMin: $(inputs.ram * 1000)
    coresMin: $(inputs.threads)
  - class: DockerRequirement
    dockerPull: quay.io/pacbio/hiphase@sha256:493ed4244608f29d7e2e180af23b20879c71ae3692201a610c7f1f980ee094e8
baseCommand: [hiphase]
arguments:
    - position: 99
      prefix: ''
      shellQuote: false
      valueFrom: |
        1>&2

inputs:
  # Required
  reference: { type: 'File', inputBinding: { prefix: "--reference", position: 50 }, doc: "Reference FASTA file" }
  bam: {type: 'File', inputBinding: { prefix: "--bam", position: 60 }, secondaryFiles: [{ pattern: ".bai", required: true}], doc: "Path to a BAM file containing reads only from the sample that is being phased" }
  vcf:
    type:
      type: array
      items: File
      inputBinding:
        prefix: --vcf
    inputBinding:
      position: 70
    doc: "Path to a VCF file containing the variants to phase, this option can be specified multiple times; each sample being phased must appear in each provided VCF file; we recommend providing at least a small variant VCF and structural variant VCF; each VCF file must be index prior to running HiPhase"
  output_vcf: 
    type:
      type: array
      items: string
      inputBinding:
        prefix: --output-vcf
    inputBinding:
      position: 80
    doc: "Path to the output VCF that will contain the phased variants, this option must be specified the same number of times as --vcf"

  # Input/Output options
  output_bam: { type: 'string?', default: "hiphased.haplotagged.bam", inputBinding: { prefix: "--output-bam", position: 65 }, doc: "Output haplotagged alignment file in BAM format. [example: haplotagged.bam]" }
  sample_name: { type: 'string?', inputBinding: { prefix: "--sample-name", position: 1 }, doc: "Sample name to phase within the VCF (default: first sample)" }
  ignore_read_groups: { type: 'boolean?', inputBinding: { prefix: "--ignore-read-groups", position: 1 }, doc: "Ignore BAM file read group IDs" }
  summary_file: { type: 'string?', default: "hiphase.summary.tsv", inputBinding: { prefix: "--summary-file", position: 1 }, doc: "Output summary phasing statistics file (csv/tsv). [example: summary.tsv]" }
  stats_file: { type: 'string?', default: "hiphase.stats.tsv", inputBinding: { prefix: "--stats-file", position: 1 }, doc: "Output algorithmic statistics file (csv/tsv). [example: stats.tsv]" }
  blocks_file: { type: 'string?', default: "hiphase.blocks.tsv", inputBinding: { prefix: "--blocks-file", position: 1 }, doc: "Output blocks file (csv/tsv). [example: blocks.tsv]" }
  haplotag_file: { type: 'string?', default: "hiphase.haplotags.tsv", inputBinding: { prefix: "--haplotag-file", position: 1 }, doc: "Output haplotag file (csv/tsv). [example: haplotag.tsv]" }
  io_threads: { type: 'int?', inputBinding: { prefix: "--io-threads", position: 1 }, doc: "Number of threads for BAM I/O (default: copy `--threads`)" }
  # Variant filtering
  min_vcf_qual: { type: 'int?', inputBinding: { prefix: "--min-vcf-qual", position: 1 }, doc: "Sets a minimum genotype quality (GQ) value to include a variant in the phasing [default: 0]" }
  # Map filtering
  min_mapq: { type: 'int?', inputBinding: { prefix: "--min-mapq", position: 1 }, doc: "Sets a minimum MAPQ to include a read in the phasing [default: 5]" }
  min_matched_alleles: { type: 'int?', inputBinding: { prefix: "--min-matched-alleles", position: 1 }, doc: "Sets a minimum number of matched variants required for a read to get included in the scoring [default: 2]" }
  # Phase block generation
  min_spanning_reads: { type: 'int?', inputBinding: { prefix: "--min-spanning-reads", position: 1 }, doc: "Sets a minimum number of reads to span two adjacent variants to join a phase block [default: 1]" }
  no_supplemental_joins: { type: 'boolean?', inputBinding: { prefix: "--no-supplemental-joins", position: 1 }, doc: "Disables the use of supplemental mappings to join phase blocks" }
  phase_singletons: { type: 'boolean?', inputBinding: { prefix: "--phase-singletons", position: 1 }, doc: "Enables the phasing and haplotagging of singleton phase blocks" }
  # Allele assignment
  max_reference_buffer: { type: 'int?', inputBinding: { prefix: "--max-reference-buffer", position: 1 }, doc: "Sets a maximum reference buffer for local realignment [default: 15]" }
  global_realignment_cputime: { type: 'int?', inputBinding: { prefix: "--global-realignment-cputime", position: 1 }, doc: "Enables global realignment with a maximum allowed CPU time before fallback to local realignment [default: 0]" }
  global_pruning_distance: { type: 'int?', inputBinding: { prefix: "--global-pruning-distance", position: 1 }, doc: "Sets a pruning threshold on global realignment, set to 0 to disable pruning [default: 500]" }
  # Phasing
  phase_min_queue_size: { type: 'int?', inputBinding: { prefix: "--phase-min-queue-size", position: 1 }, doc: "Sets the minimum queue size for the phasing algorithm [default: 1000]" }
  phase_queue_increment: { type: 'int?', inputBinding: { prefix: "--phase-queue-increment", position: 1 }, doc: "Sets the queue size increment per variant in a phase block [default: 3]" }
  # Resources
  threads: { type: 'int?', default: 2, inputBinding: { prefix: "--threads", position: 1 }, doc: "Number of threads to use for phasing" }
  ram: { type: 'int?', default: 2, doc: "RAM (in GB) to use" }

outputs:
  phased_vcf: { type: 'File[]', outputBinding: { glob: '*.phased.vcf.gz' }, secondaryFiles: ['.tbi'] }
  blocks_file_out: { type: 'File', outputBinding: { glob: '*.blocks*' }, doc: "This CSV/TSV file contains information about the the phase blocks that were output by HiPhase." }
  summary_file_out: { type: 'File', outputBinding: { glob: '*.summary*' }, doc: "This CSV/TSV file contains chromosome-level summary statistics for all phase blocks on that chromosome. Additionally, a chromosome labeled 'all' contains aggregate statistics for all phase blocks generated by HiPhase." }
  haplotag_file_out: { type: 'File', outputBinding: { glob: '*.haplotag*' }, doc: "This CSV/TSV file contains haplotag information for aligned reads. Note that while this contains the same information as the HP tag in the haplotagged output BAMs, generating those output BAMs is not required to generate this file." }
  stats_file_out: { type: 'File', outputBinding: { glob: '*.stats*' }, doc: "This CSV/TSV file contains statistics regarding the performance of the underlying algorithms while running HiPhase. This file is primarily for developers looking to improve HiPhase, but may be of use while identifying problematic phase blocks." }
  haplotagged_bam: { type: 'File', outputBinding: { glob: '*.bam' }, secondaryFiles: ['.bai'], doc: "Haplotagged alignment file in BAM format." }
