pro lid_plot_info, trange=trange, aod_cutoff=aod_cutoff, $
	track=track, display=display


@lid_settings.include

openw, lgf, logfln, /get_lun, /append
printf, lgf, '--> LID_PLOT_INFO'

if (n_elements(nprofiles) NE 1 || nprofiles LE 0L) then $
	message, 'No data. lid_data_read must be called first.'

if (n_elements(track) LE 0) then track = 1

if (n_elements(aod_cutoff) LE 0) then aod_cutoff = 0.1D

append = '_info.ps'
psfln = outfln   + append

set_plot, 'ps'
device, /color, /landscape, bits_per_pixel=8, filename=psfln
col27

xtit   = 'Time after midnight (h)'
tim    = profinfo.time/3600.0D
ofnidx = where(profinfo.mx_ofn GT max_offnadir, n_ofnidx)
notdep  = where(~profinfo.totdep OR ~profinfo.aerok, n_notdep, $
	ncomplement=n_dep)
notaerdep = where(~profinfo.aerdep OR ~profinfo.aerok, n_notaerdep, $
	ncomplement=n_aerdep)
notaer  = where(~profinfo.aerosol OR ~profinfo.aerok, n_notaer, $
	ncomplement=n_aer)
notdigi = where(~profinfo.aerosol OR profinfo.inv_type NE _digi_ $
	OR ~profinfo.aerok, n_notdigi, ncomplement=n_digi)
notash  = where(~profinfo.aerok OR ~profinfo.aerosol $
	OR profinfo.inv_type NE _ash_, n_notash, ncomplement=n_ash)

if (n_elements(trange) EQ 2) then begin
	tran_idx = where(profinfo.time GE trange[0]*3600.0D $
		AND profinfo.time LE trange[1]*3600.0D, ntran)
endif else begin
	tran_idx = indgen(nprofiles)
	ntran = nprofiles
endelse

altmax = max(profinfo.alt, min=altmin)
idx = where(profinfo[1:*].time - profinfo.time GT 3.0D * target_it, cnt)
proftime = replicate(_dundef_, nprofiles + cnt)
profalt  = replicate(_dundef_, nprofiles + cnt)
j1 = 0
k1 = 0
for i=0, cnt do begin
	k2 = (i LT cnt ? idx[i] : nprofiles - 1)
	j2 = j1 + (k2 - k1)
	proftime[j1:j2] = profinfo[k1:k2].time / 3600.0D
	profalt[j1:j2]  = profinfo[k1:k2].alt
	j1 = j2 + 2
	k1 = k2 + 1
endfor

charthick = 4
linethick = 4
charsize  = 1.15
axischarsize = 1.5
barcharsize = 1.2
symsize = 1.2
map_pos = [0.2,0.,1.,1.]
bar_pos = [0.,0.25,0.03,0.75]
cols = [2, 3, 4, 7, 8, 23]
circle_sym = dindgen(19) * 2.0D * !dpi / 18.0D
usersym, cos(circle_sym), sin(circle_sym), /fill
bottom = 1
top = 254

; Optical Depth

if (n_aer GT 0) then begin
	tau = profinfo.tot_aod
	if (n_notaer GT 0) then tau[notaer] = _dundef_

	plot, tim, tau, min_value=0.0D, ytitle='Aerosol Optical Depth',$
		xrange=trange, xstyle=xstyle, title=globaltitle, xtitle=xtit, $
		charsize=charsize, xcharsize=axischarsize, $
		ycharsize=axischarsize, charthick=charthick, $
		thick=linethick, xthick=linethick, ythick=linethick
	for i=0, nlayers-1 do begin
		tau_l = profinfo.layer_aod[i]
		if (n_notaer GT 0) then tau_l[notaer] = _dundef_
		oplot, tim, tau_l, color=cols[i], min_value=_dpos_
	endfor

	aodran = !y.crange

	plot, tim, tau, min_value=0.0D, ytitle='Aerosol Optical Depth',$
		xrange=trange, xstyle=xstyle, title=globaltitle, xtitle=xtit, $
		charsize=charsize, xcharsize=axischarsize, $
		ycharsize=axischarsize, charthick=charthick, $
		thick=linethick, xthick=linethick, ythick=linethick, ystyle=8
	axis, yaxis=1, yrange=[altmin, altmax], ytitle = 'Altitude (m)', $
		ycharsize=axischarsize, charthick=charthick, $
		ythick=linethick, ytickformat='(i)', /save
	oplot, proftime, profalt, color=2, thick=linethick, min_value=ymin

	altran = !y.crange
	
	lid_plot_track, /aod, xrange=aodran, trange=trange, /map, logfile=lgf

