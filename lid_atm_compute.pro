pro lid_atm_compute, profnum, pinfo, prof


@lid_settings.include


if (n_params() EQ 1) then begin
	pinfo = profinfo[profnum]
	prof  = profile[profnum]
endif

if (~pinfo.aerosol) then return

isash = (pinfo.inv_type EQ _ash_)

n1 = ovl
n2 = pinfo.f_idx[1]

cnt  = n_elements(prof.height)
t    = dblarr(cnt)
tau  = 0.0D
tau_ash = 0.0D
tau_oth = 0.0D
skip = 0

if (pinfo.totdep) then begin
	lidpr2 = reform(prof.pr2[*,0] + prof.pr2[*,1] / pinfo.p_norm)
endif else begin
	lidpr2 = reform(prof.pr2[*,0])
endelse

for i = n1+1, cnt-1 do begin
	if (i GT n2 && prof.alpha[i] LT 0.0D) then skip=1
	if (~skip) then begin
		t[i] =  t[i-1] $
		   + prof.alpha[i] * abs(prof.range[i]-prof.range[i-1])
	endif else begin
		t[i] =  t[i-1]
	endelse
	if (i LE n2) then begin
		dz = abs(prof.height[i]-prof.height[i-1])
		tau += prof.alpha[i] * dz
		if (isash) then begin
			tau_ash += prof.alpha_ash[i] * dz
			tau_oth += prof.alpha_oth[i] * dz
		endif
	endif
endfor
pinfo.tot_aod = tau
if (isash) then begin
	pinfo.ash_aod = tau_ash
	pinfo.oth_aod = tau_oth
endif

l_def = (pinfo.layer_idx[1,*] NE 0L $
	AND pinfo.layer_idx[1,*] GE pinfo.layer_idx[0,*])
for k=0, nlayers-1 do begin
	tau_lay  = 0.0D
	totd_lay = 0.0D
	aerd_lay = 0.0D
	pk_hgt   = 0.0D
	pk_fwhm  = 0.0D
	pk_ext   = 0.0D
	lay_hgt  = 0.0D
	lay_dpth = 0.0D
	if (l_def[k]) then begin
		idx1 = pinfo.layer_idx[0,k]
		idx2 = pinfo.layer_idx[1,k]
		for i = idx1+1, idx2 do $
			tau_lay += prof.alpha[i] $
				* abs(prof.height[i]-prof.height[i-1])

		alphalay  = prof.alpha[idx1:idx2]
		pk_ext = max(alphalay, idxm)
		pk_hgt = prof.height[idx1 + idxm]
		if (mean(alphalay) GT 1E-6) then begin
			lay_hgt  = mean(prof.height[idx1:idx2]*alphalay) $
				/ mean(alphalay)
			lay_dpth = sqrt(2.0D) * tau_lay / pk_ext
		endif
		idx = where(alphalay GE 0.5*pk_ext, n_idx)
		if (n_idx GT 0) then begin
			idx1m = idx1 + idx[0]
			idx2m = idx1 + idx[n_idx-1]
			pk_fwhm = abs(prof.height[idx2m] - prof.height[idx1m])
			idx = where(prof.totdepol[idx1m:idx2m] GT 0.0D, n_idx) $
				+ idx1m
			if (pinfo.totdep && n_idx GT 0) then $
				totd_lay = mean(prof.totdepol[idx])
			idx = where(prof.aerdepol[idx1m:idx2m] GT 0.0D, n_idx) $
				+ idx1m	
			if (pinfo.aerdep && n_idx GT 0) then $
				aerd_lay = mean(prof.aerdepol[idx])
		endif
	endif
	pinfo.layer_aod[k]     = tau_lay
	pinfo.layer_totdep[k]  = totd_lay
	pinfo.layer_aerdep[k]  = aerd_lay
	pinfo.layer_pk_hgt[k]  = pk_hgt
	pinfo.layer_pk_fwhm[k] = pk_fwhm
	pinfo.layer_pk_ext[k]  = pk_ext
	pinfo.layer_hgt[k]     = lay_hgt
	pinfo.layer_dpth[k]    = lay_dpth
endfor

trayovl = total(prof.mol_beta[0:ovl]*(prof.range[1:ovl]-prof.range[0:ovl])) $
	/0.119366D
norm_br = mean(prof.beta[(ovl-5):(ovl+5)] / prof.mol_beta[(ovl-5):(ovl+5)])
klid    = normalize(lidpr2, prof.mol_beta, [(ovl-5),(ovl+5)], norm_br) $
	* exp(2.0D * prof.alpha[ovl] * prof.range[ovl] + 2.0D * trayovl) * 4D-6
pinfo.klid[0] = klid

norm_br  = mean(prof.beta[(n1-5):(n1+5)] / prof.mol_beta[(n1-5):(n1+5)])
kmol     = normalize(lidpr2, prof.mol_pr2, [(n1-5),(n1+5)], norm_br)
prof.mol_corr[*,0] = kmol * prof.mol_pr2 * exp(-2.0D * t)

if (pinfo.after_dep) then begin
	pinfo.klid[1] = pinfo.klid[0] * pinfo.p_norm
	prof.mol_corr[*,0] /= (1.0D + pinfo.p_cal)
	prof.mol_corr[*,1] = prof.mol_corr[*,0] * pinfo.p_cal * pinfo.p_norm
endif else begin
	pinfo.klid[1] = _dundef_
	prof.mol_corr[*,1] = 0.0D
endelse

if (n_params() EQ 1) then begin
	profile[profnum]  = prof
	profinfo[profnum] = pinfo
endif

end
