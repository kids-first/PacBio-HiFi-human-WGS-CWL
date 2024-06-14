class: CommandLineTool
cwlVersion: v1.2
id: hificnv
doc: |
  Original PacBio WDL: https://github.com/PacificBiosciences/HiFi-human-WGS-WDL/blob/main/workflows/sample_analysis/sample_analysis.wdl
requirements:
  - class: ShellCommandRequirement
  - class: InlineJavascriptRequirement
  - class: ResourceRequirement
    coresMin: $(inputs.threads)
    ramMin: $(inputs.threads*2000) # Uses ~2 GB memory / thread
  - class: DockerRequirement
    dockerPull: quay.io/pacbio/hificnv@sha256:19fdde99ad2454598ff7d82f27209e96184d9a6bb92dc0485cc7dbe87739b3c2
baseCommand: ["/bin/bash", "-c"]
arguments:
  - position: 0
    shellQuote: false
    valueFrom: |
      set -euo pipefail

      if [ -z "$(inputs.sex)" ]; then
        echo "Sex is not defined for $(inputs.sample_id). Defaulting to karyotype XX for TRGT."
      fi

      ${
        // Determine which bed file to use based on the sex input
        var expected_bed = "";
        if (inputs.sex === "MALE") {
          expected_bed = inputs.expected_bed_male.path;
        } else {
          expected_bed = inputs.expected_bed_female.path;
        }
        return "expected_bed=" + expected_bed;
      }

      hificnv --version

      hificnv \
        --threads $(inputs.threads) \
        --bam $(inputs.bam.path) \
        --ref $(inputs.reference.path) \
        --maf $(inputs.phased_vcf.path) \
        --exclude $(inputs.exclude_bed.path) \
        --expected-cn $expected_bed \
        --output-prefix $(inputs.sample_id).hificnv

      bcftools index --tbi $(inputs.sample_id).hificnv.vcf.gz

inputs:
  sample_id: { type: 'string' }
  sex: { type: 'string?' }
  bam: { type: 'File', secondaryFiles: [{pattern: ".bai", required: true}] }
  phased_vcf: { type: 'File', secondaryFiles: [{pattern: ".tbi", required: true}], doc: "basename(vcf, '.vcf.gz') + '.phased.vcf.gz.tbi'" }
  reference: { type: 'File', secondaryFiles: [{pattern: ".fai", required: true}] }
  exclude_bed: { type: 'File', secondaryFiles: [{pattern: ".tbi", required: true}], doc: "basename(bed, '.bed.gz') + '.bed.gz.tbi'" }
  expected_bed_male: { type: 'File' }
  expected_bed_female: { type: 'File' }
  output_prefix: { type: 'string?', default: "hificnv" }
  threads: { type: 'int?', default: 8, doc: "Number of threads to allocate to this task." }

outputs:
  cnv_vcf: { type: 'File', outputBinding: { glob: '*.vcf.gz' }, secondaryFiles: ['.tbi'] }
  copynum_bedgraph: { type: 'File', outputBinding: { glob: '*.bedgraph' } }
  depth_bw: { type: 'File', outputBinding: { glob: '*.depth.bw' } }
  maf_bw: { type: 'File', outputBinding: { glob: '*.maf.bw' } }
  