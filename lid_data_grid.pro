pro lid_data_grid, type=type, double=double, overlap=overl2, $
	ysample=ysample, yrange=yrange, yexisting=yexisting, verbose=verbose


@lid_settings.include

openw, lgf, logfln, /get_lun, /append
printf, lgf, '--> LID_DATA_GRID'

if (n_elements(nprofiles) NE 1 || nprofiles LE 0L) then $
	message, 'No data. lid_data_read must be called first.'

if (n_elements(overl2) EQ 0) then begin
	ovl2 = ovl
endif else if (overl2 EQ 1) then begin
	ovl2 = 0
endif else begin
	ovl2 = long(round(overl2 / range_res))
endelse

type = lid_type_select(type)
if (n_elements(ysample) NE 1) then ysample = range_res * smooth

if (n_elements(yrange) NE 2) then begin
	if (view EQ _nadir_) then begin
		yrange = [ymin, max(profinfo.alt)]
	endif else begin
		yrange = [min(profinfo.alt), ymax]
	endelse
endif

if (keyword_set(double)) then begin
	dtype = 5
	dsize = size_double
endif else begin
	dtype = 4
	dsize = size_float
endelse

if (~keyword_set(yexisting)) then begin
	yrange   = double(yrange)
	ysample  = double(ysample)
	irange   = yrange / ysample
	irange   = [ceil(irange[0]), floor(irange[1])]
	nheights = long(irange[1]-irange[0]+1)

	lid_height    = make_array(type=dtype, nheights)
	lid_height[*] = (irange[0] + dindgen(nheights)) * ysample
	info_str = string(nheights,ysample, yrange, $
		format='(%"lid_height(%d): %5.1fm gridding interval ' $
		+ '(%d:%dm).")')
	printf, lgf, info_str
	if (keyword_set(verbose)) then print, info_str
endif else if (n_elements(nheights) NE 1 || nheights LE 0L $
   || n_elements(lid_height) NE nheights) then begin
	message, 'Pre-existing lid_height array inexistent or inconsistent.'
endif else begin
	info_str = string(nheights, $
		format='(%"Using pre-existing lid_height(%d) array.")')
	printf, lgf, info_str
	if (keyword_set(verbose) && verbose GE 2) then print, info_str
endelse

nchan2 = (issignal[type] ? nchannels : 1)
data = make_array(type=dtype, nprofiles, nheights, nchan2, value=_dundef_)
datasize = n_elements(data) * double(dsize)

for p=0, nprofiles-1 do begin
	pinfo = profinfo[p]
	prof  = profile[p]
	var   = lid_type_data(type, pinfo, prof)

	if ((isaer[type] || type EQ _totdep_ || type EQ _aerdep_) $
		&& ~pinfo.aerok) then continue
	if (type EQ _totdep_ && ~pinfo.totdep) then continue
	if (type EQ _aerdep_ && ~pinfo.aerdep) then continue
	if (isaer[type] && ~pinfo.aerosol)   then continue

	maxdata = (isaer[type] $
		? max([pinfo.f_idx, pinfo.d_idx]) : maxaltitudes-1)

	if ((isaer[type] || type EQ _totdep_ || type EQ _aerdep_) $
	   && view EQ _nadir_) then begin
		next_sfc = (pinfo.lsf GE ymin ? pinfo.lsf : _dundef_)
		for i=0, nclouds-1 do $
			if (pinfo.ct_idx[i] GT pinfo.f_idx[0]) then next_sfc = $
				max([next_sfc, prof.height[pinfo.ct_idx[i]]])
		idx = where(prof.height GT next_sfc, cnt)
		if (next_sfc GE ymin && cnt GT 0) then maxdata = idx[cnt-1]
	endif

	min_h = min(prof.height[ovl2:maxdata], max=max_h)
	idx = where(lid_height GE min_h AND lid_height LE max_h, cnt)
	if (cnt GT 0) then for ch=0, nchan2-1 do $
		data[p,idx,ch] = interpol(var[*,ch],prof.height,lid_height[idx])
endfor


case type of
	_uncorr_  : lid_uncorr  = data
	_signal_  : lid_signal  = data
	_pr2_     : lid_pr2     = data
	_pr2tot_  : lid_pr2tot  = data
	_reldep_  : lid_reldep  = data
	_totdep_  : lid_totdep  = data
	_aerdep_  : lid_aerdep  = data
	_extinc_  : lid_extinc  = data
	_backsc_  : lid_backsc  = data
	_bratio_  : lid_bratio  = data
	_ext_ash_ : lid_ash_ext = data
	_ext_oth_ : lid_oth_ext = data
	_conc_    : lid_conc    = data
	_unc_ext_ : lid_unc_ext = data
endcase


info_str = string(typename[type], nprofiles, nheights, $
	(nchan2 LE 1 ? '' : string(nchan2, format='(%",%d")')), $
	datasize, datasize / (1024L*1024L), $
	format='(%"lid_%s(%d,%d%s):  array size: %d bytes - %5.2f MB.")')
printf, lgf, info_str
if (keyword_set(verbose)) then print, info_str


free_lun, lgf


end

