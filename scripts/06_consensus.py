#!/usr/bin/env python3
"""06: member-copy consensus per peeled group. usage: 06_consensus.py ROUND1_DIR OUTDIR
Reads round1/peel/peel_features.json, round1/n50/alu.chunks.tsv; writes OUTDIR/members.tsv (copy<TAB>group),
OUTDIR/pick_{G1,G2,S}.ids (500 random member copies each, seed 1)."""
import json, random, sys, os, collections
r1, out = sys.argv[1], sys.argv[2]
j = json.load(open(os.path.join(r1, "peel/peel_features.json")))
grp = {}
for i, g in enumerate(j["peeled"]): 
    for c in g["members"]: grp[c] = "G%d" % (i + 1)
for c in j["residue"]: grp[c] = "S"
mem = collections.defaultdict(list)
with open(os.path.join(r1, "n50/alu.chunks.tsv")) as f:
    for l in f:
        p = l.rstrip("\n").split("\t")
        if p[1] in grp: mem[grp[p[1]]].append(p[0])
rnd = random.Random(1)
with open(os.path.join(out, "members.tsv"), "w") as m:
    for g, ids in sorted(mem.items()):
        for i in ids: m.write("%s\t%s\n" % (i, g))
for g, ids in sorted(mem.items()):
    pick = rnd.sample(ids, min(500, len(ids)))
    open(os.path.join(out, "pick_%s.ids" % g), "w").write("\n".join(pick) + "\n")
    print(g, len(ids), "members;", len(pick), "picked")
