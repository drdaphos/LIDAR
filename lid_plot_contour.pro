pro lid_plot_contour, type=type0, chan=chan, alt=show_alt, display=display, $
	ind_variable=ind_variable, trange=trange, yrange=yrange, xrange=xrange,$
	bar_divs=bar_divs, min_value=min_value, bar_format=bar_format, $
	nlevs=nlevs, titvl=titvl, tstart=tstart1, t_ticks=t_ticks, $
	t_minor=t_minor, pos_ticks=pos_ticks, vert_t=vert_t, vert_c=vert_c, $
	title=title, article=article, noaxis=noaxis, landscape=landscape, $
	a_paper=a_paper, palette=palette, processed=processed


@lid_settings.include

openw, lgf, logfln, /get_lun, /append
printf, lgf, '--> LID_PLOT_CONTOUR'

if (n_elements(nprofiles) NE 1 || nprofiles LE 0L) then $
	message, 'No data. lid_data_read must be called first.'

if (n_elements(nheights) NE 1 || nheights LE 0L) then $
	message, 'No gridded data. lid_data_grid must be called first.'


typedef = (keyword_set(processed) ? [_extinc_, _totdep_] : [_pr2_, _reldep_])
if (n_elements(type0) LE 0)         then type0 = typedef
if (n_elements(chan) LE 0)          then chan = 0
if (n_elements(show_alt) NE 1)      then show_alt = 1
if (n_elements(ind_variable) NE 1)  then ind_variable = 'time'
if (n_elements(nlevs) NE 1)         then nlevs = 32
if (n_elements(bar_divs) LE 0)      then bar_divs = [5, 5] $
	else if (n_elements(bar_divs) EQ 1) then bar_divs = [bar_divs,bar_divs]
if (n_elements(landscape) NE 1)     then landscape = default_landscape
if (n_elements(a_paper) NE 1)       then a_paper = 4
if (n_elements(palette) NE 1)       then palette = default_palette
if (n_elements(title) NE 1)         then title = globaltitle

case strlowcase(ind_variable) of
	'time'      : ivar = 0
	'distance'  : ivar = 1
	'latitude'  : ivar = 2
	'longitude' : ivar = 3
endcase

xtit0 = ['Time after midnight (h)', 'Along-track distance (km)', $
	'Latitude', 'Longitude']
xtit  = xtit0[ivar]
ytit  = 'Altitude AMSL (m)'


a_factor = 2.0D ^ ((4 - a_paper) / 2.0D)
c_factor = (a_paper GT 4 ? a_factor : 1.0D)
p_factor = a_factor

if (n_elements(pos_ticks) NE 1) then begin
	pos_ticks = 10 + landscape * 5
	pos_ticks = fix(round(pos_ticks * p_factor))
endif

n_vert = n_elements(vert_t)
if (n_vert GT 0) then begin
	vert_c0 = replicate(255, n_vert)
	vn = min([n_vert, n_elements(vert_c)]) - 1
	if (vn EQ 0) then vert_c0[*] = vert_c $
		else if (vn GE 1) then vert_c0[0:vn] = vert_c[0:vn]
endif


def_xmin =  [_dundef_, _dundef_, 0.0D,    0.0D,    0.0D, 0.0D, 0.0D, $
	0.0D, 0.0D, 1.0D,     0.0D, 0.0D, 0.0D, 0.0D]
def_xmax =  [_dundef_, _dundef_, 2500.0D, 2500.0D, 2.5D, 0.1D, 0.2D, $
	1D-3, 1D-5, _dundef_, 1D-3, 1D-3, 1000.0D, 1D-3]
def_format = ['(E0.2)', '(E0.2)', '(I0)', '(I0)', '(F0.1)', '(F0.3)', $
	'(F0.3)', '(E0.2)', '(E0.2)', '(F0.2)', '(E0.2)', '(E0.2)', $
	'(I0)', '(E0.2)']

xoffset0 = 0.5
yoffset0 = 1.0
xsize0 = 20
ysize0 = 27.5

if (landscape) then begin
	xoffset = xoffset0
	yoffset = yoffset0 + ysize0
	xsize = ysize0
	ysize = xsize0
	xleft = 0.08
	xright = 0.86
	xbarl = 0.96
	xbarr = 0.98
	ybottom = [0.60, 0.17]
	ytop = [0.92, 0.49]
	xletter = 0.94
	yletter = ytop
	ytitl = 0.97
	ybarmarg = 0.04
	yaxmargin = 0.09
	ysignmarg = 0.15
	charsize = 0.85
	pos_t1 = 20
	pos_t2 = 25
