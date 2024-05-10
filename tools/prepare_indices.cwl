class: ExpressionTool
cwlVersion: v1.2
id: prepare-indices
expression: | 
  ${
    var tasks_per_shard = Math.floor(inputs.total_deepvariant_tasks / inputs.num_shards)
    var indices = []
    for (var i = 0; i < inputs.num_shards; i++) {
      indices.push(i * tasks_per_shard)
    }
    return { "task_indices": indices }
  }

inputs:
  total_deepvariant_tasks: { type: 'int' }
  num_shards: { type: 'int' }

outputs:
  task_indices: { type: 'int[]' }