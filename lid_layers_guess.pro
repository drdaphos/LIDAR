pro lid_layers_guess, profnum, lgf, noguess=noguess, save=save, $
	depol=depol, fernald=fernald, digi=digi, clouds=clouds, aerok=aerok, $
	verbose=verbose


@lid_settings.include


openlog = (n_elements(lgf) NE 1)
if (openlog) then openw, lgf, logfln, /get_lun, /append

if (n_elements(nprofiles) NE 1 || nprofiles LE 0L) then $
	message, 'No data. lid_data_read must be called first.'

save0 = 0

if (n_elements(profnum) EQ 0) then begin
	lid_layers_read, lgf, read_in
	if (read_in) then goto, skip
	first = 0
	last  = nprofiles-1
	if (openlog) then save0 = 1
endif else if (n_elements(profnum) EQ 1) then begin
	first = profnum
	last  = profnum
endif else begin
	first = profnum[0]
	last  = profnum[1]
endelse

if (n_elements(save) NE 1) then save = save0

if (keyword_set(noguess)) then goto, skip

if (first LT 0 || last GE nprofiles) then $
	message, 'Profiles selected are out of range.'


if (~keyword_set(depol) && ~keyword_set(fernald) && ~keyword_set(digi) $
   && ~keyword_set(clouds) && ~keyword_set(aerok)) then begin
	depol = 1
	fernald = 1
	digi = 1
	clouds = 1
	aerok = 1
endif

guesstype = ''
if (keyword_set(depol))   then guesstype += 'P'
if (keyword_set(fernald)) then guesstype += 'F'
if (keyword_set(digi))    then guesstype += 'D'
if (keyword_set(clouds))  then guesstype += 'C'
if (keyword_set(aerok))   then guesstype += 'O'


info_str = string(format='(%"lid_layers_guess: Applying first guess ' $
	+ 'of layers for profiles %d-%d: %s")', first, last, guesstype)
printf, lgf, info_str
if (keyword_set(verbose)) then print, info_str


cloud_incr_idx = long(cloud_incr_dist / range_res)
cloud_dist_idx = long(cloud_distance / range_res)
rayl_itvl_idx  = long(rayl_itvl / range_res)
n_rayl_adj2    = 5
n_rayl_adj3    = 5
normidx = [2*ovl, 1500]


