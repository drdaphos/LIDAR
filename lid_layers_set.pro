pro lid_layers_set, profnum, lgf, verbose=verbose, $
	ok=aerok, lr=f_lidratio, p_hgt=p_hgt, p_cal=p_cal, $
	f_hgt=f_hgt, f_br=f_br, f_alpha=f_alpha, $
	d_hgt=d_hgt, d_br=d_br, d_alpha=d_alpha, $
	lsf=lsf, ct=ct, aerosol=aerosol


@lid_settings.include


openlog = (n_elements(lgf) NE 1)
if (openlog) then openw, lgf, logfln, /get_lun, /append

if (n_elements(nprofiles) NE 1 || nprofiles LE 0L) then $
	message, 'No data. lid_data_read must be called first.'


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

if (n_elements(f_alpha) GT 0 && n_elements(f_br) GT 0) then $
	message, 'f_alpha and f_br: incompatible options.'

if (n_elements(d_alpha) GT 0 && n_elements(d_br) GT 0) then $
	message, 'd_alpha and d_br: incompatible options.'


info_str = string(format='(%"lid_layers_set: manually setting the ' $
	+ 'following for profiles %d-%d")', first, last)
printf, lgf, info_str
if (keyword_set(verbose)) then print, info_str

info_str = strarr(20)
k = 0

if (n_elements(aerok) EQ 1) then begin
	aerok0 = (aerok NE 0)
	profinfo[first:last].aerok = aerok0
	info_str[k++] = string(format='(%"  Aerok Flag: %d")', aerok0)
endif

if (n_elements(f_lidratio) EQ 1) then begin
	profinfo[first:last].f_lidratio = f_lidratio
	info_str[k++] = string(format='(%"  Lidar Ratio: %6.1f")', f_lidratio)
endif

np = n_elements(p_hgt)
if (np GE 1) then begin
	p_hgt0 = ascending(np GT 1 ? p_hgt[0:1] : $
		[p_hgt-range_res/2.0D, p_hgt+range_res/2.0D])
	if (np EQ 1 && p_hgt EQ 0) then p_hgt0 = [0,0]
	info_str[k++] = string(format='(%"  Depol cal range: %d-%d m")', $
		round(p_hgt0))
	np = 1
endif

if (n_elements(p_cal) EQ 1) then begin
	profinfo[first:last].p_cal = p_cal
	info_str[k++] = string(format='(%"  Depol cal const: %8.5f")', p_cal)
endif

nf = n_elements(f_hgt)
if (nf GE 1) then begin
	f_hgt0 = ascending(nf GT 1 ? f_hgt[0:1] : $
		[f_hgt-range_res/2.0D, f_hgt+range_res/2.0D])
	if (nf EQ 1 && f_hgt EQ 0) then f_hgt0 = [0,0]
	info_str[k++] = string(format='(%"  Fernald ref height: %d-%d m")', $
		round(f_hgt0))
	nf = 1
endif

if (n_elements(f_br) EQ 1) then begin
	profinfo[first:last].f_br = f_br
	info_str[k++] = string(format='(%"  Fernald ref br: %6.3f")', f_br)
endif

f_alpha_flag = (n_elements(f_alpha) EQ 1)
if (f_alpha_flag) then info_str[k++] = string(f_alpha, $
	format='(%"  Fernald ref alpha aerosol: %0.1f Mm-1 (uses LR)")')

d_alpha_flag = (n_elements(d_alpha) EQ 1)
if (d_alpha_flag) then info_str[k++] = string(d_alpha, $
	format='(%"  Digirolamo ref alpha aerosol: %0.1f Mm-1 (uses LR)")')

nd = n_elements(d_hgt)
if (nd GE 1) then begin
	d_hgt0 = ascending(nd GT 1 ? d_hgt[0:1] : $
		[d_hgt-range_res/2.0D, d_hgt+range_res/2.0D])
	if (nd EQ 1 && d_hgt EQ 0) then d_hgt0 = [0,0]
	info_str[k++] = string(format='(%"  Digirolamo ref height: %d-%d m")', $
		round(d_hgt0))
	nd = 1
endif

if (n_elements(d_br) EQ 1) then begin
	profinfo[first:last].d_br = d_br
	info_str[k++] = string(format='(%"  Digirolamo ref br: %6.3f")', d_br)
endif

