#!/bin/bash
#SBATCH --partition=core
#SBATCH --cpus-per-task=32
#SBATCH --mem=64G
#SBATCH --time=24:00:00
# 13: SINEderella step 2 (unchanged) on the 527,234 firm AluS copies with one bank. usage: sbatch ... 13_bank_vs_S.sbatch coseg|dfam
set -euo pipefail
cd /scratch/sk4386/alu_audit || exit 1
export PATH=/home/sk4386/.conda/envs/bioinfo/bin:$PATH
export TMPDIR=/scratch/sk4386/alu_audit/tmp
T=${SLURM_CPUS_PER_TASK:-32}
B=$1; W=round3/$B; rm -rf $W; mkdir -p $W/toy
ST2=tools/SINEderella/step2_asSINEment.sh
[ -s round3/S.fa ] || seqkit grep -n -f round2/S/S.ids round2/asg/copies.fa -w 0 > round3/S.fa
grep -c '^>' round3/S.fa
if [ "$B" = coseg ]; then
  # members per COSEG subfamily -> up to 500 random copies (seed 1) -> MAFFT -> plurality consensus
  paste round2/S/coseg/s2.names <(awk '{print $2}' round2/S/coseg/s2.seqs.assign) > $W/members.tsv
  : > $W/bank.fa
  for sf in $(cut -f2 $W/members.tsv | sort -n | uniq); do
    awk -F'\t' -v s=$sf '$2==s{print $1}' $W/members.tsv | awk 'BEGIN{srand(1)}{print rand()"\t"$0}' > $W/m.tmp
    sort -k1,1g $W/m.tmp > $W/m2.tmp; head -n 500 $W/m2.tmp | cut -f2 > $W/pick.ids; rm -f $W/m.tmp $W/m2.tmp
    seqkit grep -n -f $W/pick.ids round2/asg/copies.fa -w 0 > $W/pick.fa
    mafft --retree 2 --maxiterate 0 --quiet --thread $T $W/pick.fa > $W/pick.aln.fa
    python3 scripts/06_cons_from_aln.py coseg_sf$sf $W/pick.aln.fa >> $W/bank.fa
  done
  rm -f $W/pick.*
  awk -F'\t' '{print $1"\tcoseg_sf"$2}' $W/members.tsv > $W/truth.tsv
else
  awk '/^>/{p=($1 ~ /^>DFAM_AluS/)} p' tools/SubFam/benchmark/alu_hg38/results/dfam_alu.fa | sed '/^>/s/^>DFAM_\([^ ]*\).*/>\1/' > $W/bank.fa
  awk -F'\t' '{print $1"\t"$2}' round2/asg/rm_name.tsv > $W/truth.tsv
fi
seqkit fx2tab -n -l $W/bank.fa | head -40; grep -c '^>' $W/bank.fa
seqkit head -n 2000 round3/S.fa -w 0 > $W/toy/S.fa
bash $ST2 $W/bank.fa $W/toy/S.fa $T $W/toy/out > $W/toy/step2.log 2>&1 || { tail -20 $W/toy/step2.log; echo TOY FAILED; exit 1; }
awk -F'\t' 'NR>1{n[$5]++} END{for(k in n) print n[k], k}' $W/toy/out/assignment_full.tsv
echo TOY_OK
bash $ST2 $W/bank.fa round3/S.fa $T $W/out > $W/step2.log 2>&1 || { tail -30 $W/step2.log; echo STEP2 FAILED; exit 1; }
F=$W/out/assignment_full.tsv
echo "rows $(($(wc -l < $F)-1))"
# per consensus: firm, not unanimous, low, leak among firm (runner_ratio >= 0.90)
awk -F'\t' -v OFS='\t' 'NR>1{ c=$2; s=$5; n[c]++; if(s=="assigned"){f[c]++; if(match($7,/runner_ratio=[0-9.]+/)){r=substr($7,RSTART+13,RLENGTH-13)+0; if(r>=0.90) l[c]++}} else if(s=="no_unanimous") u[c]++; else lo[c]++ }
  END{ print "consensus","firm","not_unanimous","low_score","leak_n","leak_pct_of_firm"; for(c in n) printf "%s\t%d\t%d\t%d\t%d\t%.2f\n", c, f[c], u[c], lo[c], l[c], (f[c]?100*l[c]/f[c]:0) }' $F | (read h; echo "$h"; sort -t$'\t' -k2,2nr) | tee $W/per_consensus.tsv
awk -F'\t' 'NR>1{t++; if($5=="assigned"){f++; if(match($7,/runner_ratio=[0-9.]+/) && substr($7,RSTART+13,RLENGTH-13)+0>=0.90) l++}} END{printf "TOTAL firm %d of %d (%.1f%%); leak %d (%.2f%% of firm)\n", f,t,100*f/t,l,100*l/f}' $F | tee $W/total.txt
# self-check: copies with a known label go back to it?
awk -F'\t' 'NR==FNR{t[$1]=$2; next} FNR>1 && ($1 in t) && $5=="assigned"{n++; if($2==t[$1]) ok++} END{printf "SELF-CHECK firm copies with a label: %d, back to own label: %d (%.3f)\n", n, ok, ok/n}' $W/truth.tsv $F | tee -a $W/total.txt
echo BANK_DONE $B $(date -Iseconds)
