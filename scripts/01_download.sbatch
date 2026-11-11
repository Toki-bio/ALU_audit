#!/bin/bash
#SBATCH --job-name=alu_dl
#SBATCH --partition=core
#SBATCH --cpus-per-task=2
#SBATCH --mem=4G
#SBATCH --time=06:00:00
#SBATCH --output=/scratch/sk4386/alu_audit/logs/01_download_%j.log
set -euo pipefail
cd /scratch/sk4386/alu_audit/data || exit 1
pwd
RM=https://www.repeatmasker.org/genomes/hs1/rmsk4.2.2_dfam3.9_rb20181026_rmb
get() { curl -sS -L -A "Mozilla/5.0" --retry 20 --retry-delay 30 --retry-all-errors -o "$2" "$1"; ls -l "$2"; }
get https://hgdownload.soe.ucsc.edu/goldenPath/hs1/bigZips/hs1.fa.gz hs1.fa.gz
echo "a493d5402cc86ecc3f54f6346d980036  hs1.fa.gz" | md5sum -c -
get $RM/hs1.fa.out.gz hs1.fa.out.gz
get $RM/hs1.fa.align.gz hs1.fa.align.gz
[ "$(stat -c %s hs1.fa.out.gz)" = 187138419 ] || { echo "SIZE MISMATCH out"; exit 1; }
[ "$(stat -c %s hs1.fa.align.gz)" = 2781413400 ] || { echo "SIZE MISMATCH align"; exit 1; }
for f in hs1.fa.gz hs1.fa.out.gz hs1.fa.align.gz; do gzip -t $f; echo "GZIP_OK $f"; done
md5sum hs1.fa.gz hs1.fa.out.gz hs1.fa.align.gz > md5.txt
cat md5.txt
echo "DOWNLOAD_DONE $(date -Iseconds)"
