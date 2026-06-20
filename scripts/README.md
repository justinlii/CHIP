The goal is to run fast_borzoi_sed.sh for all variants in 
/lab-share/CHIP-Strober-e2/Public/ben/rare_variant_s2e/preprocess_rare_variants/gtex.eur.pass.rare_maf_lt_0.0025.snvs.chr*.rare_variant_carriers_near_genes.tsv.gz

This goal is split into 5 steps

Step 0: Install borzoi on e3. Recommend using "conda". Also highly recommend prompting chat gpt to help with your install of Borzoi.

Step 1: Convert files in /lab-share/CHIP-Strober-e2/Public/ben/rare_variant_s2e/preprocess_rare_variants/gtex.eur.pass.rare_maf_lt_0.0025.snvs.chr*.rare_variant_carriers_near_genes.tsv.gz to format of ${example_variant_vcf_file} by subsetting colums. See examples here: https://github.com/BennyStrobes/borzoi_genome_wide_run/blob/main/genome_wide_run/run_example_for_justin.sh

Step 2: Split 22 (unevenly sized) vcf files into ~20 evenly sized vcf files with same number of lines (ie variants) per file

Step 3: For one of 20 evenly sized vcf files, make sure you can run fast_borzoi_sed.py for that 1 vcf file. See line 68 of https://github.com/BennyStrobes/borzoi_genome_wide_run/blob/main/genome_wide_run/run_example_for_justin.sh where all you have to do is swap -v argument to all variant-gene pairs files (see above) and switch $example_variant_vcf_file to vcf file of interest. This step will be done using interactive GPU job.

Step 4: Submit all 20 jobs at once. each job should take < 30 hours, so request 30 hours + 25GB of memory on gpu. (edited) 
