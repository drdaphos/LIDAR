pro lid_data_process, profnum, depolarization=depol, $
	fernald=fern, digirolamo=digi, ash_process=ash, $
	ash_dr=ash_dr, ash_lr=ash_lr, other_lr=other_lr, $
	d_lr=d_lr, d_ref_rel=d_ref_rel, d_ref_abs=d_ref_abs, verbose=verbose


@lid_settings.include

openw, lgf, logfln, /get_lun, /append
printf, lgf, '--> LID_DATA_PROCESS'

openw, info, infofln, /get_lun, /append
printf, info, ''

if (n_elements(nprofiles) NE 1 || nprofiles LE 0L) then $
	message, 'No data. lid_data_read must be called first.'


if (n_elements(depol) NE 1) then depol = 1
if (n_elements(digi) NE 1)  then digi  = 0
if (n_elements(ash) NE 1)   then ash   = 0
if (n_elements(fern) NE 1)  then fern  = fix(~digi AND ~ash)

if (fern + digi + ash GT 1) then $
	message, 'Can''t set more than one inversion type'

if (~depol && ~fern && ~digi && ~ash) then $
	message, 'No processing selected'

if (ash) then depol = 1

info_str = string(format='(%"Processing Options:%s%s%s%s")', $
	(depol ? ' DEPOLARIZATION' : ''), (fern ? ' FERNALD' : ''), $
	(digi ? ' DIGIROLAMO' : ''), (ash ? ' ASH' : ''))

if (n_elements(ash_dr) + n_elements(ash_lr) + n_elements(other_lr) GT 0 $
	&& ~ash) then $
		message, 'Ash processing parameters will be ignored', /continue

if (n_elements(d_lr) + n_elements(d_ref_rel) + n_elements(d_ref_abs) GT 0 $
	&& ~fern) then $
		message, 'Uncertainty parameters will be ignored', /continue

if (n_elements(ash_dr) NE 1)    then ash_dr = default_ash_dr
if (n_elements(ash_lr) NE 1)    then ash_lr = default_ash_lr
if (n_elements(other_lr) NE 1)  then other_lr = default_lr
if (n_elements(d_lr) NE 1)      then d_lr = 0.0D
if (n_elements(d_ref_rel) NE 1) then d_ref_rel = 0.0D
if (n_elements(d_ref_abs) NE 1) then d_ref_abs = 0.0D

aer_unc_compute = ((d_lr GT 0.0D OR d_ref_rel GT 0.0D $
	OR d_ref_abs GT 0.0D) AND fern)

if (n_elements(profnum) EQ 0) then begin
	first = 0
	last  = nprofiles-1
endif else if (n_elements(profnum) EQ 1) then begin
	first = profnum
	last  = profnum
endif else begin
	first = profnum[0]
	last  = profnum[1]
endelse

if (first LT 0 || last GE nprofiles) then $
	message, 'Profiles selected are out of range.'


info_str += string(format='(%"      Profiles: %d-%d")', first, last)
printf, lgf, info_str
printf, info, info_str
if (keyword_set(verbose)) then print, info_str

if (depol) then begin
	info_str = string(format='(%"Cross-talk computation: ' $
		+ 'Tp=%0.4f Ts=%0.4f Rs=%0.4f Rp=%0.4f")', crosstalk_tp, $
		crosstalk_ts, crosstalk_rs, crosstalk_rp)
	printf, lgf, info_str
	printf, info, info_str
	if (keyword_set(verbose)) then print, info_str
endif


if (aer_unc_compute) then begin
	info_str = string(format='(%"Extinction uncertainties: ' $
		+ 'delta_LR=%0.1f, delta_REF=%dMm-1(abs),%d%%(rel)")', $
		d_lr, round(1D6*d_ref_abs), round(d_ref_rel*100.0))
	printf, lgf, info_str
	printf, info, info_str
	if (keyword_set(verbose)) then print, info_str
endif


