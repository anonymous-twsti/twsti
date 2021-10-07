# Tw-STI
Code for submission #316 (EUROCRYPT'21): "Log-S-unit lattices using Explicit Stickelberger Generators to solve Approx Ideal-SVP"


### Environment

The provided code has been tested with the following versions.

| Soft      | Version  | Url  |
| :---      | :---     | :--- |
| Magma     | v2.24-10 | https://magma.maths.usyd.edu.au/magma/ |
| SageMath  | v9.0     | https://www.sagemath.org/ |
| fplll     | v5.3.2   | https://github.com/fplll/fplll |


##### Remark
We suppose that fplll is in `/usr/local/bin`.
For changing this, you must edit in `./src/lattice.py` the following line:
```
__FPLLL_PATH = "/usr/local/bin/";
```

### Computational workflow

Note that `./data/list_ms_pcmp` contains the list of cyclotomic fields conductors for which h+=1 is known/computable, and of degree 20 < n < 192.

For simplicity, we suppose that everything is executed from `./scripts`, but it should work from everywhere. The conductor of the targetted cyclotomic field is `<m>`. Each script accepts a list of conductors, but beware that one or several threads will be launched for **each** of the conductors in the list.

0. Make sure to create a `logs` folder besides the `scripts` folder.
1. Compute places: complex embeddings, factor bases:
```
./cf_places.sh <m>
```
2. Compute circular units / real relative norm generators / Stickelberger generators:
```
./urs.sh <m>
```
3. Saturate (2 saturation, one pass):
```
./saturation.sh <m>
```
4. Compute S-units; for this Magma is needed, and it should work up to degree n < 80:
```
./sunits.sh <m>
```
5. Compute log-S-unit (sub)lattices associated to these family (urs/sat/[su]) for each of the {iso/noiso}x{exp/tw} options
```
./sti_twphs_lattice.sh <m>
```
6. Reduce each available lattice with LLL and BKZ-40
```
./lat_reduce.sh <m>
```
7. Precompute Gram-Schmidt orthogonalizations:
```
./gso.sh <m>
```
8. Evaluate the geometry of the obtained lattices: root hermite factor, orthogonality defect, table of Gram-Schmidt log norms.
```
./eval_geo.sh <m>
```
9. Simulate approximation factors on 100 random targets for split prime ideals of size 2^100:
```
./rand_targets.sh <m>
./approx_factor.sh <m>                                                                             
```


### Files organisation

##### Folder list
- `./src`: All interesting stuff.
- `./scripts`: Sage/Magma scripts. Each script shall be called _via_ its Bash `.sh` counterpart.
This will redirect logs, detach thread(s), detect the number of orbits and the available S-unit sets.
- `./data`: this is where all data are put. Beware that the whole precomputation for the 192 fields weights > 1To.
- `./logs`: logs of computations, including timings and many diagnostics.


##### Naming conventions for precomputations


|Extension | Content |
|:---|:---|
`.inf`| Complex embeddings
`.fb`|  Factor bases (from d=1 to d=dmax predicted by Twisted-PHS)
`.targets`| Random targets, in the form of infinite absolute values, and p-adic valuations
`.urs`| Circular units, Real S+-units (h+=1), Stickelberger generators
`.sat`| 2-Saturated (one pass) family from urs 
`.su`| S-units, complete group when available (up to degree 80)
`.lat`,`.lat_gso`| Lattice diretly obtained after Twisted-PHS-like construction 
`.lll`, `.lll_U`,`.lll_gso`| LLL Version of the above, with unitary transformation
`.bkz-<bk>`, `.bkz-<bk>_U`,`.bkz-<bk>_gso`| BKZ reduction of block size bk, with unitary transformation
`.geo`| Tables of all geometric indicators for this conductor
`.gsn`| Gram-Schmidt log norms (each gsn file contains data for raw/lll/bkz lattice for one given option)
`.afinf`,`.gf`,`.afsup`,`.hf`| Estimated approximation factors (Minkowski, Gaussian Heuristic, AGM inequality, Hermite Factor



### License

This work is published under the GNU General Public License (GPL) v3.0.
See the LICENSE file for complete statement.

