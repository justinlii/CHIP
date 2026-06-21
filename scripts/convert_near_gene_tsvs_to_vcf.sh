#!/bin/bash
set -euo pipefail

# Step 1: Prepare variant input files for fast_borzoi_sed.py.
# This script does not run Borzoi yet; it converts rare variant near-gene files
# into the simplified 5-column VCF-like format expected by the Borzoi pipeline.
#
# Source files:
#   /lab-share/CHIP-Strober-e2/Public/ben/rare_variant_s2e/preprocess_rare_variants/
#   gtex.eur.pass.rare_maf_lt_0.0025.snvs.chr*.rare_variant_carriers_near_genes.tsv.gz
#
# Source columns:
#   CHROM POS ID REF ALT RARE_ALLELE MAF RARE_AC AN CARRIERS gene_ids
#
# Output columns:
#   CHROM POS ID REF ALT
#
# We skip the header row, retain only columns 1-5, and remove duplicate variants.

#####################
# Input/output paths
#####################

INPUT_DIR="/lab-share/CHIP-Strober-e2/Public/ben/rare_variant_s2e/preprocess_rare_variants"
OUTPUT_DIR="/lab-share/CHIP-Strober-e2/Public/Justin_Li/borzoi_inputs/vcfs"

mkdir -p "${OUTPUT_DIR}"

echo "Input directory: ${INPUT_DIR}"
echo "Output directory: ${OUTPUT_DIR}"
echo

# If the file pattern matches no files, return an empty list instead of the literal pattern.
shopt -s nullglob

input_files=(
  "${INPUT_DIR}"/gtex.eur.pass.rare_maf_lt_0.0025.snvs.chr*.rare_variant_carriers_near_genes.tsv.gz
)

if [ ${#input_files[@]} -eq 0 ]; then
    echo "ERROR: No input files found."
    exit 1
fi

# Iterate through each input file, skip the header, subset columns CHROM/POS/ID/REF/ALT,
# remove duplicate variants, and write the result as a simplified 5-column VCF-like file.
for f in "${input_files[@]}"
do
    base=$(basename "$f" .rare_variant_carriers_near_genes.tsv.gz)
    out="${OUTPUT_DIR}/${base}.vcf"

    echo "Converting:"
    echo "  input:  $f"
    echo "  output: $out"

    zcat "$f" \
      | awk 'BEGIN{OFS="\t"} NR>1 {
            key=$1 FS $2 FS $3 FS $4 FS $5;
            if (!seen[key]++) print $1,$2,$3,$4,$5
        }' \
      > "$out"

    n_rows=$(wc -l < "$out")
    echo "  wrote ${n_rows} unique variants"
    echo
done

echo "Done converting files."