for p=first, last do begin
	pinfo = profinfo[p]
	prof  = profile[p]
	pinfo2 = pinfo
	ch0 = reform(prof.pr2[*,0])
	ch1 = reform(prof.pr2[*,1])
	knorm = mean(ch0[normidx[0]:normidx[1]]/ch1[normidx[0]:normidx[1]])
	ch1 *= knorm
	mol = prof.mol_pr2
	hgt = prof.height
	ran = prof.range
	pinfo.aerok = 0
	pinfo.lsf = _hundef_
	if (pinfo.f_lidratio EQ 0.0D) then pinfo.f_lidratio = default_lr
	pinfo.p_idx = [0L, 0L]
	pinfo.f_idx = [0L, 0L]
	pinfo.d_idx = [0L, 0L]
	pinfo.ct_idx = lonarr(nclouds)

	; search cloud tops and surface return

	idx = cloud_incr_idx + where(ch0[cloud_incr_idx:*] GE cloud_threshold $
		AND ch0[cloud_incr_idx:*] GE cloud_incr_fact * ch0[0:*] $
		AND ran[cloud_incr_idx:*] GT overlap, cnt)
	if (cnt GT 0) then begin
		idx2 = lonarr(cnt)
		j = 0
		idx2[j++] = idx[0]
		for i=1, cnt-1 do $
			if (idx[i] GE idx[i-1] + cloud_dist_idx) then $
				idx2[j++] = idx[i]
		cnt = j
		idx = idx2[0:(cnt-1)]
		for i=0, cnt-1 do begin
			sig0 = ch0[idx[i]-cloud_incr_idx]
			sig = reverse(ch0[(idx[i]-cloud_incr_idx):idx[i]])
			idx2 = where(sig LE 1.5*sig0, cnt2)
			if (cnt2 GT 0) then idx[i] -= idx2[0]
		endfor
		cldidx = idx
		cldalt = hgt[cldidx]
	endif
	ncld   = cnt

	if (view EQ _nadir_ && cnt GT 0) then begin
		if (pinfo.osf GE ymin) then begin
			smin = pinfo.osf - surf_oro_diff
			smax = pinfo.osf + surf_oro_diff
		endif else begin
			smin = surf_min_hgt
			smax = surf_max_hgt
		endelse
		idx = where(cldalt LE smax, cnt)
		if (cnt GT 0) then begin
			shgt = cldalt[idx[0]]
			if (shgt GE smin) then pinfo.lsf = shgt
			ncld -= cnt
			if (ncld GT 0) then begin
				cldidx = cldidx[0:(ncld-1)]
				cldalt = cldalt[0:(ncld-1)]
			endif
		endif
	endif

	if (ncld GT 0) then begin
		nc = min([ncld, nclouds]) - 1
		pinfo.ct_idx[0:nc] = cldidx[0:nc]
	endif

	; accept/reject based on geometry

	ok_alt = (view NE _nadir_ || $
		pinfo.alt GE max([pinfo.osf, 0.0D]) + min_process_alt)
	ok_ofn = (pinfo.mx_ofn LE max_offnadir)
	pinfo.aerok = (ok_alt && ok_ofn)

	; search best Rayleigh scattering intervals

	if (view EQ _nadir_) then begin
		far_alt = max([pinfo.lsf, pinfo.osf, 0.0D]) + rayl_sfc_margin
	endif else begin
		far_alt = ymax
	endelse
	idxmax = long(min([abs(pinfo.alt - far_alt) / pinfo.vres, $
		rayl_search_ran / pinfo.res]))
	idxmin = ovl
	rayl_bad_idx = rayl_near_bad / pinfo.res
	ndiv0 = double(idxmax - idxmin) / rayl_itvl_idx
	ndiv = long(round(ndiv0))
	if (ndiv LE 0) then continue

	rayl_itvl_idx0 = (idxmax - idxmin) / ndiv
	ifit1 = lonarr(2, ndiv)
	test1 = dblarr(3, ndiv)
	for k=0, ndiv-1 do begin
		i1 = idxmin + rayl_itvl_idx0 * k
		i2 = i1 + rayl_itvl_idx0 - 1
		ifit1[*,k] = [i1, i2]
		test_rayl, ch0, ch1, mol, ifit1[*,k], idxmax, $
			rayl_itvl_idx, rayl_bad_idx, tst
		test1[*,k] = tst
	endfor
	dfit1 = sort(test1[0,*])
	ffit1 = sort(test1[1,*])
	didx1 = ifit1[*,dfit1[0]]
	fidx1 = ifit1[*,ffit1[0]]
	
	ifit2 = lonarr(2, n_rayl_adj2, 2)
	test2 = dblarr(3, n_rayl_adj2, 2)
	shift2 = 3 * rayl_itvl_idx0 / (2 * n_rayl_adj2)
	for k=0, n_rayl_adj2-1 do begin
		delta2 = (k - n_rayl_adj2 / 2) * shift2
		ifit2[*,k,0] = didx1 + delta2
		ifit2[*,k,1] = fidx1 + delta2
		for i=0,1 do begin
			test_rayl, ch0, ch1, mol, ifit2[*,k,i], $
				idxmax, rayl_itvl_idx, rayl_bad_idx, tst
			test2[*,k,i] = tst
		endfor
	endfor
	dfit2 = sort(test2[0,*,0])
	ffit2 = sort(test2[1,*,1])
	didx2 = ifit2[*,dfit2[0],0]
	fidx2 = ifit2[*,ffit2[0],1]

	didx  = didx2
	dtst  = test2[*,dfit2[0],0]
	fidx  = fidx2
	ftst  = test2[*,ffit2[0],1]

	ifitp = [[didx], [fidx]]
	testp = [[dtst], [ftst]]
	pfit  = sort(testp[2,*])
	pidx  = ifitp[*,pfit[0]]

	; error-check on Rayleigh scattering intervals

	if ((pidx[0] NE 0 || pidx[1] NE 0) && pidx[0] LE ovl) $
		then pidx = [0L,0L]

	if ((fidx[0] NE 0 || fidx[1] NE 0) && fidx[0] LE ovl) $
		then fidx = [0L,0L]

	if ((didx[0] NE 0 || didx[1] NE 0) $
	   && (fidx[0] LE ovl || fidx[0] LE didx[1])) $
		then didx = [0L,0L]

	pinfo.d_idx = didx
	if (pinfo.d_br EQ 0.0D) then pinfo.d_br = default_d_ref

	pinfo.f_idx = fidx
	if (pinfo.f_br EQ 0.0D) then pinfo.f_br = default_f_ref

	pinfo.p_idx = pidx
	if (pinfo.p_cal EQ 0.0D) then pinfo.p_cal = default_caldr

	if (keyword_set(depol)) then begin
		pinfo2.p_idx = pinfo.p_idx
		pinfo2.p_cal = pinfo.p_cal
	endif

	if (keyword_set(fernald)) then begin
		pinfo2.f_idx = pinfo.f_idx
		pinfo2.f_br  = pinfo.f_br
		pinfo2.f_lidratio = pinfo.f_lidratio
	endif

	if (keyword_set(digi)) then begin
		pinfo2.d_idx = pinfo.d_idx
		pinfo2.d_br  = pinfo.d_br
	endif

	if (keyword_set(clouds)) then begin
		pinfo2.ct_idx = pinfo.ct_idx
		pinfo2.lsf    = pinfo.lsf
	endif

	if (keyword_set(aerok)) then begin
		pinfo2.aerok = pinfo.aerok
	endif

	profinfo[p] = pinfo2
endfor


if (save) then lid_layers_save, lgf, verbose=0


skip:
if (openlog) then free_lun, lgf


end