endif



if (n_ash GT 0) then begin
	tau     = profinfo.tot_aod
	tau_ash = profinfo.ash_aod
	tau_oth = profinfo.oth_aod
	if (n_notash GT 0) then begin
		tau[notash]     = _dundef_
		tau_ash[notash] = _dundef_
		tau_oth[notash] = _dundef_
	endif

	plot, tim, tau, min_value=0.0D, ytitle='Aerosol Optical Depth',$
		xrange=trange, xstyle=xstyle, title=globaltitle, xtitle=xtit, $
		charsize=charsize, xcharsize=axischarsize, $
		ycharsize=axischarsize, charthick=charthick, $
		thick=linethick, xthick=linethick, ythick=linethick
	oplot, tim, tau_ash, min_value=0.0D, color=2
	oplot, tim, tau_oth, min_value=0.0D, color=3
	legend, ['Ash', 'Other'], color=[2,3], linestyle=0, $
		charthick=charthick, box=0
endif


; Layer information: depolarization and geometry

n_lay = lonarr(nlayers)
for i=0, nlayers-1 do begin
	nolay = where(profinfo.layer_idx[1,i] LE 0 $
		OR profinfo.layer_idx[1,i] LT profinfo.layer_idx[0,i], $
		n_nolay, ncomplement = cnt)
	n_lay[i] = cnt
endfor

