class: CommandLineTool
cwlVersion: v1.2
id: deepvariant_call_variants
doc: |
  Original PacBio WDL: https://github.com/PacificBiosciences/wdl-common/blob/fef058b879d04c15c3da2626b320afdd8ace6c2e/wdl/workflows/deepvariant/deepvariant.wdl
requirements:
  - class: ShellCommandRequirement
  - class: InitialWorkDirRequirement
    listing:
      - entry: $(inputs.example_tfrecord_tars)
        writable: true
  - class: InlineJavascriptRequirement
  - class: ResourceRequirement
    coresMin: $(inputs.threads)
    ramMin: $(inputs.total_deepvariant_tasks*4000) # Int mem_gb = total_deepvariant_tasks * 4
  - class: DockerRequirement
    dockerPull: gcr.io/deepvariant-docker/deepvariant:1.5.0
baseCommand: ["/bin/bash", "-c"]
arguments:
  - position: 0
    shellQuote: false
    valueFrom: |
      set -euo pipefail

      for tfrecord_tar in $(inputs.example_tfrecord_tars); do
        tar -zxvf "$tfrecord_tar"
      done

      ${
        var deepvariant_model_path = "";
        if (inputs.deepvariant_model) {
          deepvariant_model_path = inputs.deepvariant_model.replace(/\.data.*/, "");
        } else {
          deepvariant_model_path = "/opt/models/pacbio/model.ckpt";
        }
        return "deepvariant_model_path=" + deepvariant_model_path;
      }

      echo "DeepVariant version: 1.5.0"

      /opt/deepvariant/bin/call_variants \
        --outfile $(inputs.sample_id).$(inputs.reference_name).call_variants_output.tfrecord.gz \
        --examples "example_tfrecords/$(inputs.sample_id).examples.tfrecord@$(inputs.total_deepvariant_tasks).gz" \
        --checkpoint "${deepvariant_model_path}"

inputs:
  sample_id: { type: 'string' }
  reference_name: { type: 'string' }
  deepvariant_model: { type: 'File?' } # DeepVariantModel? deepvariant_model
  example_tfrecord_tars: { type: 'File[]' }
  total_deepvariant_tasks: { type: 'int' }
  threads: { type: 'int?', default: 2, doc: "Number of threads to allocate to this task." }
  
outputs:
  tfrecord: { type: 'File', outputBinding: { glob: '*.tfrecord.gz' } }
