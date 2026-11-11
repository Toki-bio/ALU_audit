#!/usr/bin/env python3
"""plurality consensus of an aligned fasta: column dropped if >50% gaps, else most frequent base (ties -> first of ACGT)."""
import sys, collections
name, path = sys.argv[1], sys.argv[2]
seqs = []; cur = []
for l in open(path):
    if l.startswith(">"):
        if cur: seqs.append("".join(cur).upper()); cur = []
    else: cur.append(l.strip())
if cur: seqs.append("".join(cur).upper())
n = len(seqs); L = len(seqs[0]); out = []
for k in range(L):
    c = collections.Counter(s[k] for s in seqs)
    if c.get("-", 0) > n / 2: continue
    c.pop("-", None); c.pop("N", None)
    if not c: continue
    top = max(c.values()); out.append(next(b for b in "ACGT" if c.get(b, 0) == top))
print(">%s\n%s" % (name, "".join(out)))
