"""
Step 2: Split chromosome-level VCF-like files from Step 1 into evenly sized chunks. 
For example, chr1 may have many more variants than chr21. If you run one job per chromosome,
some jobs finish fast while others take much longer. Splitting into ~20 similarly sized chunks 
makes the Borzoi jobs more balanced, faster workflow.

Input: 22 unevenly sized VCF-like files from Step 1
  - format: CHROM POS ID REF ALT

Output: ~20 VCF-like files with approximately same number of lines/variants
    variants_chunk_00.vcf
    variants_chunk_01.vcf
    ...
    variants_chunk_19.vcf

Note: Since step 1 output files have no header, every line is a variant
------------------------------------------------------------------------
PSUEDOCODE: 
initialize total_line_counter = 0

for each VCF file:
    for each line:
        total_line_counter++

target_lines_per_file = ceil(total_line_counter / 20)

initialize chunk_index = 0
initialize current_line_count = 0
open output chunk file 0

for each VCF file:
    for each line:
        write line to current output chunk
        current_line_count++

        if current_line_count == target_lines_per_file:
            close current output chunk
            chunk_index++
            current_line_count = 0
            open next output chunk
"""

from pathlib import Path
import math
import argparse

def count_lines(file_paths):
    """
      Count total number of lines/variants across all input files.
    """
    total = 0
    for path in file_paths:
        with path.open("r") as f:
            for _ in f:
                total += 1
    return total

def main():
    # Creates an argument parser. This lets your script accept command-line options 
    # e.g. --input-dir, --output-dir, and --num-chunks
    parser = argparse.ArgumentParser(
        # the description is what appears if you run ```python scripts/split_vcfs_evenly.py --help```
        description="Split chromosome-level VCF-like files into evenly sized chunks."
    )

    # adds optional command-line argument called --input-dir
    parser.add_argument(
        "--input-dir",
        default="/lab-share/CHIP-Strober-e2/Public/Justin_Li/borzoi_inputs/vcfs",
        help="Directory containing chromosome-level VCF-like files from Step 1.",

        # if we just run ```python scripts/split_vcfs_evenly.py``` -> default filepath is used
        # if we override ```python scripts/split_vcfs_evenly.py --input-dir /different/input/folder``` -> different/input/path can be used
    )

    parser.add_argument(
        "--output-dir",
        default="/lab-share/CHIP-Strober-e2/Public/Justin_Li/borzoi_inputs/vcf_chunks",
        help="Directory where evenly sized VCF-like chunks will be written.",
    )

    parser.add_argument(
        "--num-chunks",
        type=int,
        default=20,
        help="Number of output chunks to create.",
    )

    args = parser.parse_args()

    input_dir = Path(args.input_dir)
    output_dir = Path(args.output_dir)
    num_chunks = args.num_chunks

    output_dir.mkdir(parents=True, exist_ok=True)

    # Find all chromosome-level VCF-like files from Step 1.
    input_files = sorted(
        input_dir.glob("gtex.eur.pass.rare_maf_lt_0.0025.snvs.chr*.vcf")
    )

    if len(input_files) == 0:
        raise RuntimeError(f"No input VCF files found in {input_dir}")

    print(f"Found {len(input_files)} input files:")
    for path in input_files:
        print(f"  {path}")
    print()

    # Count total number of variants.
    total_variants = count_lines(input_files)

    if total_variants == 0:
        raise RuntimeError("Input files contain 0 total variants.")

    print(f"Total variants: {total_variants}")

    # Each chunk should get approximately this many variants.
    target_lines_per_chunk = math.ceil(total_variants / num_chunks)

    print(f"Number of chunks: {num_chunks}")
    print(f"Target lines per chunk: {target_lines_per_chunk}")
    print()

    # Remove old output chunk files before writing new ones.
    for old_file in output_dir.glob("variants_chunk_*.vcf"):
        old_file.unlink()

    chunk_index = 0
    current_line_count = 0
    total_written = 0

    current_output_path = output_dir / f"variants_chunk_{chunk_index:02d}.vcf"
    current_output_file = current_output_path.open("w")

    print(f"Writing {current_output_path}")

    try:
        # Stream through each input file line by line.
        for input_file in input_files:
            print(f"Reading {input_file}")

            with input_file.open("r") as f:
                for line in f:
                    # If the current chunk is full, start a new one.
                    # Only open a new chunk if we have not reached the final chunk.
                    if (current_line_count >= target_lines_per_chunk and chunk_index < num_chunks - 1):
                        current_output_file.close()

                        chunk_index += 1
                        current_line_count = 0

                        current_output_path = output_dir / f"variants_chunk_{chunk_index:02d}.vcf"
                        current_output_file = current_output_path.open("w")

                        print(f"Writing {current_output_path}")

                    current_output_file.write(line)
                    current_line_count += 1
                    total_written += 1

    finally:
        current_output_file.close()

    print()
    print("Finished splitting files.")
    print(f"Total variants written: {total_written}")

    if total_written != total_variants:
        raise RuntimeError(
            f"ERROR: total_written={total_written} does not match total_variants={total_variants}"
        )

    print()
    print("Chunk sizes:")

    chunk_files = sorted(output_dir.glob("variants_chunk_*.vcf"))

    for chunk_file in chunk_files:
        n_lines = sum(1 for _ in chunk_file.open("r"))
        print(f"{chunk_file.name}: {n_lines} variants")

    print()
    print(f"Output directory: {output_dir}")
    print("Done.")


if __name__ == "__main__":
    main()

  
