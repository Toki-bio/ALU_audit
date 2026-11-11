import random, collections
lab=[l.rstrip("\n").split("\t")[1] for l in open("round2/S/s2.labels.tsv")]
def pur(n, seed):
    r=random.Random(seed); x=lab[:]; r.shuffle(x)
    ch=[x[i:i+n] for i in range(0,len(x)-n+1,n)]
    p=[collections.Counter(c).most_common(1)[0][1]/len(c) for c in ch]
    return sum(p)/len(p), sum(1 for v in p if v>=0.7), sum(1 for v in p if v>=0.9), len(p)
for n in (50,10):
    print("random chunks n=%d: mean purity %.3f, >=0.7: %d, >=0.9: %d of %d" % ((n,)+pur(n,1)))
