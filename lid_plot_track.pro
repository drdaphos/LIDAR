pro lid_plot_track, hor_tag=hor_tag, hor_val=hor_val, core_param=core_param, $
	profinfo_tag=profinfo_tag, profinfo_val=profinfo_val, $
	condition=condition, altitude=altitude, aod=aod, sort=sort, $
	trange=trange, yrange=yrange, latrange=latrange, lonrange=lonrange, $
	xrange=xrange, min_value=min_value, smooth=smoo, sample=samp, $
	tracksample=tsamp, bar_divs=bar_divs, bar_format=bar_format, $
	map=show_map, timehgt=show_th, lathgt=show_lath, lonhgt=show_lonh, $
	symsize=symsize, title=title, countries=countries, $
	logfile=lgf, display=display, palette=palette, verbose=verbose


@lid_settings.include


if (n_elements(flno) NE 1 || n_elements(hor) LE 0) then $
	message, 'lid_flight_select and lid_horace_read must be called first.'

openlog = (n_elements(lgf) NE 1)
newplot = openlog

if (openlog) then begin
	openw, lgf, logfln, /get_lun, /append
	printf, lgf, '--> LID_PLOT_TRACK'
endif

if (newplot) then begin
	psfln = outfln + '_track.ps'
	set_plot, 'ps'
	device, /color, /landscape, bits_per_pixel=8, filename=psfln
	!p.multi = 0
endif


if (keyword_set(altitude)) then begin
	hor_tag = 'alt'
	title1 = 'Altitude (m)'
	if (n_elements(bar_format) LE 0) then bar_format = '(f0.1)'
endif


if (keyword_set(aod)) then begin
	if (n_elements(profinfo_tag) LE 0 && n_elements(profinfo_val) LE 0) $
		then profinfo_tag = 'tot_aod'
	if (n_elements(condition) LE 0) $
		then condition = 'profinfo.aerosol AND profinfo.aerok'
	if (n_elements(bar_format) LE 0) then bar_format = '(f0.2)'
	title1 = 'AOD'
endif

if (n_elements(sort) NE 1) then sort = 1

if (n_elements(palette) NE 1) then palette = default_palette


tvlct, colortable, /get
if (size(palette, /type) EQ 7) then begin
        set_palette, filename=palette, bottom=bottom, top=top
endif else begin
        set_palette, palette, bottom=bottom, top=top
endelse

ystyle = 1
tstyle = 1
latstyle = 1
lonstyle = 1

if (n_elements(trange) NE 2) then begin
	trange = [takeoff, landing] / 3600.0
	tstyle = 0
endif
if (n_elements(yrange) NE 2)     then ystyle = 0
if (n_elements(latrange) NE 2)   then latstyle = 0
if (n_elements(lonrange) NE 2)   then lonstyle = 0
if (n_elements(bar_divs) NE 1)   then bar_divs = 5
if (n_elements(symsize) NE 1)    then symsize = 0.8

if (~keyword_set(show_map) && ~keyword_set(show_th) $
   && ~keyword_set(show_lath) && ~keyword_set(show_lonh)) then begin
	show_map = 1
	show_th = 1
	show_lath = 1
	show_lonh = 1
endif

charthick = 4
linethick = 4
charsize  = 1.15
axischarsize = 1.5
barcharsize = 1.2
graph_pos = [0.15, 0.11, 0.82, 0.95]
bar_pos = [0.94, 0.15, 0.99, 0.91]
circle_sym = dindgen(19) * 2.0D * !dpi / 18.0D
usersym, cos(circle_sym), sin(circle_sym), /fill

hort = 0
horv = 0
corp = 0
pint = 0
pinv = 0
if (n_elements(hor_tag) EQ 1 && size(hor_tag, /type) EQ 7)          then hort=1
if (n_elements(hor_val) GT 0)                                       then horv=1
if (n_elements(core_param) EQ 1)                                    then corp=1
if (n_elements(profinfo_tag) EQ 1 && size(profinfo_tag,/type) EQ 7) then pint=1
if (n_elements(profinfo_val) GT 0)                                  then pinv=1

nchoices = hort + horv + corp + pint + pinv
if (nchoices GT 1) then begin
	message, 'Conflicting selection'
endif else if (nchoices LT 1) then begin
	hort = 1
	hor_tag = 'tim/3600.0D'
	title1 = 'Time (h)'
	if (n_elements(bar_format) LE 0) then bar_format = '(f0.2)'
endif

if (corp && n_elements(corefln) NE 1) then begin
	message, 'No core file: ' + corefln
endif

if ((pint || pinv) && (n_elements(nprofiles) NE 1 || nprofiles LE 0L)) $
   then begin
	message, 'No data. lid_data_read must be called first.'
endif

data_cmd = ''
use_profiles = 0
samp0 = 15
smoo0 = 15 

