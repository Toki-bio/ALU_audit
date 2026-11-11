#!/bin/bash
#SBATCH --job-name=alu_coseg
#SBATCH --partition=core
#SBATCH --cpus-per-task=4
#SBATCH --mem=32G
#SBATCH --time=24:00:00
#SBATCH --output=/scratch/sk4386/alu_audit/logs/11_coseg_S_%j.log
# 11: COSEG on the round-2 AluS sample (round2/S/s2.fa), settings of Price 2004 / the COSEG README Alu example.
set -euo pipefail
cd /scratch/sk4386/alu_audit || exit 1
export PATH=/home/sk4386/.conda/envs/bioinfo/bin:$PATH
export TMPDIR=/scratch/sk4386/alu_audit/tmp
C=/scratch/sk4386/alu_audit/tools/coseg
O=round2/S/coseg; rm -rf $O; mkdir -p $O/toy
# control: COSEG's own Alu example (Price's data)
cp $C/ALU.cons $C/ALU.seqs $C/ALU.ins $O/toy/
( cd $O/toy && /usr/bin/time -v perl $C/runcoseg.pl -k -d -m 50 -c ALU.cons -s ALU.seqs -i ALU.ins > run.out 2> time.txt ) || { tail -20 $O/toy/run.out $O/toy/time.txt; echo "TOY FAILED"; exit 1; }
cat $O/toy/ALU.seqs.subfamilies
grep -E "Elapsed" $O/toy/time.txt
echo TOY_OK
# convert the AluS sample: global alignment to the same AluSx consensus
python3 tools/SubFam/benchmark/alu_konkel/to_coseg.py $C/ALU.cons round2/S/s2.fa $O/s2
wc -l $O/s2.seqs $O/s2.ins $O/s2.names
cp $C/ALU.cons $O/s2.cons
( cd $O && /usr/bin/time -v perl $C/runcoseg.pl -k -d -m 50 -c s2.cons -s s2.seqs -i s2.ins > run.out 2> time.txt ) || { tail -30 $O/run.out $O/time.txt; echo "COSEG FAILED"; exit 1; }
ls -la $O
grep -E "Elapsed|Maximum resident" $O/time.txt
cat $O/s2.seqs.subfamilies
tail -15 $O/s2.seqs.log
python3 scripts/12_coseg_vs_rm.py $O/s2 round2/S/s2.labels.tsv | tee $O/coseg_vs_rm.txt
echo COSEG_DONE $(date -Iseconds)