if (total(n_lay) GT 0) then begin
	tdep0 = profinfo.layer_totdep
	if (n_notdep GT 0) then tdep0[*,notdep] = _dundef_
	yymax = max(tdep0)
	plot, tim, profinfo.layer_totdep[0], /nodata, yrange=[0,yymax], $
		ytitle='Volume depolarization ratio', $
		xrange=trange, xstyle=xstyle, title=globaltitle, xtitle=xtit, $
		charsize=charsize, xcharsize=axischarsize, $
		ycharsize=axischarsize, charthick=charthick, $
		thick=linethick, xthick=linethick, ythick=linethick
	for i=0, nlayers-1 do if (n_lay[i] GT 0) then begin
		nolay = where(profinfo.layer_idx[1,i] LE 0 $
			OR profinfo.layer_idx[1,i] LT profinfo.layer_idx[0,i], $
			n_nolay)
		tdep = profinfo.layer_totdep[i]
		if (n_nolay GT 0) then tdep[nolay] = _dundef_
		if (n_notdep GT 0) then tdep[notdep] = _dundef_
		oplot, tim, tdep, color=cols[i], min_value=_dpos_
	endif

	adep0 = profinfo.layer_aerdep
	if (n_notaerdep GT 0) then adep0[*,notaerdep] = _dundef_
	yymax = max(adep0)
	plot, tim, profinfo.layer_aerdep[0], /nodata, yrange=[0,yymax], $
		ytitle='Aerosol depolarization ratio', $
		xrange=trange, xstyle=xstyle, title=globaltitle, xtitle=xtit, $
		charsize=charsize, xcharsize=axischarsize, $
		ycharsize=axischarsize, charthick=charthick, $
		thick=linethick, xthick=linethick, ythick=linethick
	for i=0, nlayers-1 do if (n_lay[i] GT 0) then begin
		nolay = where(profinfo.layer_idx[1,i] LE 0 $
			OR profinfo.layer_idx[1,i] LT profinfo.layer_idx[0,i], $
			n_nolay)
		adep = profinfo.layer_aerdep[i]
		if (n_nolay GT 0) then adep[nolay] = _dundef_
		if (n_notaerdep GT 0) then adep[notaerdep] = _dundef_
		oplot, tim, adep, color=cols[i], min_value=_dpos_
	endif

	aext0 = profinfo.layer_pk_ext
	if (n_notaer GT 0) then aext0[*,notaer] = _dundef_
	yymax = max(aext0)
	plot, tim, profinfo.layer_pk_ext[0], /nodata, yrange=[0,yymax], $
		ytitle='Aerosol peak extinction', $
		xrange=trange, xstyle=xstyle, title=globaltitle, xtitle=xtit, $
		charsize=charsize, xcharsize=axischarsize, $
		ycharsize=axischarsize, charthick=charthick, $
		thick=linethick, xthick=linethick, ythick=linethick
	for i=0, nlayers-1 do if (n_lay[i] GT 0) then begin
		nolay = where(profinfo.layer_idx[1,i] LE 0 $
			OR profinfo.layer_idx[1,i] LT profinfo.layer_idx[0,i], $
			n_nolay)
		aext = profinfo.layer_pk_ext[i]
		if (n_nolay GT 0) then aext[nolay] = _dundef_
		if (n_notaer GT 0) then aext[notaer] = _dundef_
		oplot, tim, aext, color=cols[i], min_value=_dpos_
	endif


	yymax = max([profinfo.layer_pk_hgt + profinfo.layer_pk_fwhm/2.0D, $
		profinfo.layer_hgt + profinfo.layer_dpth/2.0D])

	plot, tim, profinfo.layer_pk_hgt[0], /nodata, yrange=[0,yymax], $
		ytitle='Layer altitude and FWHM (m)', $
		xrange=trange, xstyle=xstyle, title=globaltitle, xtitle=xtit, $
		charsize=charsize, xcharsize=axischarsize, $
		ycharsize=axischarsize, charthick=charthick, $
		thick=linethick, xthick=linethick, ythick=linethick
	oplot, proftime, profalt, linestyle=1, thick=linethick, min_value=ymin
	for i=0, nlayers-1 do if (n_lay[i] GT 0) then begin
		nolay = where(profinfo.layer_idx[1,i] LE 0 $
			OR profinfo.layer_idx[1,i] LT profinfo.layer_idx[0,i], $
			n_nolay)
		peak = profinfo.layer_pk_hgt[i]
		top  = profinfo.layer_pk_hgt[i] + profinfo.layer_pk_fwhm[i]/2.0D
		bott = profinfo.layer_pk_hgt[i] - profinfo.layer_pk_fwhm[i]/2.0D
		if (n_nolay GT 0) then begin
			peak[nolay] = _dundef_
			top[nolay]  = _dundef_
			bott[nolay] = _dundef_
		endif
		if (n_notaer GT 0) then begin
			peak[notaer] = _dundef_
			top[notaer]  = _dundef_
			bott[notaer] = _dundef_
		endif
		oplot, tim, peak, color=cols[i], min_value=_dpos_
		oplot, tim, top,  color=cols[i], min_value=_dpos_
		oplot, tim, bott, color=cols[i], min_value=_dpos_
	endif

	plot, tim, profinfo.layer_hgt[0], /nodata, yrange=[0,yymax], $
		ytitle='Layer height and depth (m)', $
		xrange=trange, xstyle=xstyle, title=globaltitle, xtitle=xtit, $
		charsize=charsize, xcharsize=axischarsize, $
		ycharsize=axischarsize, charthick=charthick, $
		thick=linethick, xthick=linethick, ythick=linethick
	oplot, proftime, profalt, linestyle=1, thick=linethick, min_value=ymin
	for i=0, nlayers-1 do if (n_lay[i] GT 0) then begin
		nolay = where(profinfo.layer_idx[1,i] LE 0 $
			OR profinfo.layer_idx[1,i] LT profinfo.layer_idx[0,i], $
			n_nolay)
		peak = profinfo.layer_hgt[i]
		top  = profinfo.layer_hgt[i] + profinfo.layer_dpth[i]/2.0D
		bott = profinfo.layer_hgt[i] - profinfo.layer_dpth[i]/2.0D
		if (n_nolay GT 0) then begin
			peak[nolay] = _dundef_
			top[nolay]  = _dundef_
			bott[nolay] = _dundef_
		endif
		if (n_notaer GT 0) then begin
			peak[notaer] = _dundef_
			top[notaer]  = _dundef_
			bott[notaer] = _dundef_
		endif
		oplot, tim, peak, color=cols[i], min_value=_dpos_
		oplot, tim, top,  color=cols[i], min_value=_dpos_
		oplot, tim, bott, color=cols[i], min_value=_dpos_
	endif
endif


; Cloud tops
dummy = where(profinfo.ct_idx GT 0, n_cld)

