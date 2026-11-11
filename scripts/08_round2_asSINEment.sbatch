#!/bin/bash
#SBATCH --job-name=alu_r2a
#SBATCH --partition=core
#SBATCH --cpus-per-task=32
#SBATCH --mem=64G
#SBATCH --time=24:00:00
#SBATCH --output=/scratch/sk4386/alu_audit/logs/08_round2_asSINEment_%j.log
# 08: assign all full-length copies to the three round-1 consensuses (round2/cons3.fa) with SINEderella step 2, unchanged.
# Then the control on the round-1 sample, then the S-only sample (seed 2), SubFam -n 50, peel defaults.
set -euo pipefail
cd /scratch/sk4386/alu_audit || exit 1
export PATH=/home/sk4386/.conda/envs/bioinfo/bin:$PATH
export TMPDIR=/scratch/sk4386/alu_audit/tmp
T=${SLURM_CPUS_PER_TASK:-32}
A=round2/asg; rm -rf $A; mkdir -p $A/toy
ST2=tools/SINEderella/step2_asSINEment.sh
# plain ids (chr:start-end(strand)), as SINEderella's own extracted.fasta; the RepeatMasker name stays in a side table
sed '/^>/s/|.*$//' copyset/alu_full.clean.fa > $A/copies.fa
awk -F'|' '/^>/{print substr($1,2)"\t"$2}' copyset/alu_full.clean.fa > $A/rm_name.tsv
awk -F'\t' '{split($1,a,"|"); print a[1]"\t"$2}' round2/members.tsv > $A/members.tsv
seqkit head -n 2000 $A/copies.fa -w 0 > $A/toy/copies.fa
bash $ST2 round2/cons3.fa $A/toy/copies.fa $T $A/toy/out > $A/toy/step2.log 2>&1 || { tail -20 $A/toy/step2.log; echo "TOY FAILED"; exit 1; }
ls $A/toy/out; head -3 $A/toy/out/assignment_full.tsv
awk -F'\t' 'NR>1{n[$2" "$5]++} END{for(k in n) print n[k], k}' $A/toy/out/assignment_full.tsv | sort -k1,1nr
echo TOY_OK
bash $ST2 round2/cons3.fa $A/copies.fa $T $A/out > $A/step2.log 2>&1 || { tail -30 $A/step2.log; echo "STEP2 FAILED"; exit 1; }
cat $A/out/summary.txt 2>/dev/null | head -30
cat $A/out/assignment_stats.tsv
F=$A/out/assignment_full.tsv
head -2 $F
echo "rows: $(($(wc -l < $F)-1)) of $(grep -c '^>' $A/copies.fa)"
awk -F'\t' 'NR>1{n[$2" "$5]++} END{for(k in n) print n[k], k}' $F | sort -k1,1nr
# control: round-1 sample copies, firm assignments only
awk -F'\t' 'NR==FNR{m[$1]=$2; next} FNR>1 && ($1 in m){ n++; if($5!="assigned"){u++; next} t="cons_" m[$1]; f++; if($2==t) ok++; k[m[$1]" -> "$2]++ }
  END{ printf "CONTROL: %d sample copies; %d firm, %d not firm; firm agreement %d of %d = %.3f\n", n, f, u, ok, f, ok/f; for(x in k) print "  ", x, k[x];
       if (f < 15000 || ok/f < 0.90) print "FAILED" > "'$A'/CONTROL_FAILED" }' $A/members.tsv $F
[ ! -e $A/CONTROL_FAILED ] || { echo "CONTROL FAILED - STOP"; exit 1; }
echo CONTROL_OK
# S-only remainder (firm cons_S), sample of 30,000, seed 2 - files, never sort | head
R=round2/S; rm -rf $R; mkdir -p $R
awk -F'\t' 'NR>1 && $5=="assigned" && $2=="cons_S"{print $1}' $F > $R/S.ids
wc -l < $R/S.ids
awk 'BEGIN{srand(2)}{print rand()"\t"$0}' $R/S.ids > $R/shuf.tmp
sort -k1,1g $R/shuf.tmp > $R/sorted.tmp
head -n 30000 $R/sorted.tmp | cut -f2 > $R/s2.ids; rm -f $R/shuf.tmp $R/sorted.tmp
seqkit grep -n -f $R/s2.ids $A/copies.fa -w 0 > $R/s2.fa
awk -F'\t' 'NR==FNR{s[$1]=1; next} ($1 in s)' $R/s2.ids $A/rm_name.tsv > $R/s2.labels.tsv
grep -c '^>' $R/s2.fa
cut -f2 $R/s2.labels.tsv | sort | uniq -c | sort -k1,1nr > $R/s2.label_counts.txt; head -n 25 $R/s2.label_counts.txt
bash tools/SubFam/SubFam.sh -n 50 -t $T -o $R/n50 -x alu -g $R/s2.labels.tsv $R/s2.fa
grep -c '^>' $R/n50/alu.cons.fasta
awk -F'\t' 'NR>1{n++; s+=$5; if($5>=0.9)a++; else if($5>=0.7)b++; else c++} END{printf "chunks %d mean purity %.3f; >=0.9: %d, 0.7-0.9: %d, <0.7: %d\n",n,s/n,a,b,c}' $R/n50/alu.composition.tsv
mkdir -p $R/peel
python3 tools/SINE-discriminator/peel_features.py $R/n50/alu.cons.fasta $R/peel 2>&1 | tee $R/peel/peel.stdout.txt | tail -60
find /scratch/sk4386/alu_audit -type f | wc -l
echo ROUND2_DONE $(date -Iseconds)
