#!/bin/bash
#SBATCH --job-name=alu_r2
#SBATCH --partition=core
#SBATCH --cpus-per-task=32
#SBATCH --mem=64G
#SBATCH --time=10:00:00
#SBATCH --output=/scratch/sk4386/alu_audit/logs/07_round2_%j.log
# 07: round 2. Needs round1/ (peel result), copyset/alu_full.clean.fa. See brief of 2026-11-11.
set -euo pipefail
cd /scratch/sk4386/alu_audit || exit 1
export PATH=/home/sk4386/.conda/envs/bioinfo/bin:$PATH
export TMPDIR=/scratch/sk4386/alu_audit/tmp; rm -rf round2/full round2/toy; mkdir -p $TMPDIR round2/toy round2/full
T=${SLURM_CPUS_PER_TASK:-32}
SC=scripts
python3 $SC/06_consensus.py round1 round2
: > round2/cons3.fa
for g in G1 G2 S; do
  seqkit grep -n -f round2/pick_$g.ids copyset/alu_full.clean.fa -w 0 > round2/pick_$g.fa
  mafft --retree 2 --maxiterate 0 --quiet --thread $T round2/pick_$g.fa > round2/pick_$g.aln.fa
  python3 $SC/06_cons_from_aln.py cons_$g round2/pick_$g.aln.fa >> round2/cons3.fa
done
seqkit fx2tab -n -l round2/cons3.fa
assign() {  # $1 = library fasta, $2 = outprefix. Library is split into blocks of 10,000 (as SINEderella step 2 does with 20,000):
  # one ssearch36 run reported only ~21,000 hits per query on the 824,790-copy library (first attempt, 62,957 of 824,790).
  rm -rf $2.blocks; mkdir -p $2.blocks
  seqkit split2 -s 10000 -O $2.blocks -j 8 $1 > /dev/null
  ls $2.blocks/*.fa* > $2.blocks.list
  xargs -a $2.blocks.list -P $T -I{} sh -c 'ssearch36 -g -3 -n -Q -T 1 -z 1 -E 100000000 -b 20000 -d 20000 -m 8 round2/cons3.fa {} > {}.m8'
  cat $2.blocks/*.m8 > $2.m8
  rm -rf $2.blocks $2.blocks.list
  awk -F'	' -v OFS='	' '{ if(!($2 in b1)||$12>b1[$2]){ if($2 in b1) b2[$2]=b1[$2]; b1[$2]=$12; g[$2]=$1 } else if(!($2 in b2)||$12>b2[$2]) b2[$2]=$12 }
    END{ for(k in b1) print k, g[k], b1[k], (k in b2)?b2[k]:0 }' $2.m8 > $2.best.tsv
}
# toy: 2,000 copies
seqkit head -n 2000 copyset/alu_full.clean.fa -w 0 > round2/toy/in.fa
assign round2/toy/in.fa round2/toy/toy
echo "toy copies assigned: $(wc -l < round2/toy/toy.best.tsv) of 2000"
cut -f2 round2/toy/toy.best.tsv | sort | uniq -c
[ "$(wc -l < round2/toy/toy.best.tsv)" -ge 1990 ] || { echo "TOY FAILED"; exit 1; }
echo TOY_OK
assign copyset/alu_full.clean.fa round2/full/all
NA=$(wc -l < round2/full/all.best.tsv); NT=$(grep -c '^>' copyset/alu_full.clean.fa); echo "assigned: $NA of $NT"; [ "$NA" -ge $((NT*99/100)) ] || { echo "ASSIGNMENT INCOMPLETE - STOP"; exit 1; }
cut -f2 round2/full/all.best.tsv | sort | uniq -c
# control: the 30,000 round-1 sample copies have a known group via their chunk
awk -F'\t' 'NR==FNR{m[$1]=$2; next} ($1 in m){ t=(m[$1]=="S")?"cons_S":("cons_" m[$1]); n++; if($2==t) ok++; k[m[$1]" -> "$2]++} END{printf "CONTROL agreement with round-1 group: %d of %d = %.3f\n", ok, n, ok/n; for(x in k) print "  ", x, k[x]; if(n<20000 || ok/n<0.90) print "FAILED" > "round2/full/CONTROL_FAILED"}' round2/members.tsv round2/full/all.best.tsv
[ ! -e round2/full/CONTROL_FAILED ] || { echo "CONTROL FAILED - STOP"; exit 1; }
# the S-only remainder and its sample (seed 2); sort from a file, never sort | head
awk -F'\t' '$2=="cons_S"{print $1}' round2/full/all.best.tsv > round2/full/S.ids
awk 'BEGIN{srand(2)}{print rand()"\t"$0}' round2/full/S.ids > round2/full/S.shuf.tmp
sort -k1,1g round2/full/S.shuf.tmp > round2/full/S.sorted.tmp
head -n 30000 round2/full/S.sorted.tmp | cut -f2 > round2/full/s2.ids
rm -f round2/full/S.shuf.tmp round2/full/S.sorted.tmp
seqkit grep -n -f round2/full/s2.ids copyset/alu_full.clean.fa -w 0 > round2/full/s2.fa
awk -F'|' '/^>/{print substr($0,2)"\t"$2}' round2/full/s2.fa > round2/full/s2.labels.tsv
grep -c '^>' round2/full/s2.fa
cut -f2 round2/full/s2.labels.tsv | sort | uniq -c | sort -k1,1nr > round2/full/s2.label_counts.txt
head -n 30 round2/full/s2.label_counts.txt
SF=tools/SubFam/SubFam.sh
/usr/bin/time -v bash $SF -n 50 -t $T -o round2/full/n50 -x alu -g round2/full/s2.labels.tsv round2/full/s2.fa 2> round2/full/n50.time.txt
grep -c '^>' round2/full/n50/alu.cons.fasta
grep -E "Elapsed|Maximum resident" round2/full/n50.time.txt
awk -F'\t' 'NR>1{n++; s+=$5; if($5>=0.9)a++; else if($5>=0.7)b++; else c++} END{printf "chunks %d mean purity %.3f; >=0.9: %d, 0.7-0.9: %d, <0.7: %d\n",n,s/n,a,b,c}' round2/full/n50/alu.composition.tsv
mkdir -p round2/full/peel
python3 tools/SINE-discriminator/peel_features.py round2/full/n50/alu.cons.fasta round2/full/peel 2>&1 | tee round2/full/peel/peel.stdout.txt | tail -60
gzip -f round2/full/all.m8 round2/toy/toy.m8
find /scratch/sk4386/alu_audit -type f | wc -l
echo ROUND2_DONE $(date -Iseconds)