if (n_cld GT 0) then begin
	ct_hgt = replicate(_dundef_, nprofiles, nclouds)
	for p=0, nprofiles-1 do begin
		prof  = profile[p]
		pinfo = profinfo[p]
		idx = where(pinfo.ct_idx GT 0, n_idx)
		if (n_idx GT 0) then $
			ct_hgt[p,idx] = prof.height[pinfo.ct_idx[idx]]
	endfor
	idx = where(ct_hgt GE ymin, n_idx)
	if (n_idx GT 0) then yymax = max(ct_hgt[idx], min=yymin)
	plot, tim, ct_hgt[*,0], /nodata, yrange=[yymin,yymax], $
		ytitle='Cloud ' + (view EQ _nadir_ ? 'top' : 'base') $
		+ ' height (m)', $
		xrange=trange, xstyle=xstyle, title=globaltitle, xtitle=xtit, $
		charsize=charsize, xcharsize=axischarsize, $
		ycharsize=axischarsize, charthick=charthick, $
		thick=linethick, xthick=linethick, ythick=linethick
	for i=0, nclouds-1 do $
		oplot, tim, ct_hgt[*,i], color=cols[i], min_value=ymin
endif


; Digirolamo AOD, Lidar Ratio, and Iterations

if (n_digi GT 0) then begin
	tau = profinfo.d_aod
	if (n_notdigi GT 0) then tau[notdigi] = _dundef_

	plot, tim, tau, /ystyle, min_value=0.0D, ytitle='Digi AOD', $
		xrange=trange, xstyle=xstyle, title=globaltitle, xtitle=xtit, $
		charsize=charsize, xcharsize=axischarsize, $
		ycharsize=axischarsize, charthick=charthick, $
		thick=linethick, xthick=linethick, ythick=linethick
	timran = !x.crange
	oplot, timran, [aod_cutoff, aod_cutoff], color=2

	aodran = !y.crange
	lr = profinfo.d_lidratio
	if (n_notdigi GT 0) then lr[notdigi] = _dundef_

	plot, tim, lr, /ystyle, min_value=0.0D, ytitle='Digi Lidar Ratio', $
		xrange=trange, xstyle=xstyle, title=globaltitle, xtitle=xtit, $
		charsize=charsize, xcharsize=axischarsize, $
		ycharsize=axischarsize, charthick=charthick, $
		thick=linethick, xthick=linethick, ythick=linethick

	plot, tau, lr, /xstyle, /ystyle, min_value=0.0D, xrange=aodran, $
		psym=4, xtitle='Digi AOD', ytitle='Digi Lidar Ratio', $
		title=globaltitle, charsize=charsize, xcharsize=axischarsize, $
		ycharsize=axischarsize, charthick=charthick, $
		thick=linethick, xthick=linethick, ythick=linethick
	lr_ran = !y.crange
	oplot, [aod_cutoff, aod_cutoff], lr_ran, color=2

	simplestat, lr, his_freq, his_x, min_value=0.0D, $
		avg=avglr, std=stdlr, xmin=minlr, xmax=maxlr, med=medlr
	simplestat_plot, his_freq, his_x, avg=avglr, std=stdlr, $
		xmin=minlr, xmax=maxlr, med=medlr, xtitle='Digi Lidar Ratio', $
		title=globaltitle, charsize=charsize, $
		xcharsize=0.8*axischarsize, ycharsize=axischarsize, $
		charthick=charthick, thick=linethick, xtickformat='(f0.1)'

	idx = where(tau GE aod_cutoff, cnt)
	if (cnt GT 1) then begin
		simplestat, lr[idx], his_freq, his_x, min_value=0.0D, $
			avg=avglr, std=stdlr, xmin=minlr, xmax=maxlr, med=medlr
		simplestat_plot, his_freq, his_x, avg=avglr, std=stdlr, $
			xmin=minlr, xmax=maxlr, med=medlr, $
			title=globaltitle, xtitle='Digi Lidar Ratio', $
			charsize=charsize, xcharsize=0.8*axischarsize, $
			ycharsize=axischarsize, charthick=charthick, $
			thick=linethick, xtickformat='(f0.1)'
		xyouts, 0.15, 0.8, /normal, charsize=axischarsize, $
			charthick=charthick, string(aod_cutoff, $
			format='(%"Cutoff at %0.2f Digi-AOD")'), color=2
	endif

	iter = profinfo.d_iter
	if (n_notdigi GT 0) then iter[notdigi] = _undef_

	plot, tim, iter, /ystyle, min_value=0, ytitle='Digi Iterations', $
		xrange=trange, xstyle=xstyle, title=globaltitle, xtitle=xtit, $
		charsize=charsize, xcharsize=axischarsize, $
		ycharsize=axischarsize, charthick=charthick, $
		thick=linethick, xthick=linethick, ythick=linethick