endif else begin
	xoffset = xoffset0
	yoffset = yoffset0
	xsize = xsize0
	ysize = ysize0
	xleft = 0.15
	xright = 0.80
	xbarl = 0.94
	xbarr = 0.98
	ybottom = [0.575, 0.13]
	ytop = [0.93, 0.485]
	xletter = 0.90
	yletter = ytop - 0.01
	ytitl = 0.97
	ybarmarg = 0.04
	yaxmargin = 0.07
	ysignmarg = 0.12
	charsize = 1.0
	pos_t1 = 12
	pos_t2 = 17
endelse

xoffset  *= a_factor
yoffset  *= a_factor
xsize    *= a_factor
ysize    *= a_factor
pos_t1   *= p_factor
pos_t2   *= p_factor
charsize *= c_factor

maxplots = 2
charthick = 4
linethick = 4
axischarsize = 1.35 * charsize
barcharsize = 1.2 * charsize
coordcharsize0 = 0.8 * charsize
signcharsize = 0.7 * charsize
xsty = 1

coordcharsize = coordcharsize0
if (pos_ticks GT pos_t2) then coordcharsize *= 0.6 $
	else if (pos_ticks GT pos_t1) then coordcharsize *= 0.75


nt = n_elements(type0)
nc = n_elements(chan)
nplots = max([nt, nc])
nplots = min([nplots, maxplots])
type = intarr(nt)
for i=0, nt-1 do type[i]=lid_type_select(type0[i])
if (nt LT nplots) then type = [type, replicate(type[0], nplots-nt)]
if (nc LT nplots) then chan = [chan, replicate(chan[0], nplots-nc)]

xran0 = dblarr(2,nplots)
xran0[0,*] = def_xmin[type]
xran0[1,*] = def_xmax[type]
for i = 0, min([n_elements(xrange),2*nplots])-1 do xran0[i]=xrange[i]
minv0 = reform(xran0[0,*])
for i = 0, min([n_elements(min_value), nplots])-1 do minv0[i] = min_value[i]
bar_format0 = def_format[type]
for i = 0, min([n_elements(bar_format), nplots])-1 do $
	bar_format0[i] = bar_format[i]

append = '_cntr'
for i=0, nplots-1 do begin
	append += '_' + typeshort[type[i]]
	if (issignal[type[i]]) then append += string(chan[i],format='(%"ch%d")')
endfor
append += '.ps'


if (n_elements(trange) EQ 2) then begin
	tran = long(trange * 3600.0D)
	idx = where(profinfo.start GE tran[0] AND profinfo.stop LE tran[1],nidx)
	if (nidx LE 0) then message, 'No data within trange'
	pstart = idx[0]
	pstop  = idx[nidx-1]
endif else begin
	pstart = 0
	pstop  = nprofiles - 1
	trange = [profinfo[pstart].start, profinfo[pstop].stop] / 3600.0D
endelse


if (n_elements(titvl) EQ 1 && titvl NE 0.0D) then begin
	t1 = floor(profinfo[pstart].start / (3600.0D * titvl))
	t2 = ceil(profinfo[pstop].stop / (3600.0D * titvl))
	if (n_elements(tstart1) EQ 1) then begin
		t2 += (tstart1/double(titvl) - t1)
		t1 = tstart1/double(titvl)
	endif
	nitvl = long(t2-t1)
	tran1 = dblarr(2,nitvl)
	tran1[0,*] = titvl * (t1 + dindgen(nitvl))
	tran1[1,*] = tran1[0,*] + titvl
	pmin = replicate(_lundef_, nitvl)
	pmax = replicate(_lundef_, nitvl)
	for j=0, nitvl-1 do begin
		idx = where(profinfo.time GE tran1[0,j] * 3600.0D $
			AND profinfo.time LE tran1[1,j] * 3600.0D, cnt)
		if (cnt GE 2) then begin
			pmin[j] = max([idx[0]-3, pstart])
			pmax[j] = min([idx[cnt-1]+3, pstop])
		endif
	endfor
endif else begin
	tran1 = trange
	pmin = pstart
	pmax = pstop
	nitvl = 1
endelse


if (n_elements(yrange) EQ 2) then begin
	ysty = 1
	yran = yrange
endif else begin
	ysty = 0
	if (view EQ _nadir_) then begin
		yran = [max([ymin,0]), max(profinfo[pstart:pstop].alt)]
	endif else begin
		yran = [min(profinfo[pstart:pstop].alt), ymax]
	endelse
endelse


data = dblarr(nprofiles, nheights, nplots)

