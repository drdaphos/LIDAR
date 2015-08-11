pro marenco2011, pinfo, prof, aer_dr1, lr1, lr2, $
	ref_idx=ref_idx, ref_br1=ref_br1, betatot=betatot, alphatot=alphatot, $
	beta1=beta1, alpha1=alpha1, beta2=beta2, alpha2=alpha2

;
; Marenco and Hogan, JGR (2011)
;

compile_opt strictarr, strictarrsubs

@lid_settings.include


if (~pinfo.totdep) then message, 'Depolarization undefined'

if (n_elements(ref_idx) LE 0) then ref_idx = pinfo.f_idx
if (n_elements(ref_br1) LE 0) then ref_br1 = pinfo.f_br

cnt   = maxaltitudes
cnt2  = ref_idx[1] + 1
nref  = long(mean(ref_idx))

pr2   = prof.pr2tot[0:cnt2]
d_vol = prof.totdepol[0:cnt2]
bmol  = prof.mol_beta[0:cnt2]
hgt   = prof.height[0:cnt2]

molr = 1.0D / 0.119366D
ym   = 1.0D / (1.0D + mol_dr)
y1   = 1.0D / (1.0D + aer_dr1)
xm   = (mol_dr/d_vol  - 1.0D) * ym
x1   = (aer_dr1/d_vol - 1.0D) * y1

bpm = bmol * (1.0D + xm)
apm = bmol * (molr + lr2 * xm)
eps = 1.0D + x1
eta = lr1 + lr2 * x1

ref1  = ref_br1 - 1.0D
bnorm = bpm + eps * bmol * ref1
knorm = normalize(pr2, bnorm, ref_idx, 0.0D)
dalph = eta * bpm / eps - apm

hh = reverse(hgt[0:nref])
pr = reverse(pr2[0:nref])
et = reverse(eta[0:nref])
ep = reverse(eps[0:nref])
aa = reverse(dalph[0:nref])
bb = et * pr / ep
nr = nref-1
nstep = -1

dz = abs(hh[1:*] - hh[0:nr]) * (nstep / pinfo.con)
da = (aa[1:*] + aa[0:nr]) * dz
a  = total(da, /cumulative)
ea = exp(-a)
db = (bb[1:*] + bb[0:nr]) * ea * dz
b  = total(db, /cumulative)
ba = pr[1:*] * ea / (knorm - b)

beta1 = dblarr(cnt)
beta2 = dblarr(cnt)

beta1[0:(nref-1)] = reverse(ba)
beta1[nref] = bnorm[nref]
beta1[0:nref] -= bpm
beta1[0:nref] /= eps

beta2[0:(nref-1)] = xm * bmol + x1 * beta1[0:(nref-1)]

alpha1 = lr1 * beta1
alpha2 = lr2 * beta2

betatot = beta1 + beta2
alphatot = alpha1 + alpha2


end