if (hort) then begin
	data_cmd = 'data = double(hor.' + hor_tag + ')'
	title0 = 'hor.' + hor_tag
endif else if (horv) then begin
	data = double(hor_val)
	title0 = 'user defined hor_val'
endif else if (corp) then begin
	status = mrfread(core_path + corefln, core_param, data, flags, $
		start=takeoff, stop=landing)
	if (n_elements(data) LE 0) then message, 'No data for this parameter'
	data = reform(double(data[0,*]))
	flags = reform(fix(flags[0,*]))
	idx = where(flags NE 0 OR ~finite(data), cnt)
	if (cnt GE 1) then data[idx] = _dundef_
	title0 = string(format='(%"core data - parameter %d")', core_param)
endif else if (pint) then begin
	data_cmd = 'data = double(profinfo.' + profinfo_tag + ')'
	use_profiles = 1
	samp0 = 1
	smoo0 = 1
	title0 = 'profinfo.' + profinfo_tag
endif else if (pinv) then begin
	data = double(profinfo_val)
	use_profiles = 1
	samp0 = 1
	smoo0 = 1
	title0 = 'user defined profinfo_val'
endif

if (data_cmd NE '') then begin
	exec_ok = execute(data_cmd)
	if (~exec_ok) then message, 'Error executing: ' + data_cmd
endif

if (n_elements(condition) EQ 1) then begin
	cond_cmd = string(format='(%"dummy = where(%s, complement=idx, ' $
		+ 'ncomplement=cnt)")', condition)
	exec_ok = execute(cond_cmd)
	if (~exec_ok) then message, 'Error executing: ' + cond_cmd
	if (cnt GT 0) then data[idx] = _dundef_
endif

if (n_elements(title) NE 1) then begin
	if (n_elements(title1) EQ 1) then title = title1 else title = title0
endif

if (n_elements(tsamp) NE 1) then tsamp = 30
if (n_elements(smoo) NE 1)  then smoo = smoo0
if (n_elements(samp) NE 1)  then samp = samp0
data = smooth(data, smoo, /edge_truncate)
data = data[1:*:samp]

tim = hor[1:*:tsamp].tim / 3600.0D
alt = hor[1:*:tsamp].alt
lat = hor[1:*:tsamp].lat
lon = hor[1:*:tsamp].lon
ntim = n_elements(tim)
if (use_profiles) then begin
	tim2 = profinfo[1:*:samp].time / 3600.0D
	alt2 = profinfo[1:*:samp].alt
	lat2 = profinfo[1:*:samp].lat
	lon2 = profinfo[1:*:samp].lon
endif else begin
	tim2 = hor[1:*:samp].tim / 3600.0D
	alt2 = hor[1:*:samp].alt
	lat2 = hor[1:*:samp].lat
	lon2 = hor[1:*:samp].lon
endelse

ntim2 = n_elements(tim2)

if (n_elements(data) NE ntim2) then $
	message, 'Array dimension inconsistency.'

t_idx  = where(tim2 GE trange[0] AND tim2 LE trange[1], t_cnt)
t_idx2 = where(tim2 GE trange[0] AND tim2 LE trange[1] AND abs(lat2) GE 0.1)
if (t_cnt LE 0) then message, 'No data within interval'

latmin = min(lat2[t_idx2], max=latmax)
lonmin = min(lon2[t_idx2], max=lonmax)
if (latmin EQ latmax) then begin
	latmin -= 1.0D
	latmax += 1.0D
endif
if (lonmin EQ lonmax) then begin
	lonmin -= 1.0D
	lonmax += 1.0D
endif

mapcenter = [(latmin + latmax) / 2.0, (lonmin + lonmax) / 2.0]
if (n_elements(latrange) NE 2 && n_elements(lonrange) NE 2) then begin
	aspect = float(!d.x_size * (graph_pos[2] - graph_pos[0])) $
		/ (!d.y_size * (graph_pos[3] - graph_pos[1]))
	ratio = (lonmax - lonmin) * cos(mapcenter[0] * !dtor) $
		/ ((latmax - latmin) * aspect)
	if (ratio LE 1.0D) then latrange = [latmin - 0.2, latmax + 0.2] $
		else lonrange = [lonmin - 0.2, lonmax + 0.2]
endif

if (n_elements(xrange) NE 2) then begin
	def = where(data[t_idx2] GT _dundef_ / 1000.0D)
	xmin = min(data[t_idx2[def]], max=xmax)
	xrange = [xmin, xmax]
endif

if (n_elements(min_value) NE 1) then min_value = xrange[0]
if (n_elements(bar_format) NE 1) then bar_format = '(f0.0)'

cols = bottom + bytscl(data, min=xrange[0], max=xrange[1], top=top-bottom)
;tit = globaltitle + '!C' + title
tit = string(format='(%"%s %d-%d-%d: %s")', flno_sub, dd, mth, yy, title)

