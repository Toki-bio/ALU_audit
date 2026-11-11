#!/bin/bash
#SBATCH --job-name=alu_r1
#SBATCH --partition=core
#SBATCH --cpus-per-task=8
#SBATCH --mem=24G
#SBATCH --time=04:00:00
#SBATCH --output=/scratch/sk4386/alu_audit/logs/03_seqs_round1_%j.log
# 03: sequences of full-length dimeric Alu rows, then peel round 1 input: seed-1 sample of 30,000 -> SubFam -n 50.
# Input: copyset/alu_rows.tsv, data/hs1.fa.gz. Output: copyset/alu_full.{bed,fa}, round1/
set -euo pipefail
cd /scratch/sk4386/alu_audit || exit 1
export PATH=/home/sk4386/.conda/envs/bioinfo/bin:$PATH
export TMPDIR=/scratch/sk4386/alu_audit/tmp; mkdir -p $TMPDIR round1
T=${SLURM_CPUS_PER_TASK:-8}
[ -s data/hs1.fa.fai ] || { zcat data/hs1.fa.gz > data/hs1.fa; samtools faidx data/hs1.fa; }
# full-length = one RepeatMasker row for its ID, >=0.9 of the consensus covered, 250-350 bp, a dimeric Alu name
awk -F'\t' 'NR==FNR{c[$1":"$5]++; next}
  c[$1":"$5]==1 && $4!~/^(FLAM|FRAM|FAM|CAS|ASR)/ && $4!="Alu" {cl=$12+$13; len=$3-$2
    if(($12-$11+1)/cl>=0.9 && len>=250 && len<=350) printf "%s\t%d\t%d\t%s:%d-%d(%s)|%s\t%s\t%s\n",$1,$2,$3,$1,$2,$3,$6,$4,$8,$6}' \
  copyset/alu_rows.tsv copyset/alu_rows.tsv > copyset/alu_full.bed
wc -l copyset/alu_full.bed
bedtools getfasta -fi data/hs1.fa -bed copyset/alu_full.bed -s -nameOnly | sed '/^>/s/([+-])$//' > copyset/alu_full.fa
grep -c '^>' copyset/alu_full.fa; head -2 copyset/alu_full.fa | cut -c1-120
# no N, upper/lower kept as in the genome (soft-masking is not information here) -> uppercase
seqkit seq -u -w 0 copyset/alu_full.fa | seqkit grep -s -v -p N > copyset/alu_full.clean.fa
seqkit stats -T copyset/alu_full.fa copyset/alu_full.clean.fa
# seed-1 sample of 30,000 ids (deterministic: awk srand(1), sort)
grep '^>' copyset/alu_full.clean.fa | sed 's/^>//' | awk 'BEGIN{srand(1)}{print rand()"\t"$0}' | sort -k1,1g | head -30000 | cut -f2 > round1/s1.ids
seqkit grep -n -f round1/s1.ids copyset/alu_full.clean.fa -w 0 > round1/s1.fa
awk -F'|' '/^>/{print substr($0,2)"\t"$2}' round1/s1.fa > round1/s1.labels.tsv
grep -c '^>' round1/s1.fa; cut -f2 round1/s1.labels.tsv | sort | uniq -c | sort -k1,1nr | head -50 > round1/s1.label_counts.txt
SF=/scratch/sk4386/alu_audit/tools/SubFam/SubFam.sh
# toy first: 1,000 copies end to end
seqkit head -n 1000 round1/s1.fa -w 0 > round1/toy.fa
bash $SF -n 50 -t $T -o round1/toy -x toy -g round1/s1.labels.tsv round1/toy.fa
ls -la round1/toy; [ "$(grep -c '^>' round1/toy/toy.cons.fasta)" = 20 ] || { echo "TOY FAILED"; exit 1; }
echo TOY_OK
/usr/bin/time -v bash $SF -n 50 -t $T -o round1/n50 -x alu -g round1/s1.labels.tsv round1/s1.fa 2> round1/n50.time.txt
ls -la round1/n50; grep -c '^>' round1/n50/alu.cons.fasta
grep -E "Elapsed|Maximum resident" round1/n50.time.txt
find /scratch/sk4386/alu_audit -type f | wc -l
echo ROUND1_SUBFAM_DONE $(date -Iseconds)
