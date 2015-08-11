pro lid_preview_processed, profnum, type, inv_type, xran=xran, yran=yran, $
	slope_method=slope_method, show_adiacent=show_adiacent


@lid_settings.include


if (n_elements(nprofiles) NE 1 || nprofiles LE 0L) then $
	message, 'No data. lid_data_read must be called first.'


xsiz = 640
ysiz = 480
wnum = 2

if (n_elements(profnum) NE 1) then profnum = 0
if (n_elements(yran) NE 2) then yran = [ymin, ymax]

pdelta = [-1, 0, 1]
pcol   = [15, 5, 23]
pcur   = 1
if (profnum EQ 0) then begin
	pdelta = pdelta[1:*]
	pcol   = pcol[1:*]
	pcur   = 0
endif else if (profnum EQ nprofiles-1) then begin
	pdelta = pdelta[0:1]
	pcol   = pcol[0:1]
endif
if (~keyword_set(show_adiacent)) then begin
	pdelta = 0
	pcol = 5
	pcur = 0
endif

pnum = profnum + pdelta
npnum = n_elements(pnum)

pinfo = profinfo[pnum]
prof  = replicate(profile[profnum], npnum)
for i=0, npnum-1 do prof[i] = profile[pnum[i]]

_p_depol_   = 0
_p_fern_al_ = 1
_p_digi_al_ = 2
_p_fern_br_ = 3
_p_digi_br_ = 4

type = lid_type_select(type, [0,0,0,0,0,1,0,1,0,1])
if (type EQ _totdep_) then begin
	plot_type = _p_depol_
endif else if (type EQ _extinc_) then begin
	plot_type = (inv_type EQ _fern_ ? _p_fern_al_ : _p_digi_al_)
endif else begin
	plot_type = (inv_type EQ _fern_ ? _p_fern_br_ : _p_digi_br_)
endelse

slope_method = (keyword_set(slope_method) $
	&& (type EQ _extinc_ || type EQ _bratio_))

xran0 = [[0.0D,0.2D], [0.0D, 500.0D], [0.0D, 500.0D], $
	[1.0D, 2.0D], [1.0D, 2.0D]]
isdef = [[(pinfo.p_idx[1] NE 0L AND pinfo.p_idx[1] GE pinfo.p_idx[0] $
	AND pinfo.p_cal NE 0.0D)], $
	[(pinfo.f_idx[1] NE 0L AND pinfo.f_idx[1] GE pinfo.f_idx[0] $
	AND pinfo.f_br NE 0.0D AND pinfo.f_lidratio NE 0.0D)], $
	[(pinfo.f_idx[1] NE 0L AND pinfo.f_idx[1] GE pinfo.f_idx[0] $
	AND pinfo.d_idx[1] NE 0L AND pinfo.d_idx[1] GE pinfo.d_idx[0] $
	AND pinfo.f_br NE 0.0D AND pinfo.d_br NE 0.0D)], $
	[(pinfo.f_idx[1] NE 0L AND pinfo.f_idx[1] GE pinfo.f_idx[0] $
	AND pinfo.f_br NE 0.0D AND pinfo.f_lidratio NE 0.0D)], $
	[(pinfo.f_idx[1] NE 0L AND pinfo.f_idx[1] GE pinfo.f_idx[0] $
	AND pinfo.d_idx[1] NE 0L AND pinfo.d_idx[1] GE pinfo.d_idx[0] $
	AND pinfo.f_br NE 0.0D AND pinfo.d_br NE 0.0D)]]
title0 = ['Volume depolarization ratio', 'Fernald extinction', $
	'Digirolamo extinction', 'Fernald BR', 'Digirolamo BR']

device, window_state=window_open
if (~isdef[pcur,plot_type]) then begin
	if (window_open[wnum]) then wdelete, wnum
	message, 'Some needed information has not been set.', /continue
	return
endif

if (n_elements(xran) NE 2) then xran = xran0[*, plot_type]

