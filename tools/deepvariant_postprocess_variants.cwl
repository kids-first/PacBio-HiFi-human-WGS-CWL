class: CommandLineTool
cwlVersion: v1.2
id: deepvariant_postprocess_variants
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

        var log_dir = '/opt/deepvariant/logs/'
        CMD += ' && LOGDIR=' + log_dir
        CMD += ' && mkdir -p "${LOGDIR}"'
        CMD += ' && tar -zxvf ' + inputs.nonvariant_site_tfrecord.path

        CMD += ' && python /opt/deepvariant/bin/postprocess_variants.zip'
        CMD += ' --vcf_stats_report=false'
        CMD += ' --ref ' + inputs.reference.path 
        CMD += ' --infile ' + inputs.variants.path 
        CMD += ' --outfile ./' + inputs.sample_name + '.deepvariant.vcf'
        CMD += ' --nonvariant_site_tfrecord_path "nonvariant_site_tfrecords/gvcf.tfrecord@${N_SHARDS}.gz"'
        CMD += ' --gvcf_outfile ./' + inputs.sample_name + '.deepvariant.gvcf.gz'

        return CMD
      }
  - prefix: ""
    shellQuote: false
    position: 4
    valueFrom: |
      ${
        return ' > ./call_variants.log 2>&1';
      }

inputs:
  variants: { type: 'File' }
  sample_name: { type: 'string' }
  reference: { type: 'File', secondaryFiles: [{pattern: ".fai", required: false}, {pattern: ".gzi", required: false}], doc: "Genome reference to use. Must have an associated FAI index as well. Supports text or gzipped references. Should match the reference used to align the BAM file provided to the 'reads' input." }
  qual_filter: { type: 'float?', inputBinding: { prefix: "--qual_filter", position: 2 }, doc: "Any variant with QUAL < qual_filter will be filtered in the VCF file." }
  cnn_homref_call_min_gq: { type: 'float?', inputBinding: { prefix: "--cnn_homref_call_min_gq", position: 2 }, doc: "All CNN RefCalls whose GQ is less than this value will have ./. genotype instead of 0/0." }
  multi_allelic_qual_filter: { type: 'float?', inputBinding: { prefix: "--multi_allelic_qual_filter", position: 2 }, doc: "The qual value below which to filter multi-allelic variants." }
  nonvariant_site_tfrecord: { type: 'File', doc: "Path to the non-variant sites protos in TFRecord format to convert to gVCF file. This should be the complete set of outputs from the --gvcf flag of make_examples.py." }

  # Resources
  cpus_per_job: { type: 'int?', default: 36, doc: "Number of CPUs per job." }
  n_shards: { type: 'int?', default: 32 }
  mem_per_job: { type: 'int?', default: 1024, doc: "Memory per job[MB]." }

outputs:
  output_vcf: { type: 'File?', outputBinding: { glob: '*.vcf' } }
  output_gvcf: { type: 'File?', outputBinding: { glob: '*.gvcf.gz' }, secondaryFiles: ['.tbi'] }