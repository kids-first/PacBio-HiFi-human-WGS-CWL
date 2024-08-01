class: CommandLineTool
cwlVersion: v1.2
id: deepvariant_call_variants
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
  - class: InitialWorkDirRequirement
    listing: 
      - $(inputs.example_tfrecord_tar)
baseCommand: []
arguments:
  - position: 0
    shellQuote: false
    valueFrom: |
      export HOME=/root 
      N_SHARDS=$(inputs.n_shards ? inputs.n_shards : 32)

      tar -zxvf $(inputs.example_tfrecord_tar.path)

      python /opt/deepvariant/bin/call_variants.zip \
        --outfile ./call_variants_output.tfrecord.gz \
        --examples "example_tfrecords/examples.tfrecord@\${N_SHARDS}.gz" \
        ${
          var deepvariant_model_path = "";
          if (inputs.custom_model) {
            deepvariant_model_path = inputs.custom_model.path.split('.').slice(0, -1).join('.')
          } else {
            var modelMap = {
              'WES': '/opt/models/wes/model.ckpt',
              'WGS': '/opt/models/wgs/model.ckpt',
              'PACBIO': '/opt/models/pacbio/model.ckpt',
              'HYBRID_PACBIO_ILLUMINA': '/opt/models/hybrid_pacbio_illumina/model.ckpt',
              'ONT_R104': '/opt/models/ont_r104/model.ckpt'
            }
            deepvariant_model_path = modelMap[inputs.model]
          }
          return "--checkpoint " + deepvariant_model_path
        }

inputs: 
  # Required inputs
  example_tfrecord_tar: { type: 'File', doc: "tf.Example protos containing DeepVariant candidate variants in TFRecord format, as emitted by make_examples." }
  custom_model: { type: 'File?', secondaryFiles: [{pattern: "^.index", required: true}, {pattern: "^.meta", required: true}], doc: "Custom TensorFlow model checkpoint to use to evaluate candidate variant calls. If not provided, the model trained by the DeepVariant team will be used." }
  model:
    type:
      - 'null'
      - type: enum
        symbols: ["WGS", "WES", "PACBIO", "HYBRID_PACBIO_ILLUMINA", "ONT_R104"]
    default: "PACBIO"
    doc: "TensorFlow model checkpoint to use to evaluate candidate variant calls."
  # Resources
  n_shards: { type: 'int?', default: 32 }
  cpu: { type: 'int?', default: 36, doc: "CPUs to allocate to this task" }
  ram: { type: 'int?', default: 60, doc: "GB of RAM to allocate to this task." }

outputs:
  variants: { type: 'File', outputBinding: { glob: 'call_variants_output.tfrecord.gz' } }
