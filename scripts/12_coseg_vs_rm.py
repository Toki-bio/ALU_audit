#!/usr/bin/env python3
"""12: COSEG partition vs RepeatMasker names on the same copies.
usage: 12_coseg_vs_rm.py PREFIX LABELS.tsv   (PREFIX.names = copy ids in .seqs order; PREFIX.seqs.assign = 'index subfamily')"""
import sys, collections, math
pre, lab = sys.argv[1], sys.argv[2]
names = [l.strip() for l in open(pre + ".names")]
rm = dict(l.rstrip("\n").split("\t")[:2] for l in open(lab))
asg = {}
for l in open(pre + ".seqs.assign"):
    p = l.split()
    if len(p) >= 2: asg[int(p[0])] = p[1]
pairs = [(asg[i], rm[n]) for i, n in enumerate(names) if i in asg and n in rm]
N = len(pairs)
print("copies compared: %d (names %d, assigned %d)" % (N, len(names), len(asg)))
by_c = collections.defaultdict(collections.Counter); by_r = collections.defaultdict(collections.Counter)
for c, r in pairs: by_c[c][r] += 1; by_r[r][c] += 1
print("\nCOSEG subfamily: size, top RepeatMasker names")
for c, cnt in sorted(by_c.items(), key=lambda x: -sum(x[1].values())):
    n = sum(cnt.values())
    print("  %4s %6d  %s" % (c, n, "; ".join("%s %d (%.0f%%)" % (r, k, 100 * k / n) for r, k in cnt.most_common(5))))
print("\nRepeatMasker name: size, where its copies go (top COSEG subfamilies)")
for r, cnt in sorted(by_r.items(), key=lambda x: -sum(x[1].values()))[:15]:
    n = sum(cnt.values())
    print("  %-8s %6d  %s" % (r, n, "; ".join("sf%s %d (%.0f%%)" % (c, k, 100 * k / n) for c, k in cnt.most_common(4))))
def H(counter):
    t = sum(counter.values()); return -sum(v / t * math.log(v / t) for v in counter.values() if v)
Hc = H(collections.Counter(c for c, _ in pairs)); Hr = H(collections.Counter(r for _, r in pairs))
Hr_c = sum(sum(cnt.values()) / N * H(cnt) for cnt in by_c.values())
Hc_r = sum(sum(cnt.values()) / N * H(cnt) for cnt in by_r.values())
h = 1 - Hr_c / Hr if Hr else 1; cpl = 1 - Hc_r / Hc if Hc else 1
v = 2 * h * cpl / (h + cpl) if h + cpl else 0
print("\nhomogeneity %.3f  completeness %.3f  V-measure %.3f  (RepeatMasker names as reference)" % (h, cpl, v))
