pro lid_browse, trange=trange0, yrange=yrange0, xrange=xrange0, xtype=xtype0, $
	xchan=xchan0, khor=khor0, pvert=pvert0, windowkeep=windowkeep


@lid_settings.include


common __lid_browse, trange, yrange, xrange, xtype, xchan, khor, pvert


if (n_elements(trange0) EQ 2) then trange = trange0
if (n_elements(yrange0) EQ 2) then yrange = yrange0
if (n_elements(xrange0) EQ 2) then xrange = xrange0
if (n_elements(xtype0) EQ 1)  then xtype = lid_type_select(xtype0)
if (n_elements(xchan0) EQ 1)  then xchan = xchan0
if (n_elements(khor0) EQ 1)   then khor = khor0
if (n_elements(pvert0) EQ 1)  then pvert = pvert0


;openw, lgf, logfln, /get_lun, /append
;printf, lgf, 'lid_browse: starting'

if (n_elements(nprofiles) NE 1 || nprofiles LE 0L) then $
	message, 'No data. lid_data_read must be called first.'

if (n_elements(nheights) NE 1 || nheights LE 0L) then $
	message, 'No gridded data. lid_data_grid must be called first.'

gridded = intarr(ntypes)
j = 0
for i=0, ntypes-1 do if (lid_type_gridded(i)) then gridded[j++] = i
ngridded = j


def_xmin =  [_dundef_, _dundef_, 0.0D, 0.0D, 0.0D, 0.0D, 0.0D, $
	0.0D, 0.0D, 1.0D, 0.0D, 0.0D, 0.0D, 0.0D]
def_xmax =  [_dundef_, _dundef_, 2800.0D, 2800.0D, 2.8D, 0.14D, 0.28D, $
	1.4D-3, 1.4D-5, _dundef_, 1.4D-3, 1.4D-3, 700.0D, 0.7D-3]
bar_format = ['(E0.1)', '(E0.1)', '(I0)', '(I0)', '(F0.2)', '(F0.3)', '(F0.3)',$
	'(E0.1)', '(E0.1)', '(E0.1)', '(E0.1)', '(E0.1)', '(I0)', '(E0.1)']

xfact0 = 0.8
xax = [0.08, 0.7, 0.97]
yax = [0.06, 0.35, 0.85, 0.94]
xmargin = 0.06
ymargin = 0.06
hgtmargin = [0.07, 0.07, 0.11]
bar_pos = [xax[0]+0.05, yax[2]+ymargin, xax[1]-0.15, yax[3]]
ytit = 0.96
xtxt = [0.64, 0.64]
ytxt = [0.94, 0.90]
xbutton = [0.85, 0.905, 0.915, 0.97]
ybutton = 0.9 - 0.07*findgen(10)
ybutton = [0.91, 0.84, 0.74-0.07*findgen(6), 0.28, 0.17, 0.06]
hbutton = 0.05
mindis = 0.005

plot_box = [xax[0]*xfact0, yax[1], xax[1]*xfact0, yax[2]]
pver_box = [xax[0]*xfact0, yax[0], xax[1]*xfact0, yax[1]]
khor_box = [xax[1]*xfact0, yax[1], xax[2]*xfact0, yax[2]]
map_box  = [(xax[1]+xmargin)*xfact0, yax[0], xax[2]*xfact0, yax[1] - ymargin]
xtyp_box = [xbutton[0], ybutton[0], xbutton[3], ybutton[0]+hbutton]
chn0_box = [xbutton[0], ybutton[1], xbutton[1], ybutton[1]+hbutton]
chn1_box = [xbutton[2], ybutton[1], xbutton[3], ybutton[1]+hbutton]
xran_box = [xbutton[0], ybutton[2], xbutton[3], ybutton[2]+hbutton]
tran_box = [xbutton[0], ybutton[3], xbutton[3], ybutton[3]+hbutton]
yran_box = [xbutton[0], ybutton[4], xbutton[3], ybutton[4]+hbutton]
ycho_box = [xbutton[0], ybutton[5], xbutton[3], ybutton[5]+hbutton]
yplus_box =  [0.81, ybutton[5]+hbutton/2.0+0.005, 0.84, ybutton[5]+hbutton*1.5]
yminus_box = [0.81, ybutton[5]-hbutton/2.0, 0.84, ybutton[5]+hbutton/2.0-0.005]
pcho_box = [xbutton[0], ybutton[6], xbutton[3], ybutton[6]+hbutton]
prev_box = [xbutton[0], ybutton[7], xbutton[1], ybutton[7]+hbutton]
next_box = [xbutton[2], ybutton[7], xbutton[3], ybutton[7]+hbutton]
ps_box   = [xbutton[0], ybutton[8], xbutton[3], ybutton[8]+hbutton]
save_box = [xbutton[0], ybutton[9], xbutton[3], ybutton[9]+hbutton]
quit_box = [xbutton[0], ybutton[10], xbutton[3], ybutton[10]+hbutton]
err_box  = [0.40, 0.62, 0.65, 0.70]

