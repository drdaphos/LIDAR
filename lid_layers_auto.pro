pro lid_layers_auto, verbose=verbose

@lid_settings.include

openw, lgf, logfln, /get_lun, /append
printf, lgf, '--> LID_LAYERS_AUTO'

if (n_elements(nprofiles) NE 1 || nprofiles LE 0L) then $
	message, 'No data. lid_data_read must be called first.'


n_lay = lonarr(nlayers)
for i=0, nlayers-1 do begin
	nolay = where(profinfo.layer_idx[1,i] LE 0 $
		OR profinfo.layer_idx[1,i] LT profinfo.layer_idx[0,i], $
		n_nolay, ncomplement = cnt)
	n_lay[i] = cnt
endfor

do_autolayers = (total(n_lay) LE 0)

info_str = 'lid_layers_auto: ' + (do_autolayers $
	? 'No aerosol layers set. Setting layer 0 automatically.' $
	: 'Aerosol layers already set. Nothing to be done.')
printf, lgf, info_str
if (keyword_set(verbose)) then print, info_str

if (~do_autolayers) then return

profinfo.layer_idx[0,0] = ovl

for p=0, nprofiles-1 do begin
	pinfo = profinfo[p]
	prof = profile[p]
	maxdata = pinfo.f_idx[1]
	next_sfc = _llarge_
	if (view EQ _nadir_ && pinfo.lsf GE ymin) then begin
		idx = where(prof.height LE pinfo.lsf)
		if (idx[0] GT 0) then next_sfc = idx[0] - 1
	endif
	for i=0, nclouds-1 do if (pinfo.ct_idx[i] GT pinfo.f_idx[0]) then $
		next_sfc = min([next_sfc, pinfo.ct_idx[i]])
	if (next_sfc LT maxaltitudes) then maxdata = next_sfc - 1
	pinfo.layer_idx[1,0] = maxdata
	if (pinfo.layer_idx[1,0] LE pinfo.layer_idx[0,0]) then $
		pinfo.layer_idx[*,0] = 0
	profinfo[p] = pinfo
endfor


free_lun, lgf


end