for i=0, nplots-1 do begin
	data[*,*,i] = lid_type_data(type[i], chan=chan[i], /gridded)

	if (dblcomp(xran0[0,i], _dundef_)) then xran0[0,i] = 0
	if (dblcomp(xran0[1,i], _dundef_)) then $
		xran0[1,i] = max(data[pstart:pstop,*,i])
endfor


idx = where(profinfo[1:*].time - profinfo.time GT 3.0D * target_it, cnt)
proftime = replicate(_dundef_, nprofiles + cnt)
profdist = replicate(_dundef_, nprofiles + cnt)
proflat  = replicate(_dundef_, nprofiles + cnt)
proflon  = replicate(_dundef_, nprofiles + cnt)
profalt  = replicate(_dundef_, nprofiles + cnt)
j1 = 0
k1 = 0
for i=0, cnt do begin
	k2 = (i LT cnt ? idx[i] : nprofiles - 1)
	j2 = j1 + (k2 - k1)
	proftime[j1:j2] = profinfo[k1:k2].time / 3600.0D
	profdist[j1:j2] = profinfo[k1:k2].dis  / 1000.0D
	proflat[j1:j2]  = profinfo[k1:k2].lat
	proflon[j1:j2]  = profinfo[k1:k2].lon
	profalt[j1:j2]  = profinfo[k1:k2].alt
	j1 = j2 + 2
	k1 = k2 + 1
endfor


psfln = outfln + append
tvlct, colortable, /get
set_plot, 'ps'
device, /color, landscape=landscape, bits_per_pixel=8, filename=psfln, $
	xoffset=xoffset, yoffset=yoffset, xsize=xsize, ysize=ysize
if (size(palette, /type) EQ 7) then begin
	set_palette, filename=palette, bottom=bottom, top=top, maxlevs=maxlevs
endif else begin
	set_palette, palette, bottom=bottom, top=top, maxlevs=maxlevs
endelse
nlevs = min([maxlevs, nlevs])
!p.multi = [0, 0, maxplots]

