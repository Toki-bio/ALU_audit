#!/bin/bash
#SBATCH --job-name=alu_peel1
#SBATCH --partition=core
#SBATCH --cpus-per-task=32
#SBATCH --mem=32G
#SBATCH --time=04:00:00
#SBATCH --output=/scratch/sk4386/alu_audit/logs/04_peel_round1_%j.log
# 04: peel round 1. Input: round1/n50/alu.cons.fasta (600 chunk consensuses). Output: round1/peel/
# Parameters are the peel's defaults (calibrated on Timema); none are changed after seeing Alu results.
set -euo pipefail
cd /scratch/sk4386/alu_audit || exit 1
export PATH=/home/sk4386/.conda/envs/bioinfo/bin:$PATH
export TMPDIR=/scratch/sk4386/alu_audit/tmp
P=tools/SINE-discriminator/peel_features.py
mkdir -p round1/peel_toy round1/peel
# chunk purity against RepeatMasker names (control on the input: how mixed are the chunks?)
awk -F'\t' 'NR>1{n++; s+=$5; if($5>=0.9)a++; else if($5>=0.7)b++; else c++} END{printf "chunks %d mean purity %.3f; >=0.9: %d, 0.7-0.9: %d, <0.7: %d\n",n,s/n,a,b,c}' round1/n50/alu.composition.tsv
# toy: first 120 chunk consensuses
seqkit head -n 120 round1/n50/alu.cons.fasta -w 0 > round1/peel_toy/in.fa
python3 $P round1/peel_toy/in.fa round1/peel_toy 2>&1 | tail -25
ls -la round1/peel_toy; [ -s round1/peel_toy/peel_features.json ] || { echo "TOY FAILED"; exit 1; }
echo TOY_OK
python3 $P round1/n50/alu.cons.fasta round1/peel 2>&1 | tee round1/peel/peel.stdout.txt | tail -80
ls -la round1/peel
echo PEEL_DONE $(date -Iseconds)