xmenu = [0.4, 0.8]
ymenu = 0.86 - findgen(ntypes) * 0.07
ymenuthick = 0.05
menutit_box = [0.15, 0.86, 0.3, 0.91]

wnum = 0
xsize = 1275
ysize = 800
device, get_screen_size=screen
xsize = min([xsize, screen[0]]-100)
ysize = min([ysize, screen[1]]-100)
xpos = (screen[0] - xsize) / 2
ypos = (screen[1] - ysize) / 2

if (!version.os_family EQ 'unix') then begin
	plot_type = 'x'
	arrow = 2
endif else begin
	plot_type = 'win'
	arrow = 32512
endelse

set_plot, plot_type
if (~keyword_set(windowkeep)) then window, wnum, title='Lidar browser', $
		xsize=xsize, ysize=ysize, xpos=xpos, ypos=ypos
!p.multi = [0, 2, 2]
set_palette, 3, bottom=bottom, top=top, maxlevs=maxlevs

charsize_x  = 1.15
charsize_ps = 1
thick_x  = 1
thick_ps = 4
nlevsmax = 32
circle_sym = dindgen(19) * 2.0D * !dpi / 18.0D
usersym, cos(circle_sym), sin(circle_sym), /fill
psfln = outfln + '_browse.ps'
txtfln = outfln + '_browse.txt'

idx = where(hor.tim GE takeoff AND hor.tim LE landing, cnt)
hor2 = hor[idx[0]:idx[cnt-1]:15]

latmin = min(hor2.lat, max=latmax)
lonmin = min(hor2.lon, max=lonmax)
if (latmin EQ latmax) then begin
	latmin -= 1.0D
	latmax += 1.0D
endif
if (lonmin EQ lonmax) then begin
	lonmin -= 1.0D
	lonmax += 1.0D
endif
mapcenter = [(latmin + latmax) / 2.0, (lonmin + lonmax) / 2.0]
latrange = [latmin-0.2, latmax+0.2]
lonrange = [lonmin-0.2, lonmax]+0.2

aspect = float(xsize) * xfact0 * (xax[2]-xax[1]-xmargin) $
	/ (float(ysize) * (yax[1]-ymargin-yax[0]))
ratio = (lonmax - lonmin) * cos(mean(latrange) * !dtor) $
	/ ((latmax - latmin) * aspect)
if (ratio LE 1.0D) then lonrange = 0 else latrange = 0

