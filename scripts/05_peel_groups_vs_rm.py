import json,csv,collections
j=json.load(open("peel/peel_features.json"))
rows=list(csv.reader(open("n50/alu.composition.tsv"),delimiter="\t"))
hdr=rows[0]; names=hdr[5:]
comp={r[0]:[int(x) for x in r[5:]] for r in rows[1:]}
groups={"G1(round1)":j["peeled"][0]["members"],"G2(round2)":j["peeled"][1]["members"],"residue":j["residue"]}
def rng(ids):
    n=sorted(int(i.split("_")[1]) for i in ids); out=[]; s=p=n[0]
    for x in n[1:]:
        if x==p+1: p=x; continue
        out.append("%d-%d"%(s,p) if s!=p else str(s)); s=p=x
    out.append("%d-%d"%(s,p) if s!=p else str(s)); return ",".join(out)
for g,ids in groups.items():
    tot=collections.Counter()
    for i in ids:
        for n,c in zip(names,comp[i]): tot[n]+=c
    s=sum(tot.values())
    print("\n%s: %d chunks, %d copies; chunk ids %s"%(g,len(ids),s,rng(ids)))
    print("  top names:", "; ".join("%s %d (%.0f%%)"%(n,c,100*c/s) for n,c in tot.most_common(8)))
    # AluY-family share
    y=sum(c for n,c in tot.items() if n.startswith("AluY")); sx=sum(c for n,c in tot.items() if n.startswith(("AluS",)))
    jj=sum(c for n,c in tot.items() if n.startswith("AluJ"))
    print("  family share: AluJ %.0f%%  AluS %.0f%%  AluY %.0f%%"%(100*jj/s,100*sx/s,100*y/s))
