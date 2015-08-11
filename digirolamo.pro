pro digirolamo, height, lidpr2, molpr2, betamol, near_idx, near_br, $
	far_idx, far_br, cos_offnadir=cos_offnadir, $
	beta=beta, alpha=alpha, mol_corr=mol_corr, $
	ib=ib, tau=tau, ratio=ratio, iterations=iterations, $
	abort=abort, verbose=verbose, piv=piv, debug=debug
;
; Di Girolamo et al, GRL 21, 1295 (1994)
; Marenco et al, AO 27, 6875 (1997)
;

compile_opt strictarr, strictarrsubs

if (n_elements(verbose) NE 1) then verbose = 1
thresh=0.0005D
max_iter=50
if (n_elements(piv) NE 1) then piv = 20
maxprint = 20
abort = 0

cnt = n_elements(height)

if (n_elements(lidpr2) NE cnt || n_elements(molpr2) NE cnt) then $
	message, '*** Inconsistent input array dimensions ?!?'

if (n_elements(cos_offnadir) NE 1) then cos_offnadir = 1.0

klid_near = normalize(lidpr2, molpr2, near_idx, near_br)
klid_far  = normalize(lidpr2, molpr2, far_idx, far_br)

beta = dblarr(cnt)
alpha = dblarr(cnt)
t = dblarr(cnt)
n1 = long(mean(near_idx))
n2 = long(mean(far_idx))
h1 = height[n1]
h2 = height[n2]

tau = 0.5D * alog(klid_near / klid_far)
alpha[n1:n2] = cos_offnadir * tau / abs(h1-h2)
ratio = 1D6

if (verbose GE 2) then begin
	print, format='(%"Di Girolamo: near=(%d %d) far=(%d %d) n=(%d %d) ' $
		+ 'h=(%d %d)")', fix(round(near_idx[0])), $
		fix(round(near_idx[1])), fix(round(far_idx[0])), $
		fix(round(far_idx[1])), n1, n2, fix(round(h1)), fix(round(h2))
	print, format='(%"Di Girolamo: br=(%5.3f %5.3f) klid=(%7.1e, %7.1e) ' $
		+ 't=%4.2f a=%7.1e")', near_br, far_br, klid_near, klid_far, $
		tau,alpha[n1]
end

iterations = 0
repeat begin
	for i = n1+1, cnt-1 do begin
		t[i] = t[i-1]+alpha[i]*abs(height[i]-height[i-1])/cos_offnadir
	endfor
	mol_corr = klid_near * molpr2 * exp(-2.0D * t)
	beta[n1:n2] = betamol[n1:n2] * (lidpr2[n1:n2] / mol_corr[n1:n2] - 1.0D)
	ib = int_tabulated(height[n1:n2],beta[n1:n2],/sort,/double)/cos_offnadir
	ratio_old = ratio
	ratio = ib / tau
	alpha[n1:n2] = beta[n1:n2] / ratio
	f = abs((ratio-ratio_old)/ratio_old)
	++iterations
	if (verbose GE 2 || (verbose && iterations MOD piv EQ 0 $
		&& iterations*piv LT maxprint)) then print, $
		format='(%"Di Girolamo: it=%2d t=%5.3f ib=%10.3e lr=%f [%f]")',$
		iterations,tau,ib, 1.0D/ratio, f
endrep until (f LT thresh || iterations GE max_iter)

ratio = 1.0D / ratio
tau  *= cos_offnadir
ib   *= cos_offnadir

if (f GT thresh || ~finite(ratio)) then begin
	if (keyword_set(debug) && ~verbose) then digirolamo, height, $
		lidpr2, molpr2, betamol, near_idx, near_br, far_idx, $
		far_br, cos_offnadir=cos_offnadir, verbose=1, piv=1
	ratio    = 0.0D
	ib       = 0.0D
	beta     = dblarr(cnt)
	alpha    = dblarr(cnt)
	mol_corr = dblarr(cnt)
	if (verbose GE 1) then $
		print, format='(%"Di Girolamo: aborted after %d iterations")', $
			iterations
	abort = 1
end

if (verbose GE 2) then begin
	print, format='(%"Di Girolamo: t=%5.3f ib=%9.3e lr=%f")', tau,ib,ratio
	print, ''
end

fernald, height, lidpr2, betamol, near_idx, near_br, ratio, $
	cos_offnadir=cos_offnadir, beta=betafer, alpha=alphafer
beta[0:(n1-1)]  = betafer[0:(n1-1)]
alpha[0:(n1-1)] = alphafer[0:(n1-1)]

fernald, height, lidpr2, betamol, far_idx, far_br, ratio, $
	cos_offnadir=cos_offnadir, beta=betafer, alpha=alphafer
beta[(n2+1):(cnt-1)]  = betafer[(n2+1):(cnt-1)]
alpha[(n2+1):(cnt-1)] = alphafer[(n2+1):(cnt-1)]

end
