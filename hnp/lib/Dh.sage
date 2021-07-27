import json

def generate_prime(n, safe=False):
    """Generate and return a prime with N bits.
       If SAFE is true, a safe prime is generated.

       gcd(generate_prime(128), generate_prime(128, safe=True))
    """
    while True:
        p = random_prime(2^n, False, 2^(n-1))
        if not safe or ZZ((p-1)/2).is_prime():
            return p

# https://raw.githubusercontent.com/cryptosense/diffie-hellman-groups/master/gen/common.json
def cryptosense_load(fname):
    result = {}
    with open(fname) as fh:
        data = json.load(fh)["data"]
        # Fields are: g, length, name, p, prime, safe_prime
        for dh_group in data:
            result[dh_group["name"]] = dh_group
    return result

CRYPTOSENSE_DH = cryptosense_load("common.json")


class Dh(object):
    """A group for Diffie-Hellman key exchange.
       One of N, P, or NAME must be given.
       If N is given, a suitable prime number will be generated
       (if SAFE is true, a safe prime will be generated).
       The generator is G (defaults to 2 or the parameter of
       the group NAME).

       Dh(128, safe=True)
       str(Dh(512))
       Dh(p=7)
       str(Dh(p=7))
       str(Dh(name="LibTomCrypt 1024-bit (actually 1036-bit)"))
   """

    def __init__(self, n=None, safe=False, g=None, p=None, name=None):
        if name is not None:
            dhg = CRYPTOSENSE_DH[name]
            self.p = dhg["p"]
            self.g = dhg["g"]
        elif n is not None:
            self.p = generate_prime(n, safe=safe)
            self.g = 2

        if p is not None:
            self.p = p
        if g is None:
            g = 2

        # ceil(log(self.p + 1, 2))
        self.n = len(Integer(self.p).str(base=2))
        self.G = Zmod(self.p)
        self.g = self.G(g)
        self.q = int((self.p - 1)/2)

    def __repr__(self):
        return "Dh(p={}, g={})".format(self.p, self.g)
    def __str__(self):
        return "Dh(p=<{}-bit prime>, g={})".format(self.n, self.g)

