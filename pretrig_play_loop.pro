pro pretrig_play_loop

dir = '/data/local/frmo/Faam_data/lidar_processed/2012-03-10_B679/'
prefix = '2012-03-10_B679_'
flight = 'B679'
start = 9.45
stop  = 9.5
prof = 0
norm_range = [1750.0, 2750.0]
xrange = [0,1200]
yrange = [4000, 9500]
pretrig = [2054, 2060, 2070, 2080, 2090, 2100, 2120]
npretrig = n_elements(pretrig)
ovl = [0, 300, 600, 1000, 1500]
novl = n_elements(ovl)
xmargin = 50
ymargin = 30

cols = [2,3,4,7,8,9,12,15,20,10,23,19]

ps_plot, fln = dir + 'pretrig_play.ps'

for i=0, npretrig-1 do begin
;	lid_pretrig_play, flight, start=start, stop=stop, pretrig=pretrig[i], $
;		xrange=xrange, yrange=yrange, display=0
	restore, dir + prefix + string(pretrig[i], format='(%"skip%d.sav")')
	info   = strsplit(lidar_info.title, /extract)
	con = cos(lid_offnadir[prof] * !pi / 180.0)
	hgt = lid_height
	ran = (lid_altitude[prof] - hgt) / con
	rayleigh, reverse(hgt), pr2=mol, cos_offnadir = con
	mol = reverse(mol)
	idx = where(ran GE norm_range[0] AND ran LE norm_range[1], cnt)
	kmol = normalize(lid_pr2[prof,*,0], mol, idx[[0,cnt-1]], 0.0)
	mol *= kmol
	plot, lid_pr2[prof,*,0], lid_height, xrange=xrange, $
		yrange=yrange, /xstyle, /ystyle, $
		xtitle='PR2', ytitle='Altitude (m)', $
		title=string(info[0:1], hhmmss(lid_time[prof]), pretrig[i], $
		format='(%"%s %s %s Pretrig=%d")')
	oplot, mol, hgt, color=6
	for j=0, novl-1 do begin
		yline = lid_altitude[prof]-ovl[j]
		oplot, !x.crange, [yline, yline], color = cols[j]
		xyouts, !x.crange[1]-xmargin, yline+ymargin, alignment=1, $
			string(ovl[j], format='(%"%d m")'), color = cols[j]
	endfor
endfor

ps_plot, /close, /display, /gzip

end
