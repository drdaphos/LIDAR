pro lid_concentration, profnum, kext=kext, fc=fc, $
	from_ext=from_ext, from_ash=from_ash, from_oth=from_oth


@lid_settings.include

openw, lgf, logfln, /get_lun, /append
printf, lgf, '--> LID_CONCENTRATION'

openw, info, infofln, /get_lun, /append
printf, info, ''


nfrom = keyword_set(from_ext) + keyword_set(from_ash) + keyword_set(from_oth)
if (nfrom LE 0) then from_ext = 1 $
	else if (nfrom GT 1) then message, 'Incompatible ''from'' keywords'

if (keyword_set(from_ext)) then begin
	fromname = 'aerosol extinction'
endif else if (keyword_set(from_ash)) then begin
	fromname = 'ash extinction'
endif else begin
	fromname = 'other extinction'
endelse

if (n_elements(kext) NE 1)  then kext = default_kext
if (n_elements(fc) NE 1)    then fc = default_fc

keff = kext / fc

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


info_str = string(format='(%"lid_concentration: computing concentration for' $
	+ ' profiles %d-%d")', first, last)
info_str = [info_str, $
	string(format='(%"From %s (effective Kext = %0.2f m2/g)")', $
	fromname, keff)]
printf, lgf, info_str, format='(a)'
printf, info, info_str, format='(a)'
if (keyword_set(verbose)) then print, info_str, format='(a)'


for p = first, last do begin
	pinfo = profinfo[p]
	prof  = profile[p]

	if (keyword_set(from_ext)) then begin
		alpha = prof.alpha
	endif else if (keyword_set(from_ash)) then begin
		alpha = prof.alpha_ash
	endif else if (keyword_set(from_oth)) then begin
		alpha = prof.alpha_oth
	endif else begin
		message, 'Undefined ''from''...'
	endelse

	prof.conc  = 1.0D6 * alpha / keff
	pinfo.conc = 1

	profile[p]  = prof
	profinfo[p] = pinfo
endfor

free_lun, info
free_lun, lgf

end
