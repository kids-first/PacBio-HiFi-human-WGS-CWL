#!/bin/bash

set -euo pipefail
sample_id=$1
svsigs=$2
reference=$3
reference_name=$4
shard_index=$5
regions=$6
threads=$7

if [ -n $regions ]; then
  # pbsv has the ability to call SVs by region by using indexed signatures, but
  #   if an svsig.gz file doesn't contain any signatures in the region, then
  #   pbsv crashes. To avoid this, filter the svsig.gz files to only contain
  #   signatures in the regions.
  # This is brittle and likely to break if pbsv discover changes output format.
  # Build a pattern to match; we want headers (e.g., '^#') and signature
  #   records where third column matches the chromosome (e.g., '^.\t.\tchr1\t').
  pattern=$(echo $regions \
    | sed 's/^/^.\\t.\\t/; s/ /\\t\|^.\\t.\\t/g; s/$/\\t/' \
    | echo "^#|""$(</dev/stdin)")

  for svsig in $svsigs; do
    svsig_basename=$(basename "$svsig" .svsig.gz)
    gunzip -c "$svsig" \
      | grep -P "$pattern" \
      | bgzip -c > $svsig_basename.regions.svsig.gz" \
      && echo $svsig_basename.regions.svsig.gz" >> svsigs.fofn
  done
else
  cp $(echo $svsigs | tr ' ' '\n') svsigs.fofn
fi

pbsv --version

pbsv call \
  --hifi \
  --min-sv-length 20 \
  --log-level INFO \
  --num-threads $threads \
  $reference \
  svsigs.fofn \
  $sample_id.$reference_name.$shard_index.pbsv.vcf

bgzip --version

bgzip $sample_id.$reference_name.$shard_index.pbsv.vcf

tabix --version

tabix -p vcf $sample_id.$reference_name.$shard_index.pbsv.vcf.gz