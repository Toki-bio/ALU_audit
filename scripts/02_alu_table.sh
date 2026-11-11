#!/bin/bash
# 02: Alu rows of the RepeatMasker 4.2.2/Dfam 3.9 hs1 .out file -> one TSV row per RepeatMasker row (fragment).
# Input: data/hs1.fa.out.gz   Output: copyset/alu_rows.tsv, copyset/boundary_rows.tsv, copyset/summary_*.tsv
set -euo pipefail
cd /scratch/sk4386/alu_audit || exit 1
mkdir -p copyset
zcat data/hs1.fa.out.gz | awk -v OFS='\t' '
NR<=3 {next}
{ cls=$11; nm=$10
  if (cls=="SINE/Alu") out="copyset/alu_rows.tsv";
  else if (cls=="srpRNA" || cls=="scRNA" || nm ~ /^(Alu|FLAM|FRAM|FAM|BC200|7SL)/) out="copyset/boundary_rows.tsv";
  else next
  strand=($9=="C")?"-":"+"
  if ($9=="C") { rl=$12; re=$13; rs=$14 } else { rs=$12; re=$13; rl=$14 }
  gsub(/[()]/,"",rl)
  star=(NF==16)?"*":"."
  # chr start0 end name rmID strand sw div del ins repStart repEnd repLeft class star
  print $5,$6-1,$7,nm,$15,strand,$1,$2,$3,$4,rs,re,rl,cls,star > out
}'
wc -l copyset/alu_rows.tsv copyset/boundary_rows.tsv
# per name: rows, distinct (chr,ID) elements, bp, median row length, mean div
awk -F'\t' -v OFS='\t' '{n=$4; r[n]++; bp[n]+=$3-$2; d[n]+=$8; k=$1":"$5; if(!((n,k) in seen)){seen[n,k]=1; e[n]++}}
 END{print "name","rows","elements_by_ID","bp","mean_row_len","mean_div"; for(n in r) printf "%s\t%d\t%d\t%d\t%.1f\t%.2f\n", n,r[n],e[n],bp[n],bp[n]/r[n],d[n]/r[n]}' copyset/alu_rows.tsv | (read h; echo "$h"; sort -t$'\t' -k2,2nr) > copyset/summary_by_name.tsv
awk -F'\t' -v OFS='\t' '{r[$4"\t"$14]++; bp[$4"\t"$14]+=$3-$2} END{for(n in r) print n,r[n],bp[n]}' copyset/boundary_rows.tsv | sort -t$'\t' -k3,3nr > copyset/summary_boundary.tsv
# row length histogram, 10-bp bins
awk -F'\t' -v OFS='\t' '{b=int(($3-$2)/10)*10; h[b]++} END{for(b in h) print b,h[b]}' copyset/alu_rows.tsv | sort -k1,1n > copyset/summary_rowlen_hist.tsv
# fragments per element (chr,ID)
awk -F'\t' '{c[$1":"$5]++} END{for(k in c) h[c[k]]++; for(n in h) print n"\t"h[n]}' copyset/alu_rows.tsv | sort -k1,1n > copyset/summary_fragments_per_ID.tsv
# is the ID unique genome-wide or per chromosome?
awk -F'\t' '{a[$5]=a[$5]?a[$5]:$1; if(a[$5]!=$1) x++} END{print "rows whose rmID was first seen on another chromosome:", x+0}' copyset/alu_rows.tsv
awk -F'\t' '{bp+=$3-$2; if($15=="*")s++} END{printf "total Alu rows %d, bp %d, starred %d\n", NR,bp,s}' copyset/alu_rows.tsv
awk -F'\t' '{c[$1]++; bp[$1]+=$3-$2} END{for(k in c) print k"\t"c[k]"\t"bp[k]}' copyset/alu_rows.tsv | sort -V > copyset/summary_by_chr.tsv
echo TABLE_DONE
