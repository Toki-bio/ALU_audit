#!/bin/bash
# 15: summary of one step-2 run: per consensus (firm, not unanimous, low, leak), self-check against a label table,
# and firm rate by RepeatMasker divergence bin. usage: 15_firm_summary.sh RUNDIR   (RUNDIR/out/assignment_full.tsv, RUNDIR/truth.tsv)
set -euo pipefail
cd /scratch/sk4386/alu_audit || exit 1
W=$1; F=$W/out/assignment_full.tsv
awk -F'\t' -v OFS='\t' 'NR>1{ c=$2; s=$5; n[c]++; if(s=="assigned"){f[c]++; if(match($7,/runner_ratio=[0-9.]+/)){r=substr($7,RSTART+13,RLENGTH-13)+0; if(r>=0.90) l[c]++}} else if(s=="no_unanimous") u[c]++; else lo[c]++ }
  END{ print "consensus","firm","not_unanimous","low_score","leak_n","leak_pct_of_firm"; for(c in n) printf "%s\t%d\t%d\t%d\t%d\t%.2f\n", c, f[c]+0, u[c]+0, lo[c]+0, l[c]+0, (f[c]?100*l[c]/f[c]:0) }' $F | (read h; echo "$h"; sort -t$'\t' -k2,2nr) > $W/per_consensus.tsv
awk -F'\t' 'NR>1{t++; if($5=="assigned"){f++; if(match($7,/runner_ratio=[0-9.]+/) && substr($7,RSTART+13,RLENGTH-13)+0>=0.90) l++}} END{printf "TOTAL firm %d of %d (%.1f%%); leak %d (%.2f%% of firm)\n", f,t,100*f/t,l,(f?100*l/f:0)}' $F > $W/total.txt
# self-check per label: of the copies carrying a label, how many are firm, and firm to their own label
awk -F'\t' -v OFS='\t' 'NR==FNR{t[$1]=$2; next} FNR>1 && ($1 in t){ L=t[$1]; n[L]++; if($5=="assigned"){f[L]++; if($2==L) ok[L]++} }
  END{ print "label","copies","firm","firm_pct","firm_to_own_label","own_pct_of_firm"; for(L in n) printf "%s\t%d\t%d\t%.1f\t%d\t%.1f\n", L, n[L], f[L]+0, 100*f[L]/n[L], ok[L]+0, (f[L]?100*ok[L]/f[L]:0) }' $W/truth.tsv $F | (read h; echo "$h"; sort -t$'\t' -k2,2nr) > $W/by_label.tsv
# divergence (RepeatMasker % div, column 5 of copyset/alu_full.bed; id = name field before "|")
awk -F'\t' 'NR==FNR{split($4,a,"|"); d[a[1]]=$5; next} FNR>1 && ($1 in d){ b=int(d[$1]/2)*2; n[b]++; if($5=="assigned") f[b]++ }
  END{ for(b in n) printf "%d-%d%%\t%d\t%d\t%.1f\n", b, b+2, n[b], f[b]+0, 100*f[b]/n[b] }' copyset/alu_full.bed $F | sort -k1,1n | (echo -e "div_bin\tcopies\tfirm\tfirm_pct"; cat) > $W/firm_by_div.tsv
cat $W/total.txt; echo; head -25 $W/per_consensus.tsv; echo; head -25 $W/by_label.tsv; echo; cat $W/firm_by_div.tsv
