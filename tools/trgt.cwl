class: CommandLineTool
cwlVersion: v1.2
id: trgt
doc: |
  Original PacBio WDL: https://github.com/PacificBiosciences/HiFi-human-WGS-WDL/blob/main/workflows/sample_analysis/sample_analysis.wdl
requirements:
  - class: ShellCommandRequirement
  - class: InlineJavascriptRequirement
  - class: ResourceRequirement
    coresMin: $(inputs.threads)
    ramMin: $(inputs.ram*1000)
  - class: DockerRequirement
    dockerPull: quay.io/pacbio/trgt@sha256:8c9f236eb3422e79d7843ffd59e1cbd9b76774525f20d88cd68ca64eb63054eb
baseCommand: []
arguments:
  - position: 0
    shellQuote: false
    valueFrom: |
      if [ $(inputs.sex) = null ]; then
        1>&2 echo "Sex is not defined for $(inputs.sample_id). Defaulting to karyotype XX for TRGT."
      fi

      trgt \
        --threads $(inputs.threads) \
        --karyotype $(inputs.sex == "MALE" ? "XY" : "XX") \
        --genome $(inputs.reference.path) \
        --repeats $(inputs.tandem_repeat_bed.path) \
        --reads $(inputs.bam.path) \
        --output-prefix $(inputs.sample_id).trgt

      bcftools sort \
        --output-type z \
        --output $(inputs.sample_id).trgt.sorted.vcf.gz \
        $(inputs.sample_id).trgt.vcf.gz

      bcftools index \
        --threads ${ return inputs.threads - 1 } \
        --tbi \
        $(inputs.sample_id).trgt.sorted.vcf.gz

      samtools sort \
        -@ ${ return inputs.threads - 1 } \
        -o $(inputs.sample_id).trgt.spanning.sorted.bam \
        $(inputs.sample_id).trgt.spanning.bam

      samtools index \
        -@ ${ return inputs.threads - 1 } \
        $(inputs.sample_id).trgt.spanning.sorted.bam

inputs:
  sample_id: { type: 'string' }
  sex: { type: 'string?' }
  bam: { type: 'File', secondaryFiles: [{pattern: ".bai", required: true}] }
  reference: { type: 'File', secondaryFiles: [{pattern: ".fai", required: true}] }
  tandem_repeat_bed: { type: 'File' }
  threads: { type: 'int?', default: 4, doc: "Number of threads to allocate to this task." }
  ram: { type: 'int?', default: 4, doc: "GB size of RAM to allocate to this task." }

outputs:
  spanning_reads: { type: 'File', outputBinding: { glob: '*.sorted.bam' }, secondaryFiles: ['.bai'] }
  repeat_vcf: { type: 'File', outputBinding: { glob: '*.sorted.vcf.gz' }, secondaryFiles: ['.tbi'] }
