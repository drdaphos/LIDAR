pro lid_layers_zero, profnum, lgf, verbose=verbose


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


info_str = string(format='(%"lid_layers_zero: zeroing layers ' $
	+ 'for profiles %d-%d")', first, last)
printf, lgf, info_str
if (keyword_set(verbose)) then print, info_str

profinfo[first:last].aerok      = 0
profinfo[first:last].p_idx      = 0L
profinfo[first:last].p_cal      = 0D
profinfo[first:last].f_idx      = 0L
profinfo[first:last].f_br       = 0D
profinfo[first:last].f_lidratio = 0D
profinfo[first:last].d_idx      = 0L
profinfo[first:last].d_br       = 0D
profinfo[first:last].lsf	    = _hundef_
profinfo[first:last].layer_idx  = 0L
profinfo[first:last].ct_idx     = 0L


if (openlog) then free_lun, lgf


end