var = fltarr(maxaltitudes, npnum)
for i=0, npnum-1 do begin
	if (~isdef[i,plot_type]) then continue

	if (plot_type EQ _p_depol_) then begin
		lid_voldepol, pinfo[i], prof[i], voldep=var0
	endif else if (plot_type EQ _p_fern_al_ $
	   || plot_type EQ _p_fern_br_) then begin
		fernald, prof[i].height, prof[i].pr2[*,0], prof[i].mol_beta, $
			pinfo[i].f_idx, pinfo[i].f_br - 1.0D, $
			pinfo[i].f_lidratio, cos_offnadir=pinfo[i].con, $
			alpha=alphaaer, beta=betaaer
	endif else if (plot_type EQ _p_digi_al_ $
	   || plot_type EQ _p_digi_br_) then begin
		digirolamo,prof[i].height,prof[i].pr2[*,0], prof[i].mol_pr2, $
			prof[i].mol_beta, pinfo[i].d_idx, pinfo[i].d_br-1.0D, $
			pinfo[i].f_idx, pinfo[i].f_br - 1.0D, $
			cos_offnadir=pinfo[i].con, alpha=alphaaer, $
			beta=betaaer, ratio=d_lr, tau=tau, ib=ib, $
		 	iterations=iterations, abort=abort, $
			verbose=0, debug=(i EQ pcur)
		if (i EQ pcur) then begin
			if (abort) then begin
				print, profnum, tau, $
					format='(%"%4d) Layer AOD: %7.4f")'
				message, 'Non-converging: aborted.', /continue
			endif else begin
				print, profnum, tau, ib, d_lr, iterations, $
					format='(%"%4d) Layer AOD: %7.4f, ' $
					+ 'IB: %7.4f - Estimated lidar ' $
					+ 'ratio: %7.2f - %d iterations")'
			endelse
		endif
	endif else begin
		message, 'Unknown plot type.'
	endelse

	if (plot_type EQ _p_fern_al_ || plot_type EQ _p_digi_al_) then begin
		var0 = alphaaer * 1E6
	endif else if (plot_type EQ _p_fern_br_ $
	   || plot_type EQ _p_digi_br_) then begin
		var0 = 1.0D + betaaer/prof[i].mol_beta
	endif

	var[*,i] = var0
endfor

case plot_type of
	_p_depol_ : begin
		horln = prof[pcur].height[[pinfo[pcur].p_idx]]
		verln = 0.0D
	end
	_p_fern_al_  : begin
		horln = prof[pcur].height[[pinfo[pcur].f_idx]]
		verln = 0.0D
	end
	_p_digi_al_  : begin
		horln = prof[pcur].height[[pinfo[pcur].f_idx,pinfo[pcur].d_idx]]
		verln = 0.0D
	end
	_p_fern_br_  : begin
		horln = prof[pcur].height[[pinfo[pcur].f_idx]]
		verln = 1.0D
	end
	_p_digi_br_  : begin
		horln = prof[pcur].height[[pinfo[pcur].f_idx,pinfo[pcur].d_idx]]
		verln = 1.0D
	end
endcase

if (~window_open[wnum]) then window, wnum, xsize=xsiz, ysize=ysiz
wset, wnum
wshow, wnum

maxdata = replicate(maxaltitudes-1, npnum)
if (view EQ _nadir_) then begin
	for i=0, npnum-1 do begin
		next_sfc = (pinfo[i].lsf GE ymin ? pinfo[i].lsf : _dundef_)
		for j=0, nclouds-1 do $
			if (pinfo[i].ct_idx[j] GT pinfo[i].f_idx[0]) then $
				next_sfc = max([next_sfc, $
					prof[i].height[pinfo[i].ct_idx[j]]])
		idx = where(prof[i].height GT next_sfc, cnt)
		if (next_sfc GE ymin && cnt GT 0) then maxdata[i] = idx[cnt-1]
	endfor
endif

title = string(title0[plot_type], profnum, format='(%"%s (profile %d)")')
plot, var[*,pcur], prof[pcur].height, min_value=ymin, xrange=xran, $
	yrange=yran, /xstyle, /ystyle, title=title, ytickformat='(i)', /nodata
oplot, xran, [prof[pcur].height[ovl], prof[pcur].height[ovl]], color=13
oplot, [verln, verln], yran
if (plot_type EQ _p_depol_) then $
	oplot, [pinfo[pcur].p_cal, pinfo[pcur].p_cal], yran, color=10
for i=0, n_elements(horln)-1 do oplot, xran, horln[[i,i]], color=10
if (keyword_set(show_adiacent)) then begin
	for i=0, npnum-1 do $
		oplot, var[0:maxdata[i],i], prof[i].height[0:maxdata[i]], $
			color=pcol[i]
	legend, strtrim(string(profnum+pdelta),2), $
		color=pcol, linestyle=0, box=0, /right
endif
if (maxdata[pcur] LT maxaltitudes-1) then oplot, var[maxdata[pcur]:*,pcur], $
	prof[pcur].height[maxdata[pcur]:*], color=3
oplot, var[0:maxdata[pcur],pcur], prof[pcur].height[0:maxdata[pcur]], $
	color=pcol[pcur], thick=1.5

if (slope_method) then begin
	rayleigh, prof[pcur].height, beta=prof[pcur].mol_beta, $
		cos_offnadir=pinfo[pcur].con, tau=taumol, /use_existing_beta
	slope_method, prof[pcur].range, prof[pcur].pr2[*,0], taumol, $
		prof[pcur].mol_beta, alpha=alphaslope, sample=50
	if (type EQ _extinc_) then begin
		oplot, alphaslope*1D6, prof[pcur].height, color=2, thick=2
	endif else begin
		oplot, 1.0D + alphaslope/ $
			(pinfo[pcur].f_lidratio*prof[pcur].mol_beta), $
			prof[pcur].height, color=2, thick=2
	endelse
endif

end