if (ash) then begin
	info_str = string(format='(%"Ash Depol: %0.2f   Ash LR: %d   ' $
		+ 'Other LR: %d")', ash_dr, round(ash_lr), round(other_lr))
	printf, lgf, info_str
	printf, info, info_str
	if (keyword_set(verbose)) then print, info_str
endif

refwarn = 0

for p=first, last do begin
	pinfo = profinfo[p]
	prof  = profile[p]
	p_norm    = 0.0D
	klid      = 0.0D
	lr        = 0.0D
	tau       = 0.0D
	iter      = 0
	depolyes  = 0
	aeryes    = 0
	depolflag = '-'
	aerflag   = '-'
	okflag    = '-'

	if (depol) then pinfo.totdep  = 0
	if (fern || digi || ash) then pinfo.aerosol = 0
	if (depol || fern || digi || ash) then pinfo.aerdep = 0

	if (depol && pinfo.p_idx[0] GE ovl && pinfo.p_idx[1] GE pinfo.p_idx[0] $
	   && pinfo.p_cal NE 0.0D) then begin
		lid_voldepol, pinfo, prof, voldep=totdepol, $
			pr2tot=pr2tot, p_norm=p_norm
		prof.totdepol = totdepol
		prof.pr2tot   = pr2tot
		pinfo.p_norm  = p_norm
		pinfo.totdep  = 1
		depolyes      = 1
		depolflag     = 'P'
	endif

	if (pinfo.totdep) then begin
		afterdep = 1
		pr2 = reform(prof.pr2tot)
	endif else begin
		afterdep = 0
		pr2 = reform(prof.pr2[*,0])
	endelse

	if (fern && pinfo.f_idx[0] GE ovl && pinfo.f_idx[1] GE pinfo.f_idx[0] $
	   && pinfo.f_br NE 0.0D && pinfo.f_lidratio NE 0.0D) then begin
		lr = pinfo.f_lidratio
		fernald, prof.height, pr2, prof.mol_beta, pinfo.f_idx, $
			pinfo.f_br - 1.0D, lr, cos_offnadir=pinfo.con, $
			beta=beta, alpha=alpha
		prof.beta  = beta
		prof.alpha = alpha
		pinfo.inv_type  = _fern_
		pinfo.after_dep = afterdep
		pinfo.aerosol   = 1
		aerflag = 'F'
		aeryes  = 1
		if (aer_unc_compute) then begin
			d_alpha = dblarr(maxaltitudes, 4)
			f_mol = prof.mol_beta[mean([pinfo.f_idx])]
			extref  = (pinfo.f_br-1.0D) * pinfo.f_lidratio * f_mol
			d_ref   = max([d_ref_abs, d_ref_rel*extref])
			extref0 = extref + d_ref * [-1, 1, 0, 0]
			if (extref0[0] LT 0.0D) then extref0[0] = 0.0D
			br0 = extref0 / (pinfo.f_lidratio * f_mol)
			lr0 = pinfo.f_lidratio + d_lr * [0, 0, -1, 1]
			for k=0, 3 do begin
				fernald, prof.height, pr2, prof.mol_beta, $
					pinfo.f_idx, br0[k], lr0[k], $
					cos_offnadir=pinfo.con, $ 
                        		alpha=alpha0
				d_alpha[*,k] = alpha0 - alpha
			endfor
			for i=0, maxaltitudes-1 do $
				prof.d_alpha[i] = max(abs(d_alpha[i,*]))
			pinfo.unc_aerosol = 1
		endif
	endif

	if (digi && pinfo.aerok $
	   && pinfo.d_idx[0] GE ovl && pinfo.d_idx[1] GE pinfo.d_idx[0] $
	   && pinfo.f_idx[0] GT pinfo.d_idx[1] $
	   && pinfo.f_idx[1] GE pinfo.f_idx[0] $
	   && pinfo.f_br NE 0.0D && pinfo.d_br NE 0.0D) then begin
		digirolamo, prof.height, pr2, prof.mol_pr2, prof.mol_beta, $
			pinfo.d_idx, pinfo.d_br-1.0D, pinfo.f_idx, $
			pinfo.f_br-1.0D, cos_offnadir=pinfo.con, $
			beta=beta, alpha=alpha, ratio=lr, tau=tau, $
			iterations=iter, abort=abort, verbose=0
		prof.beta  = beta
		prof.alpha = alpha
		pinfo.d_aod      = tau
		pinfo.d_lidratio = lr
		pinfo.d_iter     = iter
		pinfo.inv_type   = _digi_
		pinfo.after_dep  = afterdep
		if (~abort) then begin
			pinfo.aerosol = 1
			aerflag = 'D'
			aeryes  = 1
		endif
	endif

	if (ash && pinfo.aerok && pinfo.totdep && pinfo.f_idx[0] GE ovl $
	   && pinfo.f_idx[1] GE pinfo.f_idx[0] && pinfo.f_br NE 0.0D) then begin
		marenco2011, pinfo, prof, ash_dr, ash_lr, other_lr, $
			betatot=beta, alphatot=alpha, $
			alpha1=alpha_ash, alpha2=alpha_other
		prof.beta  = beta
		prof.alpha = alpha
		prof.alpha_ash = alpha_ash
		prof.alpha_oth = alpha_other
		pinfo.inv_type  = _ash_
		pinfo.after_dep = afterdep
		pinfo.aerosol   = 1
		lr = ash_lr
		aerflag = 'A'
		aeryes = 1
		if (~array_equal(pinfo.f_idx, pinfo.p_idx)) then begin
			info_str = string(format='(%"%d) Different ' $
				+ 'Fern/Depol references ' $
				+ '(not recommended for ASH retrieval).")', p)
			printf, lgf, info_str
			refwarn = 1
		endif
	endif

	if (pinfo.totdep && pinfo.aerosol && pinfo.after_dep) then begin
		lid_aerdepol, pinfo, prof, aerdep=aerdepol
		prof.aerdepol = aerdepol
		pinfo.aerdep = 1
	endif

	if (aeryes) then begin
		lid_atm_compute, p, pinfo, prof
		klid = pinfo.klid[0]
		tau  = pinfo.tot_aod
	endif

	if (pinfo.aerok) then okflag = '+'

	info_str = string(p, hhmmss(pinfo.start), hhmmss(pinfo.stop), $
		round(pinfo.alt), round(pinfo.mx_ofn), depolflag, aerflag, $
		okflag, p_norm, klid, iter, lr, tau, format = $
		'(%"%5d) %s-%s %4dm %2dº %s%s%s %9.2E %7.1f %2d %5.1f %6.3f")')
	printf, lgf, info_str
	if (keyword_set(verbose) && verbose GE 2) then print, info_str

	profile[p]  = prof
	profinfo[p] = pinfo
