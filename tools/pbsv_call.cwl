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
  - class: DockerRequirement
    dockerPull: quay.io/pacbio/pbsv@sha256:d78ee6deb92949bdfde98d3e48dab1d871c177d48d8c87c73d12c45bdda43446
baseCommand: ["/bin/bash", "-c"]
arguments:
  - position: 0
    shellQuote: false
    valueFrom: |
      set -euo pipefail

      if [ -n $(inputs.regions) ]; then
        pattern=$(echo $(inputs.regions) \
          | sed 's/^/^.\\t.\\t/; s/ /\\t\\|^.\\t.\\t/g; s/$/\\t/' \
          | echo "^#|$(</dev/stdin)")

        touch svsigs.fofn 
        for svsig in $(cat svsigs.list); do
          svsig_basename=$(basename "$svsig" .svsig.gz)
          gunzip -c "$svsig" \
            | grep -P "$pattern" \
            | bgzip -c > "${svsig_basename}.regions.svsig.gz" \
            && echo "${svsig_basename}.regions.svsig.gz" >> svsigs.fofn
        done
      else
        cp $(inputs.svsigs) svsigs.fofn
      fi

      pbsv --version

      pbsv call \
        --hifi \
        --min-sv-length 20 \
        --log-level INFO \
        --num-threads $(inputs.threads) \
        $(inputs.reference) \
        svsigs.fofn \
        "$(inputs.sample_id).$(inputs.reference_name)$(inputs.shard_index).pbsv.vcf"

      bgzip --version

      bgzip "$(inputs.sample_id).$(inputs.reference_name)$(inputs.shard_index).pbsv.vcf"

      tabix --version

      tabix -p vcf "$(inputs.sample_id).$(inputs.reference_name)$(inputs.shard_index).pbsv.vcf.gz"

inputs:
  sample_id: { type: 'string' }
  svsigs: { type: 'File[]' }
  sample_count: { type: 'int?' }
  reference: { type: 'File', secondaryFiles: [{pattern: ".fai", required: true}] }
  reference_name: { type: 'string' }
  shard_index: { type: 'int?' }
  regions: { type: 'string[]?' }
  
  threads: { type: 'int?', default: 8, doc: "Number of threads to allocate to this task." }
  ram: { type: 'int?', default: 64, doc: "Int mem_gb = if select_first([sample_count, 1]) > 3 then 96 else 64" }

outputs:
  pbsv_vcf: { type: 'File', outputBinding: { glob: '*.vcf.gz' }, secondaryFiles: ['.tbi'] }