endif


; Lidar Constants

for i=0, nchannels-1 do begin
	parat = profinfo.pa_ratio[i]
	idx = where(parat GE 0.0D, nidx)
	if (nidx GT 0) then begin
		plot, tim, parat, min_value=0.0D, psym=4, $
		ytitle=string(format='(%"PhC / Analog (Ch%d)")', i), $
		xrange=trange, xstyle=xstyle, title=globaltitle, xtitle=xtit, $
		charsize=charsize, xcharsize=axischarsize, $
		ycharsize=axischarsize, charthick=charthick, $
		thick=linethick, xthick=linethick, ythick=linethick

		timeran = !x.crange
	endif
endfor



if (n_aer GT 0) then begin
	for i=0, nchannels-1 do begin
		klid = profinfo.klid[i]
		klid2 = klid
		if (n_notaer GT 0) then klid2[notaer] = _dundef_
		plot, tim, klid2, /nodata, /ystyle, min_value=0.0D, $
			ytitle=string(format='(%"Lidar constant (Ch%d)")', i), $
			xrange=trange, xstyle=xstyle, $
			title=globaltitle, xtitle=xtit, $
			charsize=charsize, xcharsize=axischarsize, $
			ycharsize=axischarsize, charthick=charthick, $
			thick=linethick, xthick=linethick, ythick=linethick
		oplot, tim, klid, color=2, thick=linethick, min_value=0.0D
		oplot, tim, klid2, thick=linethick, min_value=0.0D
	endfor
endif

if (n_dep GT 0) then begin
	pnorm = profinfo.p_norm
	pnorm2 = pnorm
	if (n_notdep GT 0) then pnorm2[notdep] = _dundef_
	plot, tim, pnorm2, /nodata, /ystyle, min_value=0.0D, $
		ytitle='Depolarization calibration (lidar constant ratio)', $
		xrange=trange, xstyle=xstyle, title=globaltitle, xtitle=xtit, $
		charsize=charsize, xcharsize=axischarsize, $
		ycharsize=axischarsize, charthick=charthick, $
		thick=linethick, xthick=linethick, ythick=linethick
	oplot, tim, pnorm, color=2, thick=linethick, min_value=0.0D
	oplot, tim, pnorm2, thick=linethick, min_value=0.0D
endif


; Surface Altitude

surf  = profinfo.lsf
radar = profinfo.rsf
orog  = profinfo.osf

surf2 = surf
if (n_ofnidx GT 0) then surf2[ofnidx] = _hundef_

idx = where(surf GE surf_min_hgt, nidx)
if (nidx GT 0) then begin
	plot, tim, surf, /nodata, /ystyle, min_value=surf_min_hgt, $
		ytitle='Surface altitude AMSL (m)', $
		xrange=trange, xstyle=xstyle, title=globaltitle, xtitle=xtit, $
		charsize=charsize, xcharsize=axischarsize, $
		ycharsize=axischarsize, charthick=charthick, $
		thick=linethick, xthick=linethick, ythick=linethick
	oplot, tim, surf,  color=2, min_value=surf_min_hgt, thick=linethick
	oplot, tim, radar, color=3, min_value=surf_min_hgt, thick=linethick
	oplot, tim, orog,  color=4, min_value=surf_min_hgt, thick=linethick
	oplot, tim, surf2, min_value=surf_min_hgt, thick=linethick
endif


; flight track

if (track) then begin
	lid_plot_track, trange=trange, xrange=timeran, /map, logfile=lgf
	lid_plot_track, /altitude, trange=trange, xrange=altran, $
		/map, logfile=lgf
	fltind = transpose(profinfo.hor_idx)
	plotflightinfo, flno_sub, dd, mth, yy, nprofiles, fltind, hor.tim, $
		hor.alt, hor.lat, hor.lon, hor.ptc, hor.rll, hor.rhg, $
		profinfo.aerok, charsize=charsize, axischarsize=axischarsize, $
		linethick=linethick, charthick=charthick
endif


@lid_plot_cleanup.include


end