for j=0, nitvl-1 do begin
	if (pmin[j] LT 0 || pmax[j] LE pmin[j]) then continue

	np2   = pmax[j]-pmin[j]+1
	data2 = data[pmin[j]:pmax[j],*,*]
	time2 = profinfo[pmin[j]:pmax[j]].time
	dist2 = profinfo[pmin[j]:pmax[j]].dis
	lat2  = profinfo[pmin[j]:pmax[j]].lat
	lon2  = profinfo[pmin[j]:pmax[j]].lon
	it2   = profinfo[pmin[j]:pmax[j]].it
	idis2 = profinfo[(pmin[j]+1):pmax[j]].dis $
		- profinfo[pmin[j]:(pmax[j]-1)].dis
	ilat2 = profinfo[(pmin[j]+1):pmax[j]].lat $
		- profinfo[pmin[j]:(pmax[j]-1)].lat
	ilon2 = profinfo[(pmin[j]+1):pmax[j]].lon $
		- profinfo[pmin[j]:(pmax[j]-1)].lon
	idx   = where(time2[1:*] - time2 GE 0.8D * (it2 + it2[1:*]), cnt)
	np3   = np2 + 2*cnt
	data3 = replicate(_dundef_, np3, nheights, nplots)
	time3 = dblarr(np3)
	dist3 = dblarr(np3)
	lat3  = dblarr(np3)
	lon3  = dblarr(np3)
	p3 = 0
	for p2=0, np2-1 do begin
		data3[p3,*,*] = data2[p2,*,*]
		time3[p3]     = time2[p2]
		dist3[p3]     = dist2[p2]
		lat3[p3]      = lat2[p2]
		lon3[p3]      = lon2[p2]
		++p3
		dummy = where(p2 EQ idx, cnt)
		if (cnt GT 0) then begin
			time3[p3] = time2[p2]   + 0.5D * it2[p2]
			dist3[p3] = dist2[p2]   + 0.5D * idis2[p2]
			lat3[p3]  = lat2[p2]    + 0.5D * ilat2[p2]
			lon3[p3]  = lon2[p2]    + 0.5D * ilon2[p2]
			++p3
			time3[p3] = time2[p2+1] - 0.5D * it2[p2+1]
			dist3[p3] = dist2[p2+1] - 0.5D * idis2[p2]
			lat3[p3]  = lat2[p2+1]  - 0.5D * ilat2[p2]
			lon3[p3]  = lon2[p2+1]  - 0.5D * ilon2[p2]
			++p3
		endif
	endfor


	for i=0, nplots-1 do begin
		!p.multi[0] = (maxplots - i) MOD maxplots
		maxdata = max(data3[*,*,i], min=mindata)
		if (mindata EQ maxdata) then continue

		xran = xran0[*,i]
		minv = minv0[i]
		levs = xran[0] + (xran[1]-xran[0]) * dindgen(nlevs) / nlevs
		cols = bottom + bytscl(indgen(nlevs), top=top-bottom)

		gtit = typetit[type[i]]
		if (issignal[type[i]]) then $
			gtit += string(format='(%" - channel %d")', chan[i])

		case ivar of
			0:  begin
				tran2 = tran1[*,j]
				tvar  = time3 / 3600.0D
				axistvar = profinfo.time / 3600.0D
				proftvar = proftime
			    end

			1:  begin
				tvar = dist3 / 1000.0D
				axistvar = profinfo.dis / 1000.0D
				proftvar = profdist
			    end

			2:  begin
				tvar = lat3
				axistvar = profinfo.lat
				proftvar = proflat
			    end

			3:  begin
				tvar = lon3
				axistvar = profinfo.lon
				proftvar = proflon
			    end
		endcase

		; the following code allows single profiles to be
		; represented and gives the plot a 'pixelated' look

		avgtvar = mean(tvar[1:*]-tvar)
		delta = 0.2 * avgtvar
		data4 = replicate(_dundef_, 2*np3, nheights, nplots)
		tvar4 = dblarr(2*np3)
		for k=0, np3-1 do begin
			data4[2*k,*,*]   = data3[k,*,*]
			data4[2*k+1,*,*] = data3[k,*,*]
		endfor
		for k=1, np3-1 do tvar4[2*k]   = mean(tvar[(k-1):k]) + delta 
		for k=0, np3-2 do tvar4[2*k+1] = mean(tvar[k:(k+1)]) - delta
		tvar4[0]       = tvar[0] - avgtvar/2.0 + delta
		tvar4[2*np3-1] = tvar[np3-1] + avgtvar/2.0 - delta

		if (keyword_set(article)) then gtit = ''

		; data3 to be used for a non-pixelated (interpolated) plot
		;contour, data3[*,*,i], tvar, lid_height, $
		contour, data4[*,*,i], tvar4, lid_height, $
			min_value=minv[0], levels = levs, c_colors = cols, $
			/cell_fill, xrange=tran2, yrange=yran, $
			xstyle=xsty, ystyle=ysty, title=gtit, xtitle=xtit, $
			ytitle=ytit, ytickformat='(i)', thick=linethick, $
			xthick=linethick, ythick=linethick, $
			charthick=charthick, charsize=charsize, $
			xcharsize=axischarsize, ycharsize=axischarsize, $
			position=[xleft,ybottom[i],xright,ytop[i]], $
			xticks=t_ticks, xminor=t_minor

		tran0 = !x.crange
		yran0 = !y.crange

		if (show_alt) then oplot, proftvar, profalt, $
			thick=linethick, min_value=ymin

		for k=0, n_vert-1 do oplot, [vert_t[k],vert_t[k]], $
			yran0, thick=2*linethick, color=vert_c0[k]

		colorbar, range=xran, min_value=minv[0], $
			divisions=bar_divs[i], minor=5, /vertical, $
			bottom=bottom, ncolors = top-bottom+1, $
			linethick=linethick, charthick=charthick, $
			charsize=barcharsize, format=bar_format0[i], $
			position=[xbarl ,ybottom[i]+ybarmarg, $
			xbarr, ytop[i]-ybarmarg]
	endfor

	if (keyword_set(article) && nplots GT 1) then for i=0, nplots-1 do begin
		lett = string(byte(_a_charcode_ + i))
		xyouts, xletter, yletter[i], '(!8' + lett + '!3)', $
			charsize=axischarsize, charthick=charthick, /normal
	endfor

	if (~keyword_set(article)) then begin
		xyouts, 0.5, ytitl, title, alignment=0.5, $
			charsize=barcharsize, charthick=charthick, /normal
		xyouts, 0.5, ybottom[i-1]-ysignmarg, bottomline, alignment=0.5,$
			charsize=signcharsize, charthick=charthick, /normal
	endif

	if (~keyword_set(noaxis)) then begin
		axisdraw, axistvar, profinfo.lat, profinfo.lon, $
			ypos=ybottom[i-1]-yaxmargin, reverselines=0, $
			nticks=pos_ticks, minor=1, charsize=coordcharsize, $
			charthick=charthick, linethick=linethick, /decimal
	endif
endfor


tvlct, colortable
portrait = ~landscape
;makegif = 1
@lid_plot_cleanup.include


end
