#!/bin/bash
#SBATCH --job-name=alu_n10
#SBATCH --partition=core
#SBATCH --cpus-per-task=32
#SBATCH --mem=64G
#SBATCH --time=12:00:00
#SBATCH --output=/scratch/sk4386/alu_audit/logs/09_round2_n10_%j.log
# 09: owner's option 1. Same AluS sample as 08 (round2/S/s2.fa); SubFam -n 10 -p 0.6 (SubFam10 pairing); peel defaults.
set -euo pipefail
cd /scratch/sk4386/alu_audit || exit 1
export PATH=/home/sk4386/.conda/envs/bioinfo/bin:$PATH
export TMPDIR=/scratch/sk4386/alu_audit/tmp
T=${SLURM_CPUS_PER_TASK:-32}
R=round2/S
rm -rf $R/n10 $R/peel_n10; mkdir -p $R/peel_n10
/usr/bin/time -v bash tools/SubFam/SubFam.sh -n 10 -p 0.6 -t $T -o $R/n10 -x alu -g $R/s2.labels.tsv $R/s2.fa 2> $R/n10.time.txt
grep -c '^>' $R/n10/alu.cons.fasta
grep -E "Elapsed|Maximum resident" $R/n10.time.txt
for d in n50 n10; do awk -F'\t' -v d=$d 'NR>1{n++; s+=$5; if($5>=0.9)a++; else if($5>=0.7)b++; else c++} END{printf "%s: chunks %d mean purity %.3f; >=0.9: %d, 0.7-0.9: %d, <0.7: %d\n",d,n,s/n,a,b,c}' $R/$d/alu.composition.tsv; done
echo "--- chunks whose majority name is not AluSx, with purity >= 0.7 (n10)"
awk -F'\t' 'NR>1 && $5>=0.7{m[$4]++} END{for(k in m) print m[k], k}' $R/n10/alu.composition.tsv | sort -k1,1nr | head -20
echo "--- same for n50"
awk -F'\t' 'NR>1 && $5>=0.7{m[$4]++} END{for(k in m) print m[k], k}' $R/n50/alu.composition.tsv | sort -k1,1nr | head -20
python3 tools/SINE-discriminator/peel_features.py $R/n10/alu.cons.fasta $R/peel_n10 2>&1 | tee $R/peel_n10/peel.stdout.txt | tail -80
echo N10_DONE $(date -Iseconds)