if (sort EQ 0) then index = indgen(t_cnt) $
	else if (sort GT 0) then index = sort(data[t_idx]) $
	else index = reverse(sort(data[t_idx]))

if (keyword_set(show_map)) then begin
	setmap, latrange=latrange, lonrange=lonrange, mapcenter=mapcenter, $
		/hires, title=tit, lon_title='Longitude', lat_title='Latitude',$
		countries=countries, charsize=charsize, charthick=charthick, $
		thick=linethick, position = graph_pos
	oplot, lon, lat, thick=linethick
	for i=0, t_cnt-1 do begin
		p = t_idx[index[i]]
		if (data[p] GE min_value) then $
			oplot, [lon2[p]], [lat2[p]], psym=8, $
				symsize=symsize, color=cols[p]
	endfor
	colorbar, range=xrange, /vertical, bottom=bottom, ncolors=top-bottom+1,$
		linethick=linethick, charthick=charthick, charsize=barcharsize,$
		min_value=min_value, divisions=bar_divs, format=bar_format, $
		position=bar_pos
endif

if (keyword_set(show_th)) then begin
	plot, tim, alt, xrange=trange, yrange=yrange, xstyle=tstyle, $
		ystyle=ystyle, title=tit, xtitle='Time (h)', $
		ytitle='Altitude (m)', charsize=charsize, $
		xcharsize=axischarsize, ycharsize=axischarsize, $
		charthick=charthick, thick=linethick, xthick=linethick, $
		ythick=linethick, position = graph_pos
	for i=0, t_cnt-1 do begin
		p = t_idx[index[i]]
		if (data[p] GE min_value) then $
			oplot, [tim2[p]], [alt2[p]], psym=8, $
				symsize=symsize, color=cols[p]
	endfor
	colorbar, range=xrange, /vertical, bottom=bottom, ncolors=top-bottom+1,$
		linethick=linethick, charthick=charthick, charsize=barcharsize,$
		min_value=min_value, divisions=bar_divs, format=bar_format, $
		position=bar_pos
endif

if (keyword_set(show_lath)) then begin
	plot, lat, alt, xrange=latrange, yrange=yrange, xstyle=latstyle, $
		ystyle=ystyle, title=tit, xtitle='Latitude', $
		ytitle='Altitude (m)', charsize=charsize, $
		xcharsize=axischarsize, ycharsize=axischarsize, $
		charthick=charthick, thick=linethick, xthick=linethick, $
		ythick=linethick, position = graph_pos
	for i=0, t_cnt-1 do begin
		p = t_idx[index[i]]
		if (data[p] GE min_value) then $
			oplot, [lat2[p]], [alt2[p]], psym=8, $
				symsize=symsize, color=cols[p]
	endfor
	colorbar, range=xrange, /vertical, bottom=bottom, ncolors=top-bottom+1,$
		linethick=linethick, charthick=charthick, charsize=barcharsize,$
		min_value=min_value, divisions=bar_divs, format=bar_format, $
		position=bar_pos
endif

if (keyword_set(show_lonh)) then begin
	plot, lon, alt, xrange=lonrange, yrange=yrange, xstyle=lonstyle, $
		ystyle=ystyle, title=tit, xtitle='Longitude', $
		ytitle='Altitude (m)', charsize=charsize, $
		xcharsize=axischarsize, ycharsize=axischarsize, $
		charthick=charthick, thick=linethick, xthick=linethick, $
		ythick=linethick, position = graph_pos
	for i=0, t_cnt-1 do begin
		p = t_idx[index[i]]
		if (data[p] GE min_value) then $
			oplot, [lon2[p]], [alt2[p]], psym=8, $
				symsize=symsize, color=cols[p]
	endfor
	colorbar, range=xrange, /vertical, bottom=bottom, ncolors=top-bottom+1,$
		linethick=linethick, charthick=charthick, charsize=barcharsize,$
		min_value=min_value, divisions=bar_divs, format=bar_format, $
		position=bar_pos
endif


tvlct, colortable


if (newplot) then begin
	device, /close_file
	if (!version.os_family EQ 'unix') then begin
		set_plot, 'x'
		cmd = psview_ux + ' ' + psfln
		if (display LT 2) then cmd += ' &'
		if (keyword_set(display)) then spawn, cmd
	endif else begin
		set_plot, 'win'
		cmd = psview_win + ' ' + psfln
		noshell = 1
		if (display LT 2) then nowait=1 else nowait=0
		if (keyword_set(display)) then $
			spawn, cmd, /noshell, nowait=nowait
	endelse
endif

if (openlog) then begin
	printf, lgf, file_basename(psfln)
	free_lun, lgf
endif


if (keyword_set(verbose) && verbose GE 2) then begin
	print, 'Latrange: ', latrange
	print, 'Lonrange: ', lonrange
endif


end
