#!/usr/bin/env sage

# Small convenient hack to simulate as if we were always executing from '<trunk>/'
import os
import sys
os.chdir(os.path.dirname(__file__) + "/../");
sys.path.append("./src/");
# --------------------------------------------------------------------------------------

import itertools

from sage.all import *
import fp
from pcmp_io  import *
from ZR_mat   import *
from lattice  import *
from idsvp    import *
from random_log_elt import *

if len(sys.argv) != 6:
    print(("Usage: {:s} <data_root> z<m> <d> sat=[true/false] su=[true/false]\n"+
           "\tfor Cyclotomic Field of conductor <m>\n"+
           "\tfor Factor Bases consisting of a maximum of <d> (split prime) orbits\n"+
	   "\tsat/su: precise whether we have saturated elements and/or full S-units? <b>")
          .format(sys.argv[0]));
    sys.exit(2);

data_root = sys.argv[1];
tag   = sys.argv[2];
dmax  = ZZ(sys.argv[3]);
b_sat = True if sys.argv[4] == "sat=true" else False; 
b_su  = True if sys.argv[5] == "su=true"  else False; 


# --------------------------------------------------------------------------------------
# Obtain number field
K = nf_set_tag(tag);
r1, r2 = K.signature();
n = K.degree();
abs_disc = K.discriminant().abs();
print ("{}: eval approx factor of log S-unit lattices".format(tag), flush=True);


# ----------------------------------------------------------------------------------
# Reduction parameters
BLOCK_SZ  = 40;
W_PREC    = 500;
NB_ITER   = 80;


# ----------------------------------------------------------------------------------
# For each precomputed sets, generate the corresponding lattice (with iso/noiso:exp/tw)
opt_sets = ["urs"] + (["sat"] if b_sat == True else []) + (["su"] if b_su == True else []);
opt_iso  = { "iso": True,       "noiso": False };
opt_inf  = { "exp": "EXPANDED", "tw"   : "TWISTED" };

measures_set = ["afsup", "gf", "afinf", "hf"];
l_names      = [ "{}/{}/{}".format(_s,_iso,_inf) for _s,_iso,_inf in itertools.product(opt_sets, opt_iso.keys(), opt_inf.keys()) ];


# ----------------------------------------------------------------------------------
# List of lattices
data_dir  = data_root + "/{}/".format(tag);


# Approx factor
# ------------------------------
def print_headers(streams, d):
    assert(len(streams) == len(measures_set));
    for _i in range(len(measures_set)):
        _f_out = streams[_i];
        _f_out.write("# Measure:'{}' nf:'{}' orb={} prec={} bkz_sz={}\n# ".format(measures_set[_i], tag, d, W_PREC, BLOCK_SZ));
        for _s, _iso, _inf in itertools.product(opt_sets, opt_iso.keys(), opt_inf.keys()):
            _f_out.write("{}/{}/{}\t".format(_s,_iso,_inf));

        _f_out.write("\n");
        _f_out.flush();
    return;


def approx_factor_sup(ls, Nb):
    Re     = RealField(W_PREC);
    b_inf  = sqrt(Re(n)) * Re(Nb)^(1/Re(n));
    t2_s   = logarg_t2_norm_cf(ls);
    return Re(t2_s/b_inf);


def approx_factor_inf(ls, Nb):
    Re     = RealField(W_PREC);
    b_sup  = sqrt(Re(n)) * Re(Nb)^(1/Re(n)) * abs_disc^(1/Re(2*n));
    t2_s   = logarg_t2_norm_cf(ls);
    return Re(t2_s/b_sup);


# compute root hermite factor
def hermite_factor(ls, Nb):
    Re     = RealField(W_PREC);
    t2_s   = logarg_t2_norm_cf(ls);
    hf     = ( t2_s / Re(Nb)^(1/Re(n)) / abs_disc^(1/Re(2*n)) )^(1/Re(n));
    return hf;


