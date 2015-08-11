pro plotflightinfo, flight, dd, mth, yy, cnt, id, $
	secs, alt, lat, lon, ptc, rll, radar_alt, aerok, $
	charsize=charsize, axischarsize=axischarsize, $
	charthick=charthick, linethick=linethick 

compile_opt strictarr, strictarrsubs

col27
tim = secs / 3600.0D
coli = indgen(cnt) mod 2
cols = 2 + coli + (1-aerok[0:(cnt-1)]) * (5 - 4*coli)
start  = id[0,0]
finish = id[cnt-1,1]
margin = min([(finish - start) / 2, 1000])
i1 = max([0, start-margin])
i2 = min([n_elements(tim)-1, finish+margin])
tit = string(format='(%"%s   %d-%d-%d")', flight, dd, mth, yy)
xtit = 'Time after midnight (h)'

; longitude, latitutde map

xmin = min(lon[start:finish], max=xmax, /nan)
ymin = min(lat[start:finish], max=ymax, /nan)
xd = (xmax-xmin)/5.0D
yd = (ymax-ymin)/5.0D
xmin -= xd
xmax += xd
ymin -= yd
ymax += yd
;plot, /nodata, lon[i1:i2], lat[i1:i2], xrange=[xmin,xmax], $
;	yrange=[ymin,ymax], title=tit, xtitle='Longitude', ytitle='Latitude', $
;	charsize=charsize, xcharsize=axischarsize, ycharsize=axischarsize, $
;	charthick=charthick, thick=linethick, xthick=linethick, ythick=linethick
setmap, latrange=[ymin, ymax], lonrange=[xmin,xmax], title=tit, $
	charsize=charsize, thick=linethick, charthick=charthick, $
	lon_title='Longitude', lat_title='Latitude'
oplot, lon[i1:i2], lat[i1:i2]
for i=0, cnt-1 do $
	oplot, lon[id[i,0]:id[i,1]], lat[id[i,0]:id[i,1]], col=cols[i], $
		thick=linethick

; aircraft altitude

xmin = min(tim[start:finish], max=xmax)
ymin = min(alt[start:finish], max=ymax)
plot, tim[i1:i2], alt[i1:i2], xrange=[xmin,xmax], yrange=[ymin,ymax], $
	title=tit, xtitle=xtit, ytitle='Aircraft altitude AMSL (m)', $
	charsize=charsize, xcharsize=axischarsize, $
	ycharsize=axischarsize, charthick=charthick, $
	thick=linethick, xthick=linethick, ythick=linethick
oplot, tim[i1:i2], radar_alt[i1:i2], max_value=2000.0D, col=4, thick=linethick
for i=0, cnt-1 do $
	oplot, tim[id[i,0]:id[i,1]], alt[id[i,0]:id[i,1]], col=cols[i], $
		thick=linethick

; pitch

ymin = min(ptc[start:finish], max=ymax)
plot, tim[i1:i2], ptc[i1:i2], xrange=[xmin,xmax], yrange=[ymin,ymax], $
	title=tit, xtitle=xtit, ytitle='Pitch (degrees)', $
	charsize=charsize, xcharsize=axischarsize, $
	ycharsize=axischarsize, charthick=charthick, $
	thick=linethick, xthick=linethick, ythick=linethick
for i=0, cnt-1 do $
	oplot, tim[id[i,0]:id[i,1]], ptc[id[i,0]:id[i,1]], col=cols[i], $
		thick=linethick

; roll

ymin = min(rll[start:finish], max=ymax)
plot, tim[i1:i2], rll[i1:i2], xrange=[xmin,xmax], yrange=[ymin,ymax], $
	title=tit, xtitle=xtit, ytitle='Roll (degrees)', $
	charsize=charsize, xcharsize=axischarsize, $
	ycharsize=axischarsize, charthick=charthick, $
	thick=linethick, xthick=linethick, ythick=linethick
for i=0, cnt-1 do $
	oplot, tim[id[i,0]:id[i,1]], rll[id[i,0]:id[i,1]], col=cols[i], $
		thick=linethick

end
