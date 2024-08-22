# KFDRC PacBio HiFi WGS Variant Workflow

<p align="center">
  <img src="https://github.com/d3b-center/d3b-research-workflows/raw/master/doc/kfdrc-logo-sm.png">
</p>

The KFDRC PacBio HiFi WGS Variant Workflow performs read alignment, variant calling, and phasing. This CWL is a conversion of PacBio's [HiFi-human-WGS-WDL](https://github.com/PacificBiosciences/HiFi-human-WGS-WDL) `sample_analysis.wdl`. 

 ## Relevant Softwares and Versions
 
- [bcftools](https://github.com/samtools/bcftools): `1.14`
- [DeepVariant](https://github.com/google/deepvariant): `1.5.0`
- [HiFiCNV](https://github.com/PacificBiosciences/HiFiCNV): `0.1.7`
- [HiPhase](https://github.com/PacificBiosciences/HiPhase): `1.0.0`
- [mosdepth](https://github.com/brentp/mosdepth): `0.2.9`
- [paraphase](https://github.com/PacificBiosciences/paraphase): `2.2.3`
- [pb-CpG-tools](https://github.com/PacificBiosciences/pb-CpG-tools): `2.3.2`
- [pbmm2](https://github.com/PacificBiosciences/pbmm2): `1.10.0`
- [pbsv](https://github.com/PacificBiosciences/pbsv): `2.9.0`
- [trgt](https://github.com/PacificBiosciences/trgt): `0.5.0`

 ## Inputs
 
- Universal
    Recommended:
    - `bam`: Unaligned sample BAM.
    - `reference_fasta`: Reference genome and index.
    - `sample_id`: Used to name outputs.

- HiFiCNV
    - `exclude_bed`: Compressed BED and index of regions to exclude from calling by HiFiCNV (recommended: [`cnv.excluded_regions.common_50.hg38.bed.gz`](https://github.com/PacificBiosciences/HiFiCNV/blob/main/docs/aux_data.md)).
    - `expected_bed_female`: BED of expected copy number for female karyotype for HiFiCNV (recommended: `expected_cn.hg38.XX.bed`).
    - `expected_bed_male`: BED of expected copy number for male karyotype for HiFiCNV (recommended: `expected_cn.hg38.XY.bed`).

- Tandem Repeat
  - Recommended:
    - `reference_tandem_repeat_bed`: Tandem repeat locations used by pbsv to normalize SV representation (recommended: `human_GRCh38_no_alt_analysis_set.trf.bed`).
    - `trgt_tandem_repeat_bed`: Tandem repeat sites to be genotyped by TRGT (recommended: `human_GRCh38_no_alt_analysis_set.trgt.v0.3.4.bed`).
  - Optional:
    - `sex`: ["MALE", "FEMALE", null]. If the sex field is missing or null, sex will be set to unknown. Used to set the expected sex chromosome karyotype for TRGT and HiFiCNV (defaults to karyotype XX).

- DeepVariant
  - Recommended:
    - `model`: TensorFlow model checkpoint to use to evaluate candidate variant calls. Default is set to `PACBIO` for PacBio data.
  - Optional: 
    - `custom_model`: Alternatively, a custom TensorFlow model checkpoint may be used to evaluate candidate variant calls. If not provided, the `model` trained by the DeepVariant team will be used.


A reference data bundle for this pipeline can be found [here](https://zenodo.org/records/8415406). 
```bash
# download the reference data bundle
wget https://zenodo.org/records/8415406/files/wdl-humanwgs.v1.0.2.resource.tgz?download=1

# extract the reference data bundle and rename as dataset
tar -xzf wdl-humanwgs.v1.0.2.resource.tgz && mv static_resources PacBio_reference_bundle
```

 ## Outputs
 
- BAM stats and alignment
    - `bam_stats`: TSV of length and quality for each read.
    - `read_length_summary`: Read length distribution.
    - `read_quality_summary`: Read quality distribution.
    - `aligned_bam`: Aligned BAM.
    - `svsig`: Structural variant signatures. 

- Small variants
    - `deepvariant_vcf`: Small variants (SNPs and INDELs < 50bp) VCF called by DeepVariant (with index).
    - `deepvariant_gvcf`: Small variants (SNPs and INDELs < 50bp) gVCF called by DeepVariant (with index).
    - `deepvariant_vcf_stats`: bcftools stats summary statistics for small variants.
    - `deepvariant_roh_out`: Output of `bcftools roh` using `--AF-dflt 0.4`.
    - `deepvariant_roh_bed`: Regions of homozygosity determiend by `bcftools roh` using `--AF-dflt 0.4`.

- Structural variants
    - `pbsv_call_vcf`: Structural variants called by pbsv (with index).

- Phased variant calls and haplotagged alignments
    - `phased_deepvariant_vcf`: Small variants called by DeepVariant and phased by HiPhase (with index).
    - `phased_pbsv_vcf`: Structural variants called by pbsv and phased by HiPhase (with index).
    - `phased_summary`: Phasing summary TSV file.
    - `hiphase_stats`: Phase block summary statistics written by [HiPhase](https://github.com/PacificBiosciences/HiPhase/blob/main/docs/user_guide.md#chromosome-summary-file---summary-file).
    - `hiphase_blocks`: Phase block list written by [HiPhase](https://github.com/PacificBiosciences/HiPhase/blob/main/docs/user_guide.md#phase-block-file---blocks-file).
    - `hiphase_haplotags`: Per-read haplotag information, written by [HiPhase](https://github.com/PacificBiosciences/HiPhase/blob/main/docs/user_guide.md#haplotag-file---haplotag-file).
    - `hiphase_bam`: Aligned (by pbmm2), haplotagged (by HiPhase) reads (with index).
    - `haplotagged_bam_mosdepth_summary`: mosdepth summary of median depths per chromosome. 
    - `haplotagged_bam_mosdepth_region_bed`: mosdepth BED of median coverage depth per 500 bp window.
    - `paraphase_output_json`: Paraphase summary file.
    - `paraphase_realigned_bam`: Realigned BAM for selected medically relevant genes in segmental duplications (with index).
    - `paraphase_vcfs`: Phased Variant calls for selected medically relevant genes in segmental duplications.

- Tandem repeat information
    - `trgt_spanning_reads`: Fragments of HiFi reads spanning loci genotyped by TRGT (with index).
    - `trgt_repeat_vcf`: Tandem repeat genotypes from TRGT (with index).

- Methylation
    - `cpg_pileup_beds`: 5mCpG site methylation probability pileups.
    - `cpg_pileup_bigwigs`: 5mCpG site methylation probability pileups.

- CNVs
    - `hificnv_vcf`: VCF output containing copy number variant calls for the sample from HiFiCNV.
    - `hificnv_copynum_bedgraph`: Copy number values calculated for each region. 
    - `hificnv_depth_bw`: Bigwig file containing the depth measurements from HiFiCNV.
    - `hificnv_maf_bw`: Bigwig file containing the minor allele frequency measurements from DeepVariant, generated by HiFiCNV.


 ## Estimated Run Times

We processed a 26.5 GB BAM file using the KFDRC PacBio HiFi WGS Variant Workflow with default settings on CAVATICA. Here are the details of the run:
- Run Time: 12 hours, 49 minutes
- Cost: $10.22


## Other Resources

- [HiFi-human-WGS-WDL](https://github.com/PacificBiosciences/HiFi-human-WGS-WDL)
- [sample_analysis.wdl](https://github.com/PacificBiosciences/HiFi-human-WGS-WDL/blob/main/workflows/sample_analysis/sample_analysis.wdl)
- [Dockerfiles](https://github.com/PacificBiosciences/HiFi-human-WGS-WDL/tree/main?tab=readme-ov-file#tool-versions-and-docker-images)
- [GRCh38 reference data bundle](https://zenodo.org/records/8415406)