# compute norm of sol. / gaussian heuristic
def gaussian_factor(ls, Nb):
    Re     = RealField(W_PREC);
    gauss  = sqrt(Re(n)/Re(2)/Re(pi)/Re(e)) * Re(Nb)^(1/Re(n)) * abs_disc^(1/Re(2*n));
    t2_s   = logarg_t2_norm_cf(ls);
    return t2_s / gauss ;


def compute_afs(sols, Nb):
    # measures_set = ["afsup", "gf", "afinf", "hf"];    
    af_sup = [ approx_factor_sup(_sol, Nb) for _sol in sols ];
    gf     = [ gaussian_factor  (_sol, Nb) for _sol in sols ];
    af_inf = [ approx_factor_inf(_sol, Nb) for _sol in sols ];
    hf     = [ hermite_factor(_sol, Nb)    for _sol in sols ];
    return [af_sup, gf, af_inf, hf];

def af_write_data(streams, data):
    assert(len(data) == len(measures_set) and all(len(_af) == len(l_names) for _af in data));

    for _f, _data in zip(streams, data):
        _f.write(("{:<13.4f}\t"*(len(l_names)-1)+"{:<13.4f}\n").format(*(map(float, _data))));
        _f.flush();
    return;


# -------------------------------------------------------------------------------------
# Read infinte places
inf_places_file = data_dir + "{}.inf".format(tag);
p_inf = inf_places_read_data(inf_places_file, K);
p_inf = adapt_inf_places(K, p_inf, to_prec=W_PREC);


