from fpylll import *
import os

outputs = os.path.abspath("output2")

RR = RealField(100)

os.environ["SAGE_NUM_THREADS"] = "48"

load("lib/Dh.sage")

@parallel()
def HnpSolver(label, dh, b, t, beta, fudge):
  start = walltime()
  def info(msg):
    elapsed = walltime() - start
    with open(os.path.join(outputs, label + ".out"), "a") as fh:
      fh.write("%s:%010.3f: %s\n" % (label, elapsed, msg))

  p = Integer(dh.p)
  q = Integer(dh.q)
  g = Integer(dh.g)
  nbits = dh.n

  eps = nbits - RR(log(p, 2)) # bias of the modulus
  ell = b - eps # effective number of given most significant bits

  # generate DH-keys
  sk_a = ZZ.random_element(1, q)
  pk_a = power_mod(g, sk_a, p)
  sk_b = ZZ.random_element(1, q)
  pk_b = power_mod(g, sk_b, p)

  # shared secret
  dh_ab = power_mod(pk_a, sk_b, p)
  assert( dh_ab == power_mod(pk_b, sk_a, p) )

  # generate HNP data (cheating, fast)
  mult = vector(ZZ, t)
  appr = vector(ZZ, t)
  dh_ab_inv = inverse_mod(dh_ab, p)
  for i in range(t):
    mult[i] = ( dh_ab_inv*ZZ.random_element(1, 2^(nbits-b)) ).mod(p)
    appr[i] = 2^(nbits-b-1)    
    dist = (mult[i]*dh_ab - appr[i]).mod(p)
    assert( min(dist, p-dist ) <= p/2^(ell+1) )

  #build lattice
  B = matrix(ZZ, t+2, t+2)
  factor = ceil(2^ell)
  B[0, 0] = 1
  B[1, 1] = ceil( p/(2*fudge) )
  for i in range(t):
    B[  0, i+2] = factor * mult[i]
    B[  1, i+2] = factor * appr[i]
    B[i+2, i+2] = factor * p

  # lattice invariants and heuristics
  def det_lattice(p, ell, t):
    return RR( ceil(p/(2*sqrt(3))) * (ceil(2^ell)*p)^t )
  def root_det_lattice(p, ell, t):
    return det_lattice(p, ell, t)^(1/(t+2))
  def Gauss_heuristic(p, ell, t):
    return RR( sqrt((t+2)/(2*pi*e)) * det_lattice(p, ell, t)^(1/(t+2)) )
  def exp_norm_hidden_vector(p, t):
    return RR( sqrt((t+2)/12) * p )
  def exp_Hermite_delta(p, ell, t):
    return exp_norm_hidden_vector(p, t) / root_det_lattice(p, ell, t)
  def exp_root_Hermite_delta(p, ell, t):
    return exp_Hermite_delta(p, ell, t)^(1/(t+2))
  def gap_lattice(p, ell, t):
    return Gauss_heuristic(p, ell, t) / exp_norm_hidden_vector(p, t)
  def tau_lattice(p, ell, t):
    return gap_lattice(p, ell, t) / exp_Hermite_delta(p, ell, t)
    

  # modified lattice invariants and heuristics (shortest vector (p, 0, ..., 0) removed)
  def mod_det_lattice(p, ell, t):
    return det_lattice(p, ell, t) / p
  def mod_root_det_lattice(p, ell, t):
    return mod_det_lattice(p, ell, t)^(1/(t+1))
  def mod_Gauss_heuristic(p, ell, t):
    return RR( sqrt((t+1)/(2*pi*e)) * mod_det_lattice(p, ell, t)^(1/(t+1)) )
  def mod_exp_norm_hidden_vector(p, t):
    return RR( sqrt((t+1)/12) * p )
  def mod_exp_Hermite_delta(p, ell, t):
    return mod_exp_norm_hidden_vector(p, t) / mod_root_det_lattice(p, ell, t)
  def mod_exp_root_Hermite_delta(p, ell, t):
    return mod_exp_Hermite_delta(p, ell, t)^(1/(t+1))
  def mod_gap_lattice(p, ell, t):
    return mod_Gauss_heuristic(p, ell, t) / mod_exp_norm_hidden_vector(p, t)
  def mod_tau_lattice(p, ell, t):
    return mod_gap_lattice(p, ell, t) / mod_exp_Hermite_delta(p, ell, t)

  det_B = det_lattice(p, ell, t)
  root_det_B = root_det_lattice(p, ell, t)
  gh_B = Gauss_heuristic(p, ell, t)
  exp_norm_hidden_vec = exp_norm_hidden_vector(p, t)
  exp_root_Hermite_del = exp_root_Hermite_delta(p, ell, t)

  mod_det_B = mod_det_lattice(p, ell, t)
  mod_root_det_B = mod_root_det_lattice(p, ell, t)
  mod_gh_B = mod_Gauss_heuristic(p, ell, t)
  mod_exp_norm_hidden_vec = mod_exp_norm_hidden_vector(p, t)
  mod_exp_root_Hermite_del = mod_exp_root_Hermite_delta(p, ell, t)

  info("Instance".center(60, "="))
  info("# of equations: %i" % t)
  info("Gap: %.2f" % gap_lattice(p, ell, t))
  info("Tau: %.2f" % tau_lattice(p, ell, t))

  #solve HNP

  def root_Hermite_delta_BKZ(beta):
    return RR( (pi*beta)^(1/beta)*beta/(2*pi*e) )^(1/(2*(beta-1)))
  exp_norm_BKZ = RR( root_Hermite_delta_BKZ(beta)^(t+2) * root_det_B )

  info(("BKZ-"+str(min(beta, t+2))+" reduction").center(60, "="))
  time_total = walltime()
  C = IntegerMatrix.from_matrix(B)

  info("Expectedly achievable log(norm): %.2f" % log(exp_norm_BKZ, 2))

  #basis vector norms
  mat = matrix(ZZ, C.nrows, C.ncols)
  C.to_matrix(mat)   
  norms = [round(log(sqrt(RR(row*row)), 2), 2) for row in mat]
  info("log(exp-norms): %r" % ([round(log(RR(p), 2), 2),
                          round(log(exp_norm_hidden_vec, 2), 2),
                          round(log(gh_B, 2), 2)],))
  info("log(norms):     %r" % (norms[0:10],))


  BKZ_params = BKZ.Param(block_size=beta,
                       strategies=load_strategies_json(BKZ.DEFAULT_STRATEGY),
                       max_loops=1,
                       #flags=BKZ.VERBOSE
                       )

  num_loops = 100
  for loop in range(num_loops):

    info("Loop %i/%i" % (loop+1, num_loops))
    time_loop = walltime()
    BKZ.reduction(C, BKZ_params, float_type="mpfr", precision=128)  
    C.to_matrix(B)      
    
    #basis vector norms
    mat = matrix(ZZ, C.nrows, C.ncols)
    C.to_matrix(mat)
    #root_Hermite_del = (sqrt(RR(mat[1]*mat[1]))/ root_det_B) ^ (1/(t+2))
    #info("(", root_Hermite_del, "/", exp_root_Hermite_del, ")")    
    norms = [round(log(sqrt(RR(row*row)), 2), 2) for row in mat]
    info("log(exp-norms): %r" % ([round(log(RR(p), 2), 2),
                              round(log(exp_norm_hidden_vec, 2), 2),
                              round(log(gh_B, 2), 2)],))
    info("log(norms):     %r" % (norms[0:10],))
            
    #done?
    solution = 0
    for row_vec in C:
        tmp = row_vec[0].mod(p)
        if tmp == dh_ab:
            solution = tmp
        if p-tmp == dh_ab:
            solution = p-tmp
    info("("+str(ceil(walltime(time_loop)))+" sec)")
    
    if solution:
        break
    

  #output
  info("Summary".center(60, "="))
  elapsed = ceil(walltime(time_total))
  info("Total time: %isec" % ceil(walltime(time_total)))
  if solution:
    info("SUCCESS")
    info("HNP solution: %s" % (str(solution),))
    info("Shared secret: %s" % (str(dh_ab),))
    result = True
  else:
    info("FAIL")
    result = False

  summary = (nbits, b, t, beta, elapsed, result)
  info("SUMMARY:n:%i:k:%i:d:%i:bs:%i:t:%i:r:%r" % summary)
  if solution:
    return True
  else:
    return False

