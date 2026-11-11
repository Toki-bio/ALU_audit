#!/bin/bash
#SBATCH --job-name=alu_ctrlY
#SBATCH --partition=core
#SBATCH --cpus-per-task=32
#SBATCH --mem=64G
#SBATCH --time=24:00:00
#SBATCH --output=/scratch/sk4386/alu_audit/logs/14_control_Y_%j.log
# 14: control. SINEderella step 2 (unchanged) on the firm AluY copies (round 2, cons_G2) with the Dfam 4.0 AluY bank.
set -euo pipefail
cd /scratch/sk4386/alu_audit || exit 1
export PATH=/home/sk4386/.conda/envs/bioinfo/bin:$PATH
export TMPDIR=/scratch/sk4386/alu_audit/tmp
T=${SLURM_CPUS_PER_TASK:-32}
W=round3/dfamY; rm -rf $W; mkdir -p $W/toy
ST2=tools/SINEderella/step2_asSINEment.sh
awk -F'\t' 'NR>1 && $5=="assigned" && $2=="cons_G2"{print $1}' round2/asg/out/assignment_full.tsv > round3/Y.ids
seqkit grep -n -f round3/Y.ids round2/asg/copies.fa -w 0 > round3/Y.fa
grep -c '^>' round3/Y.fa
awk '/^>/{p=($1 ~ /^>DFAM_AluY/)} p' tools/SubFam/benchmark/alu_hg38/results/dfam_alu.fa | sed '/^>/s/^>DFAM_\([^ ]*\).*/>\1/' > $W/bank.fa
grep -c '^>' $W/bank.fa; grep '^>' $W/bank.fa | tr '\n' ' '; echo
cp round2/asg/rm_name.tsv $W/truth.tsv
seqkit head -n 2000 round3/Y.fa -w 0 > $W/toy/Y.fa
bash $ST2 $W/bank.fa $W/toy/Y.fa $T $W/toy/out > $W/toy/step2.log 2>&1 || { tail -20 $W/toy/step2.log; echo TOY FAILED; exit 1; }
awk -F'\t' 'NR>1{n[$5]++} END{for(k in n) print n[k], k}' $W/toy/out/assignment_full.tsv
echo TOY_OK
bash $ST2 $W/bank.fa round3/Y.fa $T $W/out > $W/step2.log 2>&1 || { tail -30 $W/step2.log; echo STEP2 FAILED; exit 1; }
echo CONTROL_Y_DONE $(date -Iseconds)