endfor

if (ash && refwarn) then begin
	info_str1 = 'Some profiles have different Fernald and Depolar. ' $
		+ 'reference heights (see log).'
	info_str2 = 'This is not recommended for ASH retrieval!'
	printf, lgf, [info_str1, info_str2]
	printf, info, [info_str1, info_str2]
	message, info_str1, /continue
	message, info_str2, /continue
endif

idx = where(profinfo[first:last].aerosol $
	AND profinfo[first:last].inv_type EQ _digi_, cnt)
idx += first
if (digi && cnt GT 0) then begin
	avg_lr   = mean(profinfo[idx].d_lidratio)
	min_lr   = min(profinfo[idx].d_lidratio, max=max_lr)
	min_tau  = min(profinfo[idx].d_aod, max=max_tau)
	min_iter = min(profinfo[idx].d_iter, max=max_iter)

	info_str = string(cnt, avg_lr, min_lr, max_lr, min_tau, max_tau, $
		min_iter, max_iter, format='(%"Digi (%d profiles): ' $
		+ 'Avg LR: %0.1f [%0.1f:%0.1f]; OD: %0.3f:%0.3f; Iter: %d:%d")')
	printf, lgf, info_str
	printf, info, info_str
	if (keyword_set(verbose)) then print, info_str
endif


free_lun, info
free_lun, lgf


end

