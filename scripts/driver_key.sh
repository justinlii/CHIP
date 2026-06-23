#!/bin/bash
# driver_key.sh
#
# Reproducible end-to-end driver for the Borzoi rare-variant workflow on E3.
#
# Run this file from the repo root with:
#   bash scripts/driver_key.sh
# 
# Prerequisites: must have borzoi installed
#
# This script executes the workflow in order:
#   Step 1: Convert near-gene rare-variant TSVs into 5-column VCF-like files
#   Step 2: Split chromosome-level VCF-like files into balanced chunks
#   Step 3: Submit Borzoi SLURM array jobs for the selected chunks
#
# The SLURM jobs run asynchronously after submission. This script submits them
# and prints the SLURM job ID plus useful output/log locations.

set -eo pipefail

script_dir="/lab-share/CHIP-Strober-e2/Public/Justin_Li/CHIP/scripts"
chip_repo_dir="/lab-share/CHIP-Strober-e2/Public/Justin_Li/CHIP/"
justin_root="/lab-share/CHIP-Strober-e2/Public/Justin_Li"
borzoi_repo_dir="${justin_root}/repos/borzoi_genome_wide_run"


#####################
# Input data
#####################

# Rare variant near-gene TSV source directory. -> preprocessed rare variants 
near_gene_tsv_dir="/lab-share/CHIP-Strober-e2/Public/ben/rare_variant_s2e/preprocess_rare_variants"

# Directory containing pre-trained Borzoi models.
borzoi_training_dir="/lab-share/CHIP-Strober-e2/Public/ben/s2e_uncertainty/borzoi_input_data/models"

# Model config and weights.
borzoi_params_file="${borzoi_training_dir}/params_pred.json"
borzoi_model_file="${borzoi_training_dir}/model0_best_f3c0.h5"

# Borzoi target file for current GTEx-focused run.
borzoi_target_file="${borzoi_training_dir}/targets_gtex.txt"

# Reference genome FASTA.
fasta_file="/lab-share/CHIP-Strober-e2/Public/ben/borzoi_genome_wide_run/input_data/hg38.fa"

# Gene annotation GTF used by fast_borzoi_sed.py.
gene_gtf_file="/lab-share/CHIP-Strober-e2/Public/ben/borzoi_genome_wide_run/input_data/gencode41_basic_nort.gtf"

# Variant-gene pair file used by fast_borzoi_sed.py.
variant_gene_pair_file="${near_gene_tsv_dir}/gtex.eur.pass.rare_maf_lt_0.0025.snvs.variant_gene_pairs.txt"

#####################
# Output data
#####################

# Directory for Step 1 chromosome-level 5-column VCF-like files
vcf_dir="${justin_root}/borzoi_inputs/vcfs"

# Directory for Step 2 balanced VCF chunks.
vcf_chunk_dir="${justin_root}/borzoi_inputs/vcf_chunks"

# Output root for Borzoi predictions
output_root="${justin_root}/borzoi_outputs"

# Borzoi prediction output directory for first 5 chunks
borzoi_pred_dir="${output_root}/first5_chunks"

# SLURM log directory.
log_dir="${justin_root}/borzoi_logs"

#####################
# Environment
#####################

conda_env="${justin_root}/envs/borzoi_py310"

# Batch job configuration
partition="bch-gpu"
borzoi_num_chunks=5
borzoi_max_parallel=5
gpus_per_job=1
mem_per_job="20G"
time_per_job="0-20:00"
batch_size=5

mkdir -p "${vcf_dir}"
mkdir -p "${vcf_chunk_dir}"
mkdir -p "${borzoi_pred_dir}"
mkdir -p "${log_dir}"


#####################
# Execute workflow
#####################

# step 1 - convert tsvs (preprocessed) to vcf (processed)
if false; then
    INPUT_DIR="${near_gene_tsv_dir}" \
    OUTPUT_DIR="${vcf_dir}" \
    bash "${script_dir}/convert_near_gene_tsvs_to_vcf.sh"
fi

# step 2 - split vcfs into 20 evenly distributed chunks
if false; then
    python "${script_dir}/split_vcfs_evenly.py" \
        --input-dir "${vcf_dir}" \
        --output-dir "${vcf_chunk_dir}" \
        --num-chunks 20
fi

# step 3 - submit 5 chunks to borzoi
if false; then
    sbatch "${script_dir}/run_first5_chunks.sbatch"
fi

echo
echo "Driver finished"
echo "Driver finished at: $(date)"
echo "Note: SLURM Borzoi jobs continue running asynchronously after this driver exits."