if (n_elements(lsf) EQ 1) then begin
	profinfo[first:last].lsf = lsf
	info_str[k++] = string(format='(%"  Surface: %d m")', lsf)
endif

nc = min([n_elements(ct), nclouds])
if (nc GE 1) then begin
	info_str[k] = 'Cloud top heights (m):'
	for i=0, nc-1 do $
		info_str[k] += string(format='(%"  %d")', round(ct[i]))
	++k
endif

na = min([n_elements(aerosol)/2, nlayers])
if (na GE 1) then begin
	aerosol0 = dblarr(2,nlayers)
	info_str[k] = 'Aerosol layers (m):'
	for i=0, na-1 do begin
		aerosol0[*,i] = ascending([aerosol[2*i], aerosol[2*i+1]])
		info_str[k] += string(format='(%"  %d-%d")', $
			round(aerosol0[*,i]))
	endfor
	++k
endif


if (np || nf || nd || nc GT 0 || na GT 0 $
   || f_alpha_flag || d_alpha_flag) then begin
	for p = first, last do begin
		pinfo = profinfo[p]
		prof  = profile[p]

		if (np) then begin
			idx = where(prof.range GE overlap $
				AND prof.height GE p_hgt0[0] $
				AND prof.height LE p_hgt0[1], cnt)
			if (cnt GT 0) then pinfo.p_idx = [idx[0], idx[cnt-1]]
			if (array_equal(p_hgt0, [0,0])) then pinfo.p_idx = [0,0]
		endif

		if (nf) then begin
			idx = where(prof.range GE overlap $
				AND prof.height GE f_hgt0[0] $
				AND prof.height LE f_hgt0[1], cnt)
			if (cnt GT 0) then pinfo.f_idx = [idx[0], idx[cnt-1]]
			if (array_equal(f_hgt0, [0,0])) then pinfo.f_idx = [0,0]
		endif

		if (nd) then begin
			idx = where(prof.range GE overlap $
				AND prof.height GE d_hgt0[0] $
				AND prof.height LE d_hgt0[1], cnt)
			if (cnt GT 0) then pinfo.d_idx = [idx[0], idx[cnt-1]]
			if (array_equal(d_hgt0, [0,0])) then pinfo.d_idx = [0,0]
		endif

		for i=0, nc-1 do begin
			idx = where(prof.height GE ct[i] - pinfo.vres/2.0D $
				AND prof.height LE ct[i] + pinfo.vres/2.0D, cnt)
			if (ct[i] NE 0 && cnt GT 0) then $
				pinfo.ct_idx[i] = idx[0]
			if (ct[i] EQ 0) then pinfo.ct_idx[i] = 0
		endfor

		for i=0, na-1 do begin
			idx = where(prof.height GE aerosol0[0,i] $
				AND prof.height LE aerosol0[1,i], cnt)
			if (~array_equal(aerosol0[*,i], [0L,0L]) $
				&& cnt GT 0) then $
					pinfo.layer_idx[*,i] $
						= [idx[0], idx[cnt-1]]
		endfor

		if (f_alpha_flag && pinfo.f_lidratio NE 0 $
		   && pinfo.f_idx[1] NE 0 $
		   && pinfo.f_idx[1] GE pinfo.f_idx[0]) then begin
			betamol = prof.mol_beta[mean(pinfo.f_idx)]
			pinfo.f_br = 1.0D $
				+ 1D-6 * f_alpha / (pinfo.f_lidratio*betamol)
		endif

		if (d_alpha_flag && pinfo.f_lidratio NE 0 $
		   && pinfo.d_idx[1] NE 0 $
		   && pinfo.d_idx[1] GE pinfo.d_idx[0]) then begin
			betamol = prof.mol_beta[mean(pinfo.d_idx)]
			pinfo.d_br = 1.0D $
				+ 1D-6 * d_alpha / (pinfo.f_lidratio*betamol)
		endif

		profinfo[p] = pinfo
	endfor
endif

if (k GT 0) then begin
	printf, lgf, info_str[0:(k-1)], format='(%"%s")'
	if (keyword_set(verbose)) then print, info_str[0:(k-1)],format='(%"%s")'
endif else begin
	info_str = 'lid_layers_set: Nothing to set'
	printf, lgf, info_str
	message, info_str, /continue
endelse

if (openlog) then free_lun, lgf


end

