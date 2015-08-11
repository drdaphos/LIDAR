pro axisdraw, t, lat, lon, ypos=ypos, reverselines=reverselines, $
	nticks=nticks, decimal=decimal, minor=minor, ndec=ndec, noaxis=noaxis, $
	axiscolor=axiscolor, linecolor=linecolor, charsize=charsize, $
	charthick=charthick, linethick=linethick

compile_opt strictarr, strictarrsubs

if (n_elements(ypos) NE 1)		then ypos = 0.05
if (n_elements(reverselines) NE 1)	then reverselines = 1
if (n_elements(nticks) NE 1)		then nticks = 10
if (n_elements(decimal) NE 1)           then decimal = 0
if (n_elements(minor) NE 1)		then minor = 2
if (n_elements(ndec) NE 1)		then ndec = decimal
if (n_elements(noaxis) NE 1)		then noaxis = 0
if (n_elements(axiscolor) NE 1)		then axiscolor = !p.color
if (n_elements(linecolor) NE 1)		then linecolor = !p.color
if (n_elements(charsize) NE 1)		then charsize = 1


; determine plot ranges

trange = !x.crange
yrange = !y.crange


; determine label positions and values

tickpos = trange[0] + (trange[1]-trange[0]) * dindgen(nticks+1) / nticks
ticklab = strarr(nticks+1)
for i=0, nticks do begin
	dummy = min(abs(t-tickpos[i]), idx)
	ticklab[i] = string(format='(%"%s!C%s")', $
		dectomin(lat[idx], 'N', 'S', ndec=ndec, decimal=decimal), $
		dectomin(lon[idx], 'E', 'W', ndec=ndec, decimal=decimal))
endfor


; plot vertical lines where trajectory reverses

latmin = min(lat, max=latmax)
lonmin = min(lon, max=lonmax)
dlat = latmax-latmin
dlon = (lonmax-lonmin) * cos((latmin+latmax)*!dpi/360.0D)
axcoord = dlat GE dlon ? lat : lon

nax = n_elements(axcoord)
if (reverselines && nax GE 3) then begin
	idx = where((axcoord[1:(nax-2)] - axcoord[0:(nax-3)]) $
		* (axcoord[1:(nax-2)] - axcoord[2:(nax-1)]) GT 0, cnt) + 1
	for i=0, cnt-1 do begin
		oplot, [t[idx[i]], t[idx[i]]], [yrange[0], yrange[1]], $
			color=linecolor
	endfor
endif


; draw axis

if (~noaxis) then begin
	axis, 0.0, ypos, xaxis=0, /normal, /xstyle, charsize=charsize, $
		xticks=nticks, xtickv=tickpos, xtickname=ticklab, $
		xminor=minor, color=axiscolor, charthick=charthick, $
		xthick=linethick
endif


end

