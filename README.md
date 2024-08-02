# KFDRC PacBio HiFi WGS Variant Workflow

<p align="center">
  <img src="https://github.com/d3b-center/d3b-research-workflows/raw/master/doc/kfdrc-logo-sm.png">
</p>

This repository contains PacBio HiFi WGS Variant Pipeline used for the Kids First Data Resource Center (DRC).

## Workflow

The HiFi Human WGS Variant Workflow is designed to process PacBio HiFi sequencing data for WGS applications, including read alignment, variant calling, and phasing. This workflow has been converted to CWL from PacBio's [HiFi-human-WGS-WDL](https://github.com/PacificBiosciences/HiFi-human-WGS-WDL) `sample_analysis` workflow.

Workflow steps include: 
- Read alignment
- Small variant calling
- Structural variant calling
- Phasing
- Coverage analysis
- CNV calling

See our documentation for more details: 
- [Documentation](./docs/SAMPLE_ANALYSIS_README.md)
- [CWL Workflow](./workflows/sample_analysis.cwl)
