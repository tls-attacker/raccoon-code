from collections import defaultdict
load("lib/Dh.sage")

dh1024 = Dh(name="1024-bit MODP from RFC 5114")
dh1036 = Dh(name="LibTomCrypt 1024-bit (actually 1036-bit)")
dh2048 = Dh(name="SKIP 2048-bit")
dh3072 = Dh(name="3072-bit MODP from RFC 3526")
dh4096 = Dh(name="4096-bit FFDHE group from RFC 7919")

def print_epsilon(name, dh):
  n, p = dh.n, dh.p
  eps = n - log(p, 2)
  
  print("%s: eps=%.3f" % (name, RR(eps)))

print_epsilon("1024", dh1024)
print_epsilon("1036", dh1036)
print_epsilon("2048", dh2048)
print_epsilon("3072", dh3072)
print_epsilon("4096", dh4096)

with open("summary.txt", "r") as fh:
  lines = fh.readlines()

experiment = defaultdict(list)

for line in lines:
    line = line.strip()
    head, summary = line.split()
    # SUMMARY:n:1024:k:8:d:200:bs:60:t:9174:r:True
    tag, ntag, n, ktag, k, dtag, d, bstag, bs, ttag, t, rtag, r = summary.split(":")
    assert(tag == "SUMMARY")
    assert(ntag == "n")
    assert(ktag == "k")
    assert(dtag == "d")
    assert(bstag == "bs")
    assert(ttag == "t")
    assert(rtag == "r")
    assert(r == "True")
    n = int(n)
    k = int(k)
    d = int(d)
    bs = int(bs)
    t = int(t)
    assert (n == 1024 or n == 1036 or n == 2048 or n == 3072 or n == 4096)
    assert (bs == 40 or bs == 60)
    #print (n, k, d, bs, t)
    ex = (n, k)
    experiment[ex].append((d, bs, t))

for key, val in sorted(experiment.items()):
    n, k = key
    dd, bbss, _ = val[0]
    times = []
    for rep in val:
      d, bs, t = rep
      assert (d == dd)
      assert (bs == bbss)
      times.append(t)
    print ("n=%i, k=%i, d=%i, bs=%i, t=%i\seconds \\pm %i\seconds" % (n, k, dd, bbss, mean(times), std(times)))
