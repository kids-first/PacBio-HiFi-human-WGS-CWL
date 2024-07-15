## sbpack default d3b-bixu/kids-first-long-reads-dev/deepvariant_make_examples tools/1.cwl
## THIS WORKED AS WELL IN 1H23M BUT USING ALL OF THE PARAMETERS SPECIFIED IN WDL 
## THE OUTPUT OF THIS WAS SUCCESSFULLY RAN THROUGH CALL_VARIANTS STEP YAY (2.CWL)
class: CommandLineTool
cwlVersion: v1.2
id: deepvariant_make_examples
doc: |
  Original PacBio WDL: https://github.com/PacificBiosciences/wdl-common/blob/fef058b879d04c15c3da2626b320afdd8ace6c2e/wdl/workflows/deepvariant/deepvariant.wdl
requirements:
  - class: ShellCommandRequirement
  - class: InlineJavascriptRequirement
  - class: ResourceRequirement
    ramMin: |
      ${
        if (inputs.mem_per_job) {
          return inputs.mem_per_job;
        } else {
          return 1024;
        }
      }
    coresMin: |
      ${
        return inputs.cpus_per_job ? inputs.cpus_per_job : 36;
      }
  - class: DockerRequirement
    dockerPull: images.sbgenomics.com/raisa_petrovic/deepvariant1-5-0:5
baseCommand: ["/bin/bash", "-c"]
arguments:
  - prefix: ""
    shellQuote: false
    position: 0
    valueFrom: |
      ${
        var n_shards = inputs.n_shards ? inputs.n_shards : 32
        var CMD = 'export HOME=/root && N_SHARDS=' + n_shards

        CMD += ' && mkdir -p example_tfrecords nonvariant_site_tfrecords'

        var log_dir = '/opt/deepvariant/logs/'

        CMD += ' && LOGDIR=' + log_dir
        CMD += ' && mkdir -p "${LOGDIR}"'

        CMD += ' && ( /usr/bin/time seq 0 $((N_SHARDS-1))'
        CMD += ' | parallel --eta --halt 2 --joblog "${LOGDIR}/log" --res "${LOGDIR}"'
        CMD += ' python /opt/deepvariant/bin/make_examples.zip'
        CMD += ' --reads ' + inputs.reads.path
        CMD += ' --ref ' + inputs.reference.path
        CMD += ' --norealign_reads'
        CMD += ' --vsc_min_fraction_indels 0.12'
        CMD += ' --pileup_image_width 199'
        CMD += ' --track_ref_reads'
        CMD += ' --phase_reads'
        CMD += ' --partition_size=25000'
        CMD += ' --max_reads_per_partition=600'
        CMD += ' --alt_aligned_pileup=diff_channels'
        CMD += ' --add_hp_channel'
        CMD += ' --sort_by_haplotypes'
        CMD += ' --parse_sam_aux_fields'
        CMD += ' --min_mapping_quality=1'
        CMD += ' --mode calling'
        CMD += ' --task {}'
        CMD += ' --examples "example_tfrecords/examples.tfrecord@${N_SHARDS}.gz"'
        CMD += ' --gvcf "nonvariant_site_tfrecords/gvcf.tfrecord@${N_SHARDS}.gz" )'

        CMD += ' && tar -zcvf example_tfrecords.tar.gz example_tfrecords'
        CMD += ' && tar -zcvf nonvariant_site_tfrecords.tar.gz nonvariant_site_tfrecords'

        return CMD;
      }
  - prefix: ""
    shellQuote: false
    position: 4
    valueFrom: |
      ${
        return " > ./make_examples.log 2>&1";
      }

inputs:
  # Required inputs
  reference: { type: 'File', secondaryFiles: [{pattern: ".fai", required: false}, {pattern: ".gzi", required: false}], doc: "Genome reference to use. Must have an associated FAI index as well. Supports text or gzipped references. Should match the reference used to align the BAM file provided to the 'reads' input." }
  reads: { type: 'File', secondaryFiles: [{pattern: "^.bai", required: false}, {pattern: ".bai", required: false}], doc: "Aligned, sorted, indexed BAM file containing the reads we want to call. Should be aligned to a reference genome compatible with the FASTA provided on the 'ref' input." }
  # Resources
  cpus_per_job: { type: 'int?', default: 36, doc: "Number of CPUs per job." }
  n_shards: { type: 'int?', default: 32 }
  mem_per_job: { type: 'int?', default: 1024, doc: "Memory per job[MB]." }

outputs: 
  example_tfrecord_tar: { type: 'File', outputBinding: { glob: 'example_tfrecords.tar.gz' } }
  nonvariant_site_tfrecord_tar: { type: 'File', outputBinding: { glob: 'nonvariant_site_tfrecords.tar.gz' } }
