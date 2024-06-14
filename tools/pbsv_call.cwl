class: CommandLineTool
cwlVersion: v1.2
id: pbsv_call
doc: |
  Detect and annotate structural variants

  Original PacBio WDL: https://github.com/PacificBiosciences/wdl-common/blob/fef058b879d04c15c3da2626b320afdd8ace6c2e/wdl/tasks/pbsv_call.wdl
requirements:
  - class: InlineJavascriptRequirement
  - class: ResourceRequirement
    coresMin: $(inputs.threads)
    ramMin: $(inputs.ram*1000)
  - class: DockerRequirement
    dockerPull: quay.io/pacbio/pbsv@sha256:d78ee6deb92949bdfde98d3e48dab1d871c177d48d8c87c73d12c45bdda43446
baseCommand: [pbsv, call]

inputs:
  reference: { type: 'File', secondaryFiles: [{pattern: ".fai", required: true}], inputBinding: { position: 80 } }
  svsigs: { type: 'File', inputBinding: { position: 81 }, doc: "SV signatures from one or more samples. Can be svsig.gz file or file of filenames." }
  output_prefix: { type: 'string', inputBinding: { position: 82 } }

  # Basic options
  region: { type: 'string?', inputBinding: { prefix: "--region", position: 1 }, doc: "Limit discovery to this reference region: CHR|CHR:START-END." }
  read_optimization:
    type:
      - 'null'
      - type: record
        fields:
          - name: "hifi"
            type: boolean?
            doc: "Use options optimized for HiFi reads: -S 0 -P 10."
            inputBinding:
              prefix: "--hifi"
              position: 1
          - name: "ccs"
            type: boolean?
            doc: "Use options optimized for HiFi reads: -S 0 -P 10."
            inputBinding:
              prefix: "--ccs"
              position: 1
  # Variant options
  variant_types:
    type:
      - 'null'
      - type: enum
        name: variant_types
        symbols: ["DEL","INS","INV","DUP","BND"]
    inputBinding:
      prefix: "--types"
      position: 1
    doc: |
      Call these SV types: "DEL", "INS", "INV", "DUP", "BND".
  min_sv_length: { type: 'int?', inputBinding: { prefix: "--min-sv-length", position: 1 }, doc: "Ignore variants with length < N bp. [20]" }
  max_ins_length: { type: 'string?', inputBinding: { prefix: "--max-dup-length", position: 1 }, doc: "Ignore insertions with length > N bp. [15K]" }
  max_dup_length: { type: 'string?', inputBinding: { prefix: "--max-dup-length", position: 1 }, doc: "Ignore duplications with length > N bp. [1M]" }
  # SV signature cluster options
  cluster_max_length_perc_diff: { type: 'int?', inputBinding: { prefix: "--cluster-max-length-perc-diff", position: 1 }, doc: "Do not cluster signatures with difference in length > P%. [25]" }
  cluster_max_ref_pos_diff: { type: 'int?', inputBinding: { prefix: "--cluster-max-ref-pos-diff", position: 1 }, doc: "Do not cluster signatures > N bp apart in reference. [200]" }
  cluster_min_basepair_perc_id: { type: 'int?', inputBinding: { prefix: "--cluster-min-basepair-perc-id", position: 1 }, doc: "Do not cluster signatures with basepair identity < P%. [10]" }
  # Consensus options
  max_consensus_coverage: { type: 'int?', inputBinding: { prefix: "--max-consensus-coverage", position: 1 }, doc: "Limit to N reads for variant consensus. [20]" }
  poa_scores: { type: 'string?', inputBinding: { prefix: "--poa-scores", position: 1 }, doc: "Score POA alignment with triplet match,mismatch,gap. [1,-2,-2]" }
  min_realign_length: { type: 'int?', inputBinding: { prefix: "--min-realign-length", position: 1 }, doc: "Consider segments with > N length for re-alignment. [100]" }
  # Call options
  call_min_reads_all_samples: { type: 'int?', inputBinding: { prefix: "--call-min-reads-all-samples", position: 1 }, doc: "Ignore calls supported by < N reads total across samples. [3]" }
  call_min_reads_one_sample: { type: 'int?', inputBinding: { prefix: "--call-min-reads-one-sample", position: 1 }, doc: "Ignore calls supported by < N reads in every sample. [3]" }
  call_min_reads_per_strand_all_samples: { type: 'int?', inputBinding: { prefix: "--call-min-reads-per-strand-all-samples", position: 1 }, doc: "Ignore calls supported by < N reads per strand total across samples [1]" }
  call_min_bnd_reads_all_samples: { type: 'int?', inputBinding: { prefix: "--call-min-bnd-reads-all-samples", position: 1 }, doc: "Ignore BND calls supported by < N reads total across samples [2]" }
  call_min_read_perc_one_sample: { type: 'int?', inputBinding: { prefix: "--call-min-read-perc-one-sample", position: 1 }, doc: "Ignore calls supported by < P% of reads in every sample. [20]" }
  preserve_non_acgt: { type: 'boolean?', inputBinding: { prefix: "--preserve-non-acgt", position: 1 }, doc: "Preserve non-ACGT in REF allele instead of replacing with N." }
  # Genotyping
  gt_min_reads: { type: 'int?', inputBinding: { prefix: "--gt-min-reads", position: 1 }, doc: "Minimum supporting reads to assign a sample a non-reference genotype. [1]" }
  # Annotations
  annotations: { type: 'File?', inputBinding: { prefix: "--annotations", position: 1 }, doc: "Annotate variants by comparing with sequences in fasta. Default annotations are ALU, L1, SVA." }
  annotation_min_perc_sim: { type: 'int?', inputBinding: { prefix: "--annotation-min-perc-sim", position: 1 }, doc: "Annotate variant if sequence similarity > P%. [60]" }
  # Variant filtering options
  min_n_in_gap: { type: 'int?', inputBinding: { prefix: "--min-N-in-gap", position: 1 }, doc: "Consider >= N consecutive 'N' bp as a reference gap. [50]" }
  filter_near_reference_gap: { type: 'string?', inputBinding: { prefix: "--filter-near-reference-gap", position: 1 }, doc: "Flag variants < N bp from a gap as 'NearReferenceGap'. [1K]" }
  filter_near_contig_end: { type: 'string?', inputBinding: { prefix: "--filter-near-contig-end", position: 1 }, doc: "Flag variants < N bp from a contig end as 'NearContigEnd'. [1K]" }

  threads: { type: 'int?', default: 8, doc: "Number of threads to allocate to this task.", inputBinding: { prefix: "--num-threads", position: 7 } }
  ram: { type: 'int?', default: 64, doc: "Int mem_gb = if select_first([sample_count, 1]) > 3 then 96 else 64" }

outputs:
  pbsv_vcf: { type: 'File', outputBinding: { glob: '*.vcf' } }
