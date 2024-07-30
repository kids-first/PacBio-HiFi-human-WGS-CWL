class: CommandLineTool
cwlVersion: v1.2
id: deepvariant_make_examples
doc: |
  Original PacBio WDL: https://github.com/PacificBiosciences/wdl-common/blob/fef058b879d04c15c3da2626b320afdd8ace6c2e/wdl/workflows/deepvariant/deepvariant.wdl
requirements:
  - class: ShellCommandRequirement
  - class: InlineJavascriptRequirement
  - class: ResourceRequirement
    coresMin: $(inputs.cpu)
    ramMin: $(inputs.ram * 1000)
  - class: DockerRequirement
    dockerPull: images.sbgenomics.com/raisa_petrovic/deepvariant1-5-0:5
baseCommand: []
arguments:
  - position: 0
    shellQuote: false
    valueFrom: |
      export HOME=/root 
      N_SHARDS=$(inputs.n_shards ? inputs.n_shards : 32)

      mkdir -p example_tfrecords nonvariant_site_tfrecords

      /usr/bin/time seq 0 \$((N_SHARDS - 1)) | parallel --eta --halt 2 --joblog "log" --res "res" \
        python /opt/deepvariant/bin/make_examples.zip \
        --reads $(inputs.reads.path) \
        --ref $(inputs.reference.path) \
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
        --task {} \
        --examples "example_tfrecords/examples.tfrecord@\${N_SHARDS}.gz" \
        --gvcf "nonvariant_site_tfrecords/gvcf.tfrecord@\${N_SHARDS}.gz" 

      tar -zcvf example_tfrecords.tar.gz example_tfrecords

      tar -zcvf nonvariant_site_tfrecords.tar.gz nonvariant_site_tfrecords

inputs:
  # Required inputs
  reference: { type: 'File', secondaryFiles: [{pattern: ".fai", required: false}, {pattern: ".gzi", required: false}], doc: "Genome reference to use. Must have an associated FAI index as well. Supports text or gzipped references. Should match the reference used to align the BAM file provided to the 'reads' input." }
  reads: { type: 'File', secondaryFiles: [{pattern: "^.bai", required: false}, {pattern: ".bai", required: false}, {pattern: "^.crai", required: false}, {pattern: ".crai", required: false}], doc: "Aligned, sorted, indexed BAM/CRAM file containing the reads we want to call. Should be aligned to a reference genome compatible with the FASTA provided on the 'ref' input." }
  # Resources
  n_shards: { type: 'int?', default: 32 }
  cpu: { type: 'int?', default: 36, doc: "CPUs to allocate to this task" }
  ram: { type: 'int?', default: 40, doc: "GB of RAM to allocate to this task." }

outputs: 
  example_tfrecord_tar: { type: 'File', outputBinding: { glob: 'example_tfrecords.tar.gz' } }
  nonvariant_site_tfrecord_tar: { type: 'File', outputBinding: { glob: 'nonvariant_site_tfrecords.tar.gz' } }