ps = 0
quit = 0
repeat begin
	if (n_elements(trange) EQ 2) then begin
		tstyle = 1
	endif else begin
		trange = [takeoff, landing] / 3600.0D
		tstyle = 0
	endelse

	if (n_elements(yrange) EQ 2) then begin
		ystyle = 1
	endif else begin
		ystyle = 0
		if (view EQ _nadir_) then begin
			yrange = [max([ymin,0]),max(profinfo.alt)] / 1000.0D
		endif else begin
			yrange = [min(profinfo.alt), ymax] / 1000.0D
		endelse
	endelse

	idx = where(lid_height GE yrange[0]*1000.0D $
		AND lid_height LE yrange[1]*1000.0D, cnt)
	if (n_elements(khor) NE 1 || cnt LE 0) then begin
		yhor = mean(yrange)
		dummy = min(abs(lid_height/1000.0D - yhor), khor)
	endif else if (khor LT idx[0]) then begin
		khor = idx[0]
	endif else if (khor GT idx[cnt-1]) then begin
		khor = idx[cnt-1]
	endif

	idx = where(profinfo.time GE trange[0]*3600.0D $
		AND profinfo.time LE trange[1]*3600.0D, cnt)
	if (n_elements(pvert) NE 1 || cnt LE 0) then begin
		tvert = mean(trange)
		dummy = min(abs(profinfo.time/3600.0D - tvert), pvert)
	endif else if (pvert LT idx[0]) then begin
		pvert = idx[0]
	endif else if (pvert GT idx[cnt-1]) then begin
		pvert = idx[cnt-1]
	endif

	if (n_elements(xtype) NE 1 || xtype LT 0 $
		|| ~lid_type_gridded(xtype)) then xtype = _default_type_

	if (n_elements(xchan) NE 1 || xchan LT 0 || xchan GT nchannels-1 $
		|| ~issignal[xtype]) then xchan = 0

	if (n_elements(xrange) NE 2) $
		then xrange = [def_xmin[xtype], def_xmax[xtype]]

	if (ps) then begin
		print, 'Generating PostScript...'
		set_plot, 'ps'
		device, /color, /landscape, bits_per_pixel=8, filename=psfln
		xfact = 1
		thick = thick_ps
		charsize = charsize_ps
	endif else begin
		set_plot, plot_type
		device, window_state=window_open
		if (~window_open[wnum]) then $
			window, wnum, title='Lidar browser', $
			xsize=xsize, ysize=ysize, xpos=xpos, ypos=ypos
		xfact = xfact0
		thick = thick_x
		charsize = charsize_x
	endelse

	axischarsize = 1.35 * charsize
	barcharsize = 1.35 * charsize
	if (bar_format[xtype] EQ '(E0.1)') then barcharsize *= (ps ? 0.55: 0.7)

	title = flno + ' - ' + typetit[xtype] $
		+ (issignal[xtype] ? string(xchan, format='(%" - ch%d")') : '')
	pinfo = profinfo[pvert]
	prof  = profile[pvert]
	tvert = pinfo.time / 3600.0D
	yhor  = lid_height[khor] / 1000.0D
	data_arr  = lid_type_data(xtype, chan=xchan, /gridded)
	data_prof = lid_type_data(xtype, pinfo, prof, chan=xchan)
	data_seq  = reform(data_arr[*,khor])
	if (dblcomp(xrange[0], _dundef_)) then xrange[0] = 0
	if (dblcomp(xrange[1], _dundef_)) then xrange[1] = max(data_arr)
	
	nlevs = min([maxlevs, nlevsmax])
	levs = xrange[0] + (xrange[1]-xrange[0]) * dindgen(nlevs) / nlevs
	cols = bottom + bytscl(indgen(nlevs), top=top-bottom)

	contour, data_arr, profinfo.time/3600.0D, lid_height/1000.0, $
		min_value=xrange[0], levels = levs, c_colors = cols, $
		/cell_fill, xrange=trange, yrange=yrange, $
		xstyle=tstyle, ystyle=ystyle, thick=thick, $
		xthick=thick, ythick=thick, charthick=thick, $
		charsize=charsize, xcharsize=axischarsize, $
		ycharsize=axischarsize, $
		position=[xax[0]*xfact, yax[1], xax[1]*xfact, yax[2]]

	trange = !x.crange
	yrange = !y.crange

	oplot, [tvert, tvert], yrange, thick=1.5*thick, color=2
	oplot, trange, [yhor, yhor], thick=1.5*thick, color=2

	colorbar, range=xrange, divisions=7, minor=2, bottom=bottom, $
		ncolors=top-bottom+1, linethick=thick, charthick=thick, $
		charsize=barcharsize, format=bar_format[xtype], $
		position=[bar_pos[0]*xfact, bar_pos[1], bar_pos[2]*xfact, $
		bar_pos[3]]

	plot, data_prof, prof.height/1000.0D, min_value=0.0D, $
		xrange=xrange, yrange=yrange, /xstyle, /ystyle, $
		xticks=1, thick=thick, xthick=thick, ythick=thick, $
		charthick=thick, charsize=charsize, $
		xcharsize=axischarsize, ycharsize=axischarsize, $
		position=[(xax[1]+xmargin)*xfact, yax[1], xax[2]*xfact, yax[2]]
	oplot, xrange, [yhor, yhor], thick=1.5*thick, color=2

	plot, profinfo.time/3600.0D, data_seq, min_value=0.0D, $
		xrange=trange, yrange=xrange, /xstyle, /ystyle, $
		yticks=1, thick=thick, xthick=thick, ythick=thick, $
		charthick=thick, charsize=charsize, $
		xcharsize=axischarsize, ycharsize=axischarsize, $
		position=[xax[0]*xfact, yax[0], xax[1]*xfact, yax[1] - ymargin]
	oplot, [tvert, tvert], xrange, thick=1.5*thick, color=2

	setmap, mapcenter=mapcenter, latrange=latrange, lonrange=lonrange, $
		/hires, latticks=-1, lonticks=-1, thick=thick, $
		position=[(xax[1]+xmargin)*xfact, yax[0], xax[2]*xfact, $
		yax[1] - ymargin]
	oplot, hor2.lon, hor2.lat, color=3, thick=thick
	idx = where(hor2.tim GE trange[0]*3600.0D $
		AND hor2.tim LE trange[1]*3600.0D, cnt)
	if (cnt GT 0) then oplot, hor2[idx].lon, $
		hor2[idx].lat, color=2, thick=thick
	oplot, [pinfo.lon], [pinfo.lat], psym=8, color=2, symsize=1.6
	oplot, [pinfo.lon], [pinfo.lat], psym=8, color=5, symsize=1.2
	oplot, [pinfo.lon], [pinfo.lat], psym=8, color=2, symsize=0.4

	xyouts, mean(bar_pos[[0,2]])*xfact, ytit, title, /normal, $
		alignment=0.5, charsize=1.5*charsize, charthick=thick

	xyouts, (xax[0]-hgtmargin[0])*xfact, yax[1]-ymargin-hgtmargin[1], $
		/normal, charsize=axischarsize, charthick=thick, color=2, $
		string(khor, format='(%"%d")')

	xyouts, (xax[0]-hgtmargin[0])*xfact, yax[1]-ymargin-hgtmargin[2], $
		/normal, charsize=axischarsize, charthick=thick, color=2, $
		string(yhor, format='(%"%0.1fkm")')

	xyouts, xtxt[0]*xfact, ytxt[0], /normal, $
		charsize=axischarsize, charthick=thick, $
		string(format='(%"%d  %5.2fh  %s %s")', pvert, tvert, $
		dectomin(pinfo.lat, 'N', 'S', ndec=2, /decimal), $
		dectomin(pinfo.lon, 'E', 'W', ndec=2, /decimal))

	xyouts, xtxt[1]*xfact, ytxt[1], /normal, charsize=axischarsize, $
		charthick=thick, string(format='(%"%ikm  %3.1fkm  %i\xB0")', $
		round(pinfo.dis/1000.0D), pinfo.alt/1000.0D, round(pinfo.ofn))

	txtline = string(pvert, khor, tvert, yhor, $
		dectomin(pinfo.lat, 'N', 'S', ndec=2, /decimal), $
		dectomin(pinfo.lon, 'E', 'W', ndec=2, /decimal), $
		round(pinfo.dis/1000.0D), pinfo.alt/1000.0D, $
		round(pinfo.ofn), xchan, typename[xtype], $
		format='(%"%4d  %4d  %5.2fh  %0.1fkm  %s  %s  %ikm  ' $
		+ '%3.1fkm  %ideg  %1d  %-7s")')

	if (data_seq[pvert] GT _dundef_ / 1000.0D) then begin
		xyouts, xax[2]*xfact, ytxt[1], charsize=axischarsize, $
			charthick=thick, color=2, /normal, alignment=1, $
			string(data_seq[pvert], format=bar_format[xtype])
		txtline += '  ' $
			+ string(data_seq[pvert], format=bar_format[xtype])
	endif

	if (ps) then begin
		ps = 0
		device, /close_file
		if (!version.os_family EQ 'unix') then begin
			spawn, psview_ux + ' ' + psfln + ' &'
		endif else begin
			spawn, psview_win + ' ' + psfln, /noshell, /nowait
		endelse
	endif else begin
		textbox, xtyp_box, 'Data type'
		if (issignal[xtype]) then begin
			textbox, chn0_box, 'Ch0', color = 1 + 4 * (xchan EQ 0)
			textbox, chn1_box, 'Ch1', color = 1 + 4 * (xchan EQ 1)
		endif
		textbox, xran_box, 'Data range'
		textbox, tran_box, 'Time range'
		textbox, yran_box, 'Vertical range'
		textbox, ycho_box, 'Choose height'
		textbox, yplus_box, '+'
		textbox, yminus_box, '-'
		textbox, pcho_box, 'Pick profile'
		textbox, prev_box, 'Prev'
		textbox, next_box, 'Next'
		textbox, ps_box, 'PostScript'
		textbox, save_box, 'Save point'
		textbox, quit_box, 'Quit'

		repeat begin
		   wset, wnum
		   device, cursor_standard=arrow
		   cursor, xcur, ycur, /normal, wait=3, /change
		   tcoord = (xcur/xfact-xax[0]) * (trange[1]-trange[0]) $
		      / (xax[1]-xax[0]) + trange[0]
		   ycoord = (ycur-yax[1]) * (yrange[1]-yrange[0]) $
		      / (yax[2]-yax[1]) + yrange[0]
		   pressed = 1
		   case 1 of
		      in_box(xcur, ycur, plot_box): begin
		         dummy = min(abs(profinfo.time/3600.0D - tcoord), pvert)
		         dummy = min(abs(lid_height/1000.0D - ycoord), khor)
		      end

		      in_box(xcur, ycur, pver_box): $
		         dummy = min(abs(profinfo.time/3600.0D - tcoord), pvert)

		      in_box(xcur, ycur, khor_box): $
		         dummy = min(abs(lid_height/1000.0D - ycoord), khor)

		      in_box(xcur, ycur, map_box): begin
		         pressed = 0
		         xmap = xfact * (xax[1] + xmargin + $
		            (profinfo.lon-lonrange[0]) * $
		            (xax[2]-xax[1]-xmargin) / (lonrange[1]-lonrange[0]))
		         ymap = yax[0] + (profinfo.lat - latrange[0]) * $
		            (yax[1]-yax[0]-ymargin) / (latrange[1]-latrange[0])
		         idx = where(profinfo.time GE trange[0]*3600.0D $
		            AND profinfo.time LE trange[1]*3600.0D, cnt)
		         if (cnt GT 0) then begin
		            dis2 = min((xcur-xmap[idx])^2+(ycur-ymap[idx])^2,i)
		            if (sqrt(dis2) LE mindis) then begin
		               pvert = idx[i]
		               pressed = 1
		            endif
		         endif
		      end

		      in_box(xcur, ycur, xtyp_box): begin
		         erase
		         textbox, menutit_box, 'Choose data type:', $#
		            color=5, /nobox
		         textbox, quit_box, 'Back'
		         for i=0, ngridded-1 do textbox, [xmenu[0], ymenu[i], $
		               xmenu[1],ymenu[i]+ymenuthick],typetit[gridded[i]]
		         repeat begin
		            cursor, xcur, ycur, /normal, wait=3, /change
		            xtype_specified = 0
		            for i=0, ngridded-1 do if in_box(xcur, ycur, $
		               [xmenu[0], ymenu[i], xmenu[1], $
		               ymenu[i]+ymenuthick]) then begin
		                  if (xtype NE gridded[i]) then xrange = 0
		                  xtype = gridded[i]
		                  xtype_specified = 1
		            endif
		         endrep until (xtype_specified $
		           || in_box(xcur, ycur, quit_box))
		      end

		      in_box(xcur, ycur, chn0_box): $
		         if issignal[xtype] then xchan = 0 else pressed = 0

		      in_box(xcur, ycur, chn1_box): $
		         if issignal[xtype] then xchan = 1 else pressed = 0

		      in_box(xcur, ycur, xran_box): $
		         xrange = get_input('Data', xrange, /range)

		      in_box(xcur, ycur, tran_box): $
		         trange = get_input('Time', trange, /range)

		      in_box(xcur, ycur, yran_box): $
		         yrange = get_input('Vertical', yrange, /range)

		      in_box(xcur, ycur, ycho_box): begin
		         yhor = get_input('Selected Height', yhor)
		         dummy = min(abs(lid_height/1000.0D - yhor), khor)
		      end

		      in_box(xcur, ycur, yplus_box): ++khor

		      in_box(xcur, ycur, yminus_box): --khor

		      in_box(xcur, ycur, pcho_box): $
		         pvert = get_input('Profile number', pvert, $
		            time=profinfo.start)

		      in_box(xcur, ycur, prev_box): --pvert

		      in_box(xcur, ycur, next_box): ++pvert

		      in_box(xcur, ycur, ps_box): ps = 1

		      in_box(xcur, ycur, save_box): begin
		         openw, txt, txtfln, /append, /get_lun
		         printf, txt, txtline
		         free_lun, txt
		         print, txtline
		      end

		      in_box(xcur, ycur, quit_box): quit = 1

		      else: pressed = 0
		   endcase
		endrep until (pressed)

	endelse
endrep until (quit)

textbox, err_box, 'Quit', charsize=2, color=2

set_plot, plot_type
col27
!p.multi = 0

;printf, lgf, 'lid_browse: quitting'
;free_lun, lgf


end
