;SETMAP
;a front end to map_set (IDL built-in) with a friendly syntax
;tries to compute coordinate ranges for the best aspect ratio
;latitude and longitude are printed at the axes
;try it by just typing: setmap
;if you do not like sunshine, type: setmap, mapcenter=[55.0,-4.0]
;
;by Franco Marenco
;please report any bugs and/or your modifications to me :-)
;
;input:   latrange, lonrange (arrays of two elements each): axes ranges
;input:   mapcenter (array of two elements): where you want the map to be
;         centered (default: Italy); ignored if latrange and lonrange are
;         both defined
;input:   latticks, lonticks: number of major ticks on axes (default: auto)
;input:   latminor, lonminor: number of minor ticks on axes (default: 1)
;input:   xmargin, ymargin: margins (see map_set documentation)
;input:   position: position of plot (see map_set documentation)
;input:   color: set colour for everything (map and axes)
;input:   mapcolor: set colour for map only
;input:   countries: draw country boundaries
;input:   the other input parameters are for graphical style and
;         are straightforward (look at the routine definition below)
;output:  the actual values used for latrange and lonrange are output
;keyword: hires: if set to zero, do not use the high resolution map


pro setmap, latrange=latrange, lonrange=lonrange, mapcenter=mapcenter, $
	latticks=latticks, lonticks=lonticks, latminor=latminor, $
	lonminor=lonminor, xmargin=xmargin, ymargin=ymargin,$
	position=position, hires=hires, color=color, mapcolor=mapcolor, $
	countries=countries, title=title, lon_title=lon_title, $
	lat_title=lat_title, thick=thick, charthick=charthick, $
	charsize=charsize, axischarsize=axischarsize, noerase=noerase


compile_opt strictarr, strictarrsubs


; this fixes map_set IDL bug
if (!p.multi[1]*!p.multi[2] EQ 0 && !p.multi[1]+!p.multi[2] NE 0) then begin
	!p.multi[1] = max([!p.multi[1], 1])
	!p.multi[2] = max([!p.multi[2], 1])
endif

if (!p.multi[1] LE 1 && !p.multi[2] LE 1) then begin
	advance   = 0
	xmargin0  = 6
	ymargin0  = 5
	charsize0 = 1.5
endif else begin
	advance   = 1
	xmargin0  = 4
	ymargin0  = 3
	charsize0 = 1
endelse

aspect = float(!d.x_size) / !d.y_size

if (n_elements(position) EQ 4) then begin
	xmargin0 = 0
	ymargin0 = 0
	aspect *= (position[2] - position[0]) / (position[3] - position[1])
endif


if (n_elements(hires) NE 1)     then hires     = 1
if (n_elements(latminor) NE 1)  then latminor  = 1
if (n_elements(lonminor) NE 1)  then lonminor  = 1
if (n_elements(mapcenter) NE 2) then mapcenter = [42.0,12.5]	; Italy
if (n_elements(xmargin) LE 0)   then xmargin   = xmargin0
if (n_elements(ymargin) LE 0)   then ymargin   = ymargin0
if (n_elements(charsize) NE 1)  then charsize  = charsize0


; define map boundaries

deflat = (n_elements(latrange) EQ 2 && array_equal(latrange,[0,0]) EQ 0)
deflon = (n_elements(lonrange) EQ 2 && array_equal(lonrange,[0,0]) EQ 0)

if (deflat) then begin
	minlat = min(latrange, max=maxlat)
	dlat   = (maxlat - minlat) / 2.0
	latmid = (minlat + maxlat) / 2.0
endif else begin
	latmid = mapcenter[0]
endelse

if (deflon) then begin
	minlon = min(lonrange, max=maxlon)
	dlon = (maxlon - minlon) / 2.0
endif

if (~deflat && ~deflon) then begin
	dlat = 6.0
endif else if (~deflat) then begin
	dlat   = dlon * cos(latmid * !dtor) / aspect
endif

if (~deflon) then begin
	dlon   = dlat * aspect / cos(latmid * !dtor)
endif

if (~deflat) then begin
	minlat = mapcenter[0] - dlat
	maxlat = mapcenter[0] + dlat
endif

if (~deflon) then begin
	minlon = mapcenter[1] - dlon
	maxlon = mapcenter[1] + dlon
endif

maxlat = min([maxlat,   90.0])
minlat = max([minlat,  -90.0])
maxlon = min([maxlon,  180.0])
minlon = max([minlon, -180.0])


; go out and plot the stuff

save_except = !except
!except = 0

if (keyword_set(countries)) then e_continents={countries:1}

map_set, /continents, hires=hires, limit=[minlat, minlon, maxlat, maxlon], $
	xmargin=xmargin, ymargin=ymargin, advance=advance, color=color, $
	con_color=mapcolor, mlinethick=thick, charsize=charsize, $
	position=position, e_continents=e_continents, noerase=noerase

if (n_elements(title) EQ 1) then $
	xyouts, /normal, alignment=0.5, mean(!x.window), $
		!y.window[1]+0.015*(!y.window[1]-!y.window[0]),$
		title, charsize=charsize, charthick=charthick

if (n_elements(lonticks) EQ 0 || lonticks GT 0) then begin
	axis, xaxis=0, xrange=[minlon, maxlon], xticks=lonticks, $
		xminor=lonminor, charsize=charsize, xcharsize=axischarsize, $
		charthick=charthick, color=color, xtitle=lon_title, /xstyle
endif

if (n_elements(latticks) EQ 0 || latticks GT 0) then begin
	axis, yaxis=0, yrange=[minlat, maxlat], yticks=latticks, $
		yminor=latminor, charsize=charsize, ycharsize=axischarsize, $
		charthick=charthick, color=color, ytitle=lat_title, /ystyle
endif

dummy = check_math()
!except = save_except

latrange = [minlat, maxlat]
lonrange = [minlon, maxlon]

end
