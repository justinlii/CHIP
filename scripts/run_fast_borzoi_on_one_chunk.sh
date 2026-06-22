# Step 3: For one of 20 evenly sized vcf files, check that you can run fast_borzoi_sed.py for 1 vcf file.
# See line 68 https://github.com/BennyStrobes/borzoi_genome_wide_run/blob/main/genome_wide_run/run_example_for_justin.sh
# Replace -v argument to all variant-gene pairs files and switch $example_variant_vcf_file to vcf file of interest

# enter personal directory
cd /lab-share/CHIP-Strober-e2/Public/Justin_Li
# 1. Start GPU session
srun -p bch-gpu --gpus 1 --mem 20G -t 0-03:00 --pty bash # get onto a GPU node

#####################
# Environment
#####################
module load miniforge/default # activate Borzoi environment
conda activate /lab-share/CHIP-Strober-e2/Public/Justin_Li/envs/borzoi_py310

# (make sure that the borzoi_genome_wide repo is cloned)
# git clone https://github.com/BennyStrobes/borzoi_genome_wide_run.git

#####################
# Define input paths 
#####################
borzoi_training_dir="/lab-share/CHIP-Strober-e2/Public/ben/s2e_uncertainty/borzoi_input_data/models/"
borzoi_gtex_target_file="/lab-share/CHIP-Strober-e2/Public/ben/s2e_uncertainty/borzoi_input_data/models/targets_gtex.txt"
fasta_file="/lab-share/CHIP-Strober-e2/Public/ben/borzoi_genome_wide_run/input_data/hg38.fa"
gene_gtf_file="/lab-share/CHIP-Strober-e2/Public/ben/borzoi_genome_wide_run/input_data/gencode41_basic_nort.gtf"
variant_gene_pair_file="/lab-share/CHIP-Strober-e2/Public/ben/rare_variant_s2e/preprocess_rare_variants/gtex.eur.pass.rare_maf_lt_0.0025.snvs.variant_gene_pairs.txt"
variant_vcf_file="/lab-share/CHIP-Strober-e2/Public/Justin_Li/borzoi_inputs/vcf_chunks/variants_chunk_00.vcf"

#####################
# Output data
#####################
output_root="/lab-share/CHIP-Strober-e2/Public/Justin_Li/borzoi_outputs/chunk_00_test/"
mkdir -p "${output_root}"
output_file="${output_root}/variants_chunk_00.borzoi_output.h5"

#####################
# Run Borzoi
#####################
python fast_borzoi_sed.py \
  -o "${output_file}" \
  -v "${variant_gene_pair_file}" \
  --batch_size 4 \
  --rc \
  --stats logSED,refLog,altLog \
  -f "${fasta_file}" \
  -g "${gene_gtf_file}" \
  -t "${borzoi_gtex_target_file}" \
  "${borzoi_training_dir}/params_pred.json" \
  "${borzoi_training_dir}/model0_best_f3c0.h5" \
  "${variant_vcf_file}"

echo
echo "Done."
ls -lh "${output_file}"
