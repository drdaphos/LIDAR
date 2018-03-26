pro iced_data_process, profnum, verbose=verbose
; Fernald processing with 2 lidar ratios


; ICE-D processing parameters

d_lr        = 10	; LR uncertainty
d_ref_rel   = 0.5	; Relative uncertainty on Fernald reference
d_ref_abs   = 30E-6     ; Absolute uncertainty on Fernald reference
lr_dust     = 54	; LR for upper layer (dust)
lr_pbl      = 20	; LR for lower layer (marine)
bound_layer = 0		; determine LR boundary using saved layer 0
bound_l_idx = 0		; determine LR boundary using index 0 for saved layer
transition  = 1000.0	; depth of LR transition (will be made gradual)
; Note: Lidar ratio saved in the layers file will not
;       be used, and the layers data will not be changed


@lid_settings.include

openw, lgf, logfln, /get_lun, /append
printf, lgf, '--> ICED_DATA_PROCESS

openw, info, infofln, /get_lun, /append
printf, info, ''

if (n_elements(nprofiles) NE 1 || nprofiles LE 0L) then $
	message, 'No data. lid_data_read must be called first.'


info_str = string(lr_dust, lr_pbl, format='(%"ICE-D processing ' $
	+ 'with variable LR. Dust: %4.1f. Salt: %4.1f.")')


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

info_str = string(format='(%"Cross-talk computation: ' $
	+ 'Tp=%0.4f Ts=%0.4f Rs=%0.4f Rp=%0.4f")', crosstalk_tp, $
	crosstalk_ts, crosstalk_rs, crosstalk_rp)
printf, lgf, info_str
printf, info, info_str
if (keyword_set(verbose)) then print, info_str


info_str = string(format='(%"Extinction uncertainties: ' $
	+ 'delta_LR=%0.1f, delta_REF=%dMm-1(abs),%d%%(rel)")', $
	d_lr, round(1D6*d_ref_abs), round(d_ref_rel*100.0))
printf, lgf, info_str
printf, info, info_str
if (keyword_set(verbose)) then print, info_str


for p=first, last do begin
	pinfo = profinfo[p]
	if (~pinfo.aerok) then continue
	prof  = profile[p]
	p_norm    = 0.0D
	klid      = 0.0D
	tau       = 0.0D
	iter      = 0
	depolyes  = 0
	aeryes    = 0
	depolflag = '-'
	aerflag   = '-'
	okflag    = '-'

	pinfo.totdep  = 0
	pinfo.aerosol = 0
	pinfo.aerdep = 0

	if (pinfo.p_idx[0] GE ovl && pinfo.p_idx[1] GE pinfo.p_idx[0] $
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

	if (pinfo.f_idx[0] GE ovl && pinfo.f_idx[1] GE pinfo.f_idx[0] $
	   && pinfo.f_br NE 0.0D && pinfo.f_lidratio NE 0.0D) then begin

; set LR profile
		l_def = (pinfo.layer_idx[1,*] NE 0L $
			AND pinfo.layer_idx[1,*] GE pinfo.layer_idx[0,*])
		if (~l_def[bound_layer]) then begin
			message, string(bound_layer, p, format='(%"Layer ' $
				+ '%d undefined for profile %d.")')
		endif
		bound_z = prof.height[pinfo.layer_idx[bound_l_idx,bound_layer]]
		if (bound_z GT 0) then begin
			bound_z1 = min([prof.height[0], bound_z+transition/2.0])
			bound_z2 = max([prof.height[maxaltitudes-1], $
			   bound_z-transition/2.0])
			b_z = [prof.height[0], bound_z1, bound_z2, $
				prof.height[maxaltitudes-1]]
			b_lr = [lr_dust, lr_dust, lr_pbl, lr_pbl]
		endif else begin
			b_z = [prof.height[0], prof.height[maxaltitudes-1]]
			b_lr = [lr_dust, lr_dust]
		endelse
		lr = interpol(b_lr, b_z, prof.height)
;		lr_ref = lr[mean([pinfo.f_idx])]
		lr_ref = mean(lr[pinfo.f_idx[0]:pinfo.f_idx[1]])

; apply Fernald or slope method
		rayleigh, prof.height, beta=prof.mol_beta, $
			cos_offnadir=pinfo.con, tau=taumol, /use_existing_beta
		f_mol = prof.mol_beta[mean([pinfo.f_idx])]
		if (abs(pinfo.f_br-1.0D) LT 1D-6) then begin
			f_br = 1.0D
			slo = 0
		endif else begin
			slo = 1
			slope_method, prof.range, prof.pr2[*,0], taumol, $
				prof.mol_beta, alpha=alphaslope, sample=50
			f_alpha = $
				mean(alphaslope[pinfo.f_idx[0]:pinfo.f_idx[1]])
			f_br = 1.0D + f_alpha / (lr_ref * f_mol)
		endelse
		fernald_var, prof.height, pr2, prof.mol_beta, pinfo.f_idx, $
			f_br-1.0D, lr, cos_offnadir=pinfo.con, $
			beta=beta, alpha=alpha

		prof.beta  = beta
		prof.alpha = alpha
		pinfo.inv_type  = _fern_
		pinfo.after_dep = afterdep
		pinfo.aerosol   = 1
		aerflag = 'F'
		aeryes  = 1

		d_alpha = dblarr(maxaltitudes, 4)
		extref  = (slo ? f_alpha : 0.0)
		d_ref   = max([d_ref_abs, d_ref_rel*extref])
		extref0 = extref + d_ref * [-1, 1, 0, 0]
		if (extref0[0] LT 0.0D) then extref0[0] = 0.0D
		br0 = extref0 / (lr_ref * f_mol)
		lr0 = dblarr(maxaltitudes, 4)
		for i=0, maxaltitudes-1 do lr0[i,*] = lr[i] + d_lr*[0, 0, -1, 1]
		for k=0, 3 do begin
			fernald_var, prof.height, pr2, prof.mol_beta, $
				pinfo.f_idx, br0[k], lr0[*,k], $
				cos_offnadir=pinfo.con, $ 
                       		alpha=alpha0
			d_alpha[*,k] = alpha0 - alpha
		endfor
		for i=0, maxaltitudes-1 do $
			prof.d_alpha[i] = max(abs(d_alpha[i,*]))
		pinfo.unc_aerosol = 1
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


free_lun, info
free_lun, lgf


end

