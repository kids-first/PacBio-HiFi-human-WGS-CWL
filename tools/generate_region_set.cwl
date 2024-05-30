class: ExpressionTool
cwlVersion: v1.2
id: generate-region-set
expression: |
  ${
    var fs = require("fs")
    var pbsv_splits = JSON.parse(fs.readFileSync(inputs.input_json.path))
    var shard_indices = []
    var region_sets = []
    pbsv_splits.forEach((regions, index) => {
      regions.forEach(region => {
        shard_indices.push(index)
        region_sets.push(region)
      })
    })
    return {
      shard_indices: shard_indices,
      region_sets: region_sets
    }
  }

inputs:
  input_json: { type: 'File' }

outputs:
  shard_indices:
    type: int[]
  region_sets:
    type: string[]