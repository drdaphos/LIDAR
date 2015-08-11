pro lid_layers_slopeset, profnum, lgf, verbose=verbose, $
	fernald=fernald, digirolamo=digirolamo

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

if (n_elements(fernald) EQ 0)    then fernald=1
if (n_elements(digirolamo) EQ 0) then digirolamo=0
if ((~fernald) && (~digirolamo)) then message, 'Nothing to set.'

aerflag = ''
if (fernald)    then aerflag += 'F'
if (digirolamo) then aerflag += 'D'

info_str = string(format='(%"lid_layers_slopeset: attempting ' $
	+ 'slope layers set (%s) for profiles %d-%d")', aerflag, first, last)
printf, lgf, info_str
if (keyword_set(verbose)) then print, info_str

n_fern = 0
n_digi = 0

for p = first, last do begin
	pinfo = profinfo[p]
	prof  = profile[p]

	if (pinfo.f_lidratio EQ 0.0D) then continue
	f_def = (pinfo.f_idx[1] NE 0L AND pinfo.f_idx[1] GE pinfo.f_idx[0])
	d_def = (pinfo.d_idx[1] NE 0L AND pinfo.d_idx[1] GE pinfo.d_idx[0])
	rayleigh, prof.height, beta=prof.mol_beta, cos_offnadir=pinfo.con, $
		tau=taumol, /use_existing_beta
	slope_method, prof.range, prof.pr2[*,0], taumol, prof.mol_beta, $
		alpha=alphaslope, sample=50

	if (fernald && f_def) then begin
		f_mol      = prof.mol_beta[mean([pinfo.f_idx])]
		f_alpha    = mean(alphaslope[pinfo.f_idx[0]:pinfo.f_idx[1]])
		pinfo.f_br = 1.0D + f_alpha / (pinfo.f_lidratio * f_mol)
		++n_fern
	endif

	if (digirolamo && d_def) then begin
		d_mol      = prof.mol_beta[mean([pinfo.d_idx])]
		d_alpha    = mean(alphaslope[pinfo.d_idx[0]:pinfo.d_idx[1]])
		pinfo.d_br = 1.0D + d_alpha / (pinfo.f_lidratio * d_mol)
		++n_digi
	endif

	profinfo[p] = pinfo
endfor

if (fernald) then begin
	info_str = string(format='(%"lid_layers_slopeset: ' $
		+ '%d Fernald references changed.")', n_fern)
	printf, lgf, info_str
	if (keyword_set(verbose)) then print, info_str
endif

if (digirolamo) then begin
	info_str = string(format='(%"lid_layers_slopeset: ' $
		+ '%d Digirolamo references changed.")', n_digi)
	printf, lgf, info_str
	if (keyword_set(verbose)) then print, info_str
endif


if (openlog) then free_lun, lgf

end

