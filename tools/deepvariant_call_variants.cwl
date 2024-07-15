## THIS WORKED WITH THE OUTPUT FROM 1.CWL AND FINISHED IN 13 MINUTES
class: CommandLineTool
cwlVersion: v1.2
id: deepvariant_call_variants
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
  - class: InitialWorkDirRequirement
    listing: 
      - $(inputs.example_tfrecord_tar)
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
        CMD += ' && tar -zxvf ' + inputs.example_tfrecord_tar.path
        CMD += ' && python /opt/deepvariant/bin/call_variants.zip'
        CMD += ' --outfile ./call_variants_output.tfrecord.gz'
        CMD += ' --examples "example_tfrecords/examples.tfrecord@${N_SHARDS}.gz"'

        if (inputs.custom_model) {
          CMD += ' --checkpoint ' + inputs.custom_model.path.split('.').slice(0, -1).join('.')
        } else if (inputs.model == 'WES') {
          CMD += ' --checkpoint /opt/models/wes/model.ckpt'
        } else if (inputs.model == 'WGS') {
          CMD += ' --checkpoint /opt/models/wgs/model.ckpt'
        } else if (inputs.model == 'PACBIO') {
          CMD += ' --checkpoint /opt/models/pacbio/model.ckpt'
        } else if (inputs.model == 'HYBRID_PACBIO_ILLUMINA') {
          CMD += ' --checkpoint /opt/models/hybrid_pacbio_illumina/model.ckpt'
        } else if (inputs.model == 'ONT_R104') {
          CMD += ' --checkpoint /opt/models/ont_r104/model.ckpt'
        }

        return CMD;
      }
  - prefix: ""
    shellQuote: false
    position: 4
    valueFrom: |
      ${
        return ' > ./call_variants.log 2>&1';
      }

inputs: 
  # Required inputs
  example_tfrecord_tar: { type: 'File', doc: "tf.Example protos containing DeepVariant candidate variants in TFRecord format, as emitted by make_examples." }
  custom_model: { type: 'File?', secondaryFiles: [{pattern: "^.index", required: true}, {pattern: "^.meta", required: true}], doc: "Custom TensorFlow model checkpoint to use to evaluate candidate variant calls. If not provided, the model trained by the DeepVariant team will be used." }
  model:
    type:
      - type: enum
        symbols: ["WGS", "WES", "PACBIO", "HYBRID_PACBIO_ILLUMINA", "ONT_R104"]
    doc: "TensorFlow model checkpoint to use to evaluate candidate variant calls."
 
  # Resources
  cpus_per_job: { type: 'int?', default: 36, doc: "Number of CPUs per job." }
  n_shards: { type: 'int?', default: 32 }
  mem_per_job: { type: 'int?', default: 1024, doc: "Memory per job[MB]." }

outputs:
  variants: { type: 'File', outputBinding: { glob: 'call_variants_output.tfrecord.gz' } }
