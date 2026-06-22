#!/bin/bash
#SBATCH --job-name=borzoi_first5
#SBATCH --partition=bch-gpu
#SBATCH --gpus=1
#SBATCH --mem=20G
#SBATCH --time=0-20:00
#SBATCH --output=/lab-share/CHIP-Strober-e2/Public/Justin_Li/borzoi_logs/borzoi_chunk_%A_%a.out
#SBATCH --error=/lab-share/CHIP-Strober-e2/Public/Justin_Li/borzoi_logs/borzoi_chunk_%A_%a.err

set -euo pipefail

echo "Starting job"
echo "SLURM_JOB_ID: ${SLURM_JOB_ID}"
echo "SLURM_ARRAY_TASK_ID: ${SLURM_ARRAY_TASK_ID}"
echo "Running on node: $(hostname)"
echo "Start time: $(date)"

#####################
# Environment
#####################

module load miniforge/default
conda activate /lab-share/CHIP-Strober-e2/Public/Justin_Li/envs/borzoi_py310
export LD_LIBRARY_PATH="$CONDA_PREFIX/lib:$LD_LIBRARY_PATH"

#####################
# Paths
#####################

JUSTIN_ROOT="/lab-share/CHIP-Strober-e2/Public/Justin_Li"

BORZOI_TRAINING_DIR="/lab-share/CHIP-Strober-e2/Public/ben/s2e_uncertainty/borzoi_input_data/models"
BORZOI_GTEX_TARGET_FILE="${BORZOI_TRAINING_DIR}/targets_gtex.txt"

FASTA_FILE="/lab-share/CHIP-Strober-e2/Public/ben/borzoi_genome_wide_run/input_data/hg38.fa"
GENE_GTF_FILE="/lab-share/CHIP-Strober-e2/Public/ben/borzoi_genome_wide_run/input_data/gencode41_basic_nort.gtf"

VARIANT_GENE_PAIR_FILE="/lab-share/CHIP-Strober-e2/Public/ben/rare_variant_s2e/preprocess_rare_variants/gtex.eur.pass.rare_maf_lt_0.0025.snvs.variant_gene_pairs.txt"

VCF_DIR="${JUSTIN_ROOT}/borzoi_inputs/vcf_chunks"
OUTPUT_DIR="${JUSTIN_ROOT}/borzoi_outputs/first5_chunks"
LOG_DIR="${JUSTIN_ROOT}/borzoi_logs"

mkdir -p "${OUTPUT_DIR}"
mkdir -p "${LOG_DIR}"

#####################
# Select chunk
#####################

CHUNK_ID=$(printf "%02d" "${SLURM_ARRAY_TASK_ID}")

VCF_FILE="${VCF_DIR}/variants_chunk_${CHUNK_ID}.vcf"
OUTPUT_FILE="${OUTPUT_DIR}/variants_chunk_${CHUNK_ID}.borzoi_output.h5"

echo "CHUNK_ID: ${CHUNK_ID}"
echo "VCF_FILE: ${VCF_FILE}"
echo "OUTPUT_FILE: ${OUTPUT_FILE}"

#####################
# Sanity checks
#####################

ls -lh "${VCF_FILE}"
ls -lh "${VARIANT_GENE_PAIR_FILE}"
ls -lh "${BORZOI_GTEX_TARGET_FILE}"
ls -lh "${BORZOI_TRAINING_DIR}/params_pred.json"
ls -lh "${BORZOI_TRAINING_DIR}/model0_best_f3c0.h5"
ls -lh "${FASTA_FILE}"
ls -lh "${GENE_GTF_FILE}"

nvidia-smi

#####################
# Run Borzoi
#####################

cd /lab-share/CHIP-Strober-e2/Public/Justin_Li/repos/borzoi_genome_wide_run/genome_wide_run

python fast_borzoi_sed.py \
  -o "${OUTPUT_FILE}" \
  -v "${VARIANT_GENE_PAIR_FILE}" \
  --batch_size 4 \
  --rc \
  --stats logSED,refLog,altLog \
  -f "${FASTA_FILE}" \
  -g "${GENE_GTF_FILE}" \
  -t "${BORZOI_GTEX_TARGET_FILE}" \
  "${BORZOI_TRAINING_DIR}/params_pred.json" \
  "${BORZOI_TRAINING_DIR}/model0_best_f3c0.h5" \
  "${VCF_FILE}"

echo "Finished job"
echo "End time: $(date)"
ls -lh "${OUTPUT_FILE}"