# for _d in range(dmax):
for _d in [dmax-1]:
    # --------------------------------------------------------------------------------
    # Read precomputations
    # Factor base
    f_fb  = data_dir + "{}_d{}.fb".format(tag, _d+1);
    fb    = fb_read_data(f_fb, K);
    # S-units for each set
    la_SU_all = [];
    for _s in opt_sets:
        f_su = data_dir + "{}_d{}.{}".format(tag, _d+1, _s);
        print ("Import raw S-units material for '{}' from '{}'".format(_s,f_su), end='', flush=True);
        t = cputime(); (yu, ysu), Bsu, Bvp = sunits_raw_read_data(f_su, K); t = cputime(t);
        print ("\t[done] t={:.2f}".format(t), flush=True);

        # -----------------------------------------------------------------------------
        # Obtain logarg representation of S-units.
        print ("Logarg(raw)\t\t", end='', flush=True);
        t = cputime(); la_Bsu = [ logarg_set(_g, p_inf, fb=fb, vp=_val_g) for _g, _val_g in zip(Bsu,Bvp) ]; t = cputime(t);
        print ("\t[done] t={:.2f}".format(t), flush=True);
        print ("su=mpow(logarg)\t\t", end='', flush=True);
        t = cputime(); la_su  = [ logarg_mpow(la_Bsu, _y) for _y in yu + ysu ]; t = cputime(t);
        print ("\t[done] t={:.2f}\n".format(t), flush=True);
        # -----------------------------------------------------------------------------
        
        la_SU_all.append(la_su);
    # // Su Done.

    # fHcE for all iso/noiso-exp/tw options
    print ("Compute fHcE matrices", end='', flush=True);
    t = cputime();
    fHcE = { "{}/{}".format(_iso,_inf): get_twfHcE_matrix(r1, r2, len(fb), inf_type=opt_inf.get(_inf), isometry=opt_iso.get(_iso), b_prec=W_PREC)
             for _iso, _inf in itertools.product(opt_iso.keys(), opt_inf.keys()) };
    t = cputime(t);
    print ("\t[done] t={:.2f}\n".format(t), flush=True);

    # Read lattices: BKZ+GSO+lu
    B_bkz   = [];
    U_bkz   = [];
    G_bkz   = [];
    print ("Reading bases BKZ/GSO/LU", flush=True);
    i = 0;
    for _s,_iso,_inf in itertools.product(opt_sets,opt_iso.keys(),opt_inf.keys()):
        print("\t{}:".format(l_names[i]), end='', flush=True);
        assert(l_names[i] == "{}/{}/{}".format(_s,_iso,_inf));
        
        # Lattices
        label     = "d{}_{}_{}_{}".format(_d+1,_s,_iso,_inf);
        f_bkz     = data_dir + "{}_{}.bkz-{}".format(tag, label, BLOCK_SZ);
        f_bkz_gso = data_dir + "{}_{}.bkz-{}_gso".format(tag, label, BLOCK_SZ);
        f_bkz_u   = data_dir + "{}_{}.bkz-{}_U".format(tag, label, BLOCK_SZ);
        assert(all(os.path.exists(_file) for _file in [f_bkz,f_bkz_u,f_bkz_gso]));
        
        # Read lattice and transformation matrix
        t = cputime(); B_bkz += [lattice_read_data(f_bkz,     to_b_prec=W_PREC)]; t = cputime(t);
        print("\tBKZ:'{}'\tt={:.2f}".format(f_bkz, t),     end='', flush=True);
        t = cputime(); G_bkz += [lattice_read_data(f_bkz_gso, to_b_prec=W_PREC)]; t = cputime(t);
        print("\tGSO:'{}'\tt={:.2f}".format(f_bkz_gso, t), end='', flush=True);
        t = cputime(); U_bkz += [lattice_ZZ_read_data(f_bkz_u)]; t = cputime(t);
        print("\tLU:'{}'\tt={:.2f}".format(f_bkz_u, t), flush=True);
        i += 1;
        
    
    # --------------------------------------------------------------------------------
    # Results files
    out_names = [ data_dir + "{}_d{}.{}".format(tag, _d+1, _measure) for _measure in measures_set ]; 
    out_files = [ open(_file, "w") for _file in out_names ];
    # Prepare Headers
    print_headers(out_files, _d);
    
    
    # --------------------------------------------------------------------------------
    # Read targets in logarg rep
    f_targets = data_dir + "{}_d{}.targets".format(tag, _d+1);    
    print("Read targets in '{}'".format(f_targets));
    targs     = logarg_read_data(f_targets, K);

     
    # --------------------------------------------------------------------------------
    # Now, the real deal
    for _k in range(len(targs)):
        print ("Challenge #{}:".format(_k));
        _t = targs[_k];
               
        # norm of b corresponding to target
        b_ln = norm_from_logarg(_t, fb);
        Nb   = round(exp(b_ln));
        print("\tN(b):\t\t{}".format(Nb));
        
        count_ops = 0;
        sols = []; # indexed by measure set
        for _s,_iso,_inf in itertools.product(opt_sets, opt_iso.keys(),opt_inf.keys()):
            # Indices
            ind = opt_sets.index(_s);
            assert(l_names[count_ops] == "{}/{}/{}".format(_s, _iso, _inf) and opt_sets[ind] == _s);
            
            # Apply Tw-PHS for one target
            t = cputime();
            print("\tmethod:'{}':".format(l_names[count_ops]), flush=True);
            ls, ns = twphs_protocol2(_t, p_inf, fb, fHcE.get("{}/{}".format(_iso,_inf)),
                                     B_bkz[count_ops], U_bkz[count_ops], la_SU_all[ind],
                                     NB_ITER, inf_type=opt_inf.get(_inf), G=G_bkz[count_ops],
                                     b_prec=W_PREC);
            t = cputime(t);
            print("\t[done] t2_norm={:7.3f} t={:.2f}".format(float(ns),t), flush=True);
            
            # Compute all ratios from sol
            sols      += [ls];
            count_ops += 1;
        
        af_rat = compute_afs(sols, Nb);
        assert(len(af_rat) == len(measures_set));
        assert(all(len(_af) == len(l_names) for _af in af_rat));
        af_write_data(out_files, af_rat);
        
exit;