##########################
# Jobs are defined here! #
##########################

dh1024 = Dh(name="1024-bit MODP from RFC 5114")
dh1036 = Dh(name="LibTomCrypt 1024-bit (actually 1036-bit)")
dh2048 = Dh(name="SKIP 2048-bit")

fudges = [1, 1.75, RR(sqrt(3))]

experiments = [
  # dh, k, d, bs, fudge
  (dh1024, 8, 200, 60, fudges[0]),
  (dh1024, 8, 200, 60, fudges[1]),
  (dh1024, 8, 200, 60, fudges[2])
]

reps = 8

def generate_jobs():
  jobs = []
  cnt = 0
  for ex in experiments:
    for rep in range(reps):
      dh, k, d, bs, f = ex
      cnt = cnt + 1
      label = "exp%03i-n%i-k%02i-d%03i-bs%02i-f%.3f-r%02i" % (cnt, dh.n, k, d, bs, f, rep)
      jobs.append((label, dh, k, d, bs, f))
  return jobs
jobs = generate_jobs()

# Execute all.

begin = walltime()
for job in jobs:
    print("%s:%010.3f:BEGIN" % (job[0], 0))

results = HnpSolver(jobs)

for res in results:
    pjob, ret = res
    job, obj = pjob
    elapsed = walltime() - begin
    print("%s:%010.3f:END:%r" % (job[0], elapsed, ret))
