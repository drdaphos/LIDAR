pro lid_layers_remove, profnum, $
	type=type0, layer=layer, lgf=lgf, verbose=verbose


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


if (n_elements(layer) LE 0) then message, 'No layer selected.'

idx = where(layer LT 0 OR layer GE nlayers, cnt)
if (cnt GT 0) then message, 'Invalid layer(s) selected.'


typedef = [_extinc_, _unc_ext_]
if (n_elements(type0) LE 0) then type0 = typedef
nt = n_elements(type0)
type = intarr(nt)
for t=0, nt-1 do type[t]=lid_type_select(type0[t])


for t=0, nt-1 do begin
	typ = type[t]
	for l=0, n_elements(layer)-1 do begin
		lay = layer[l]
		tot = 0
		for p = first, last do begin
			pinfo = profinfo[p]
			prof  = profile[p]
			l_def = (pinfo.layer_idx[1,lay] NE 0L $
			   AND pinfo.layer_idx[1,lay] GE pinfo.layer_idx[0,lay])
			if (~l_def) then continue
			boundaries = prof.height[pinfo.layer_idx[*,lay]]
			min_y = min(boundaries)
			max_y = max(boundaries)
			idx = where(lid_height GE min_y $
				AND lid_height LE max_y, cnt)
			if (cnt GT 0) then case typ of
				_uncorr_  : lid_uncorr[p,idx,*] = _dundef_
				_signal_  : lid_signal[p,idx,*] = _dundef_
				_pr2_     : lid_pr2[p,idx,*]    = _dundef_
				_pr2tot_  : lid_pr2tot[p,idx]   = _dundef_
				_reldep_  : lid_reldep[p,idx]   = _dundef_
				_totdep_  : lid_totdep[p,idx]   = _dundef_
				_aerdep_  : lid_aerdep[p,idx]   = _dundef_
				_extinc_  : lid_extinc[p,idx]   = _dundef_
				_backsc_  : lid_backsc[p,idx]   = _dundef_
				_bratio_  : lid_bratio[p,idx]   = _dundef_
				_ext_ash_ : lid_ash_ext[p,idx]  = _dundef_
				_ext_oth_ : lid_oth_ext[p,idx]  = _dundef_
				_conc_    : lid_conc[p,idx]     = _dundef_
				_unc_ext_ : lid_unc_ext[p,idx]  = _dundef_
			endcase
			tot += cnt
		endfor

		if (tot GT 0) then begin
			info_str = string(format='(%"lid_layers_remove: ' $
				+ 'removed data for level %d: %s")', $
				lay, typetit[typ])
			printf, lgf, info_str
			if (keyword_set(verbose)) then print, info_str
		endif
	endfor
endfor

if (openlog) then free_lun, lgf


end

