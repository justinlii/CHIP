
# The goal is to run fast_borzoi_sed.sh for all variants in 
# /lab-share/CHIP-Strober-e2/Public/ben/rare_variant_s2e/preprocess_rare_variants/gtex.eur.pass.rare_maf_lt_0.0025.snvs.chr*.rare_variant_carriers_near_genes.tsv.gz

#####################
# Input data
#####################

# Directory containing source files (these have additional columns)
source_dir = /lab-share/CHIP-Strober-e2/Public/ben/rare_variant_s2e/preprocess_rare_variants/gtex.eur.pass.rare_maf_lt_0.0025.snvs.chr*.rare_variant_carriers_near_genes.tsv.gz

# We want to convert source files to vcf format, which has fewer columns
# Convert GTEx rare variant "near gene" files into the simplified
# 5-column Borzoi variant input format:
#
#   CHROM    POS    ID    REF    ALT
#
# Source files contain extra columns:
#   CHROM POS ID REF ALT RARE_ALLELE MAF RARE_AC AN CARRIERS gene_ids
#
# We retain only columns 1-5 and remove duplicate variant rows.

INPUT_DIR="/lab-share/CHIP-Strober-e2/Public/ben/rare_variant_s2e/preprocess_rare_variants"

#####################
# Output data
#####################
OUTPUT_DIR="/lab-share/CHIP-Strober-e2/Public/Justin_Li/borzoi_inputs/vcfs"


########################
# Subsetting columns
########################
mkdir -p "${OUTPUT_DIR}"

# confirm input and output directories
echo "Input directory: ${INPUT_DIR}"
echo "Output directory: ${OUTPUT_DIR}"
echo

# Bash setting that returns empty list if no files match the pattern below
shopt -s nullglob

input_files=(
  "${INPUT_DIR}"/gtex.eur.pass.rare_maf_lt_0.0025.snvs.chr*.rare_variant_carriers_near_genes.tsv.gz
)

# shopt -s nullglob from above allows the code below to work properly
if [ ${#input_files[@]} -eq 0 ]; then
    echo "ERROR: No input files found."
    exit 1
fi

# Iterate through each input file, skip the header, subset columns CHROM/POS/ID/REF/ALT,
# remove duplicate variants, and write the result as a simplified 5-column VCF-like file.
for f in "${input_files[@]}"
do
    # the suffix removed is .rare_variant_carriers_near_genes.tsv.gz
    base=$(basename "$f" .rare_variant_carriers_near_genes.tsv.gz) # extracting the base of the filename
    out="${OUTPUT_DIR}/${base}.vcf" # constructing output file path

    # printing progress messages
    echo "Converting:"
    echo "  input:  $f"
    echo "  output: $out"

    # decompresses the .tsv.gz file and streams its contents line by line. It does not create an uncompressed temporary file
    # BEGIN{OFS="\t"} means the output columns should be separated by tabs.
    # NR>1 means only process rows after line 1. This skips the header row.
    
    zcat "$f" \
      | awk 'BEGIN{OFS="\t"} NR>1 {
            key=$1 FS $2 FS $3 FS $4 FS $5;
            if (!seen[key]++) print $1,$2,$3,$4,$5
        }' \
      > "$out" # writes output into the .vcf file

    n_rows=$(wc -l < "$out")
    echo "  wrote ${n_rows} unique variants"
    echo
done
