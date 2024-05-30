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
  - class: InitialWorkDirRequirement
    listing:
      - entryname: "svsigs.list"
        entry: $(inputs.svsigs)
      - entry: $(inputs.reference)
      - entryname: run_pbsv_call.sh
        entry:
          $include: ../scripts/run_pbsv_call.sh
  - class: DockerRequirement
    dockerPull: quay.io/pacbio/pbsv@sha256:d78ee6deb92949bdfde98d3e48dab1d871c177d48d8c87c73d12c45bdda43446
baseCommand: [bash run_pbsv_call.sh]

inputs:
  sample_id: { type: 'string', inputBinding: { position: 1 } }
  svsigs: { type: 'File[]', inputBinding: { position: 2 } }
  reference: { type: 'File', secondaryFiles: [{pattern: ".fai", required: true}], inputBinding: { position: 3 } }
  reference_name: { type: 'string', inputBinding: { position: 4 } }
  shard_index: { type: 'int?', inputBinding: { position: 5 } }
  regions: { type: 'string?', inputBinding: { position: 6 } }
  
  threads: { type: 'int?', default: 8, doc: "Number of threads to allocate to this task.", inputBinding: { position: 7 } }
  ram: { type: 'int?', default: 64, doc: "Int mem_gb = if select_first([sample_count, 1]) > 3 then 96 else 64" }

outputs:
  pbsv_vcf: { type: 'File', outputBinding: { glob: '*.vcf.gz' }, secondaryFiles: ['.tbi'] }
