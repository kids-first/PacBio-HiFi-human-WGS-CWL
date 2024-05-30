class: CommandLineTool
cwlVersion: v1.2
id: pbmm2_align
doc: |
  BCFtools is a set of utilities that manipulate variant calls in the Variant Call Format (VCF) and 
  its binary counterpart BCF. All commands work transparently with both VCFs and BCFs, both 
  uncompressed and BGZF-compressed.

  Original PacBio WDL: https://github.com/PacificBiosciences/HiFi-human-WGS-WDL/blob/main/workflows/sample_analysis/sample_analysis.wdl
requirements:
  - class: ShellCommandRequirement
  - class: InlineJavascriptRequirement
  - class: ResourceRequirement
    coresMin: $(inputs.threads)
    ramMin: $(inputs.ram*1000)
  - class: DockerRequirement
    dockerPull: quay.io/pacbio/bcftools@sha256:46720a7ab5feba5be06d5269454a6282deec13060e296f0bc441749f6f26fdec
baseCommand: ["/bin/bash", "-c"]
arguments:
  - position: 0
    shellQuote: false
    valueFrom: |
      set -euo pipefail

      bcftools --version

      bcftools stats \
        --threads ${ return inputs.threads - 1 } \
        --apply-filters PASS --samples $(inputs.sample_id) \
        --fasta-ref $(inputs.reference) \
        $(inputs.vcf) \
      > $(inputs.vcf.nameroot).vcf.stats.txt

      bcftools roh \
        --threads ${ return inputs.threads - 1 } \
        --AF-dflt 0.4 \
        $(inputs.vcf) \
      > $(inputs.vcf.nameroot).bcftools_roh.out

      echo -e "#chr\\tstart\\tend\\tqual" > $(inputs.vcf.nameroot).roh.bed
      awk -v OFS='\t' '$1=="RG" {{ print $3, $4, $5, $8 }}' \
        $(inputs.vcf.nameroot).bcftools_roh.out \
      >> $(inputs.vcf.nameroot).roh.bed

inputs:
  vcf: { type: 'File' }
  reference: { type: 'File' }
  sample_id: { type: 'string' }
  threads: { type: 'int?', default: 2, doc: "Number of threads to allocate to this task." }
  ram: { type: 'int?', default: 4, doc: "GB size of RAM to allocate to this task." }

outputs:
  vcf_stats: { type: 'File', outputBinding: { glob: '*.txt' } }
  roh_out: { type: 'File', outputBinding: { glob: '*.out' } }
  roh_bed: { type: 'File', outputBinding: { glob: '*.bed' } }
