pro lid_pretrig_show, flight=flight, pos=pos, verbose=verbose

; go through lidar data files, and plot raw signal at pre-trigger
; works both with and without horace data having been read in
; (reading horace only adds the benefit of printing out altitude)
; (reading headers gives time past midnight - otherwise just time)

@lid_settings.include

if (n_elements(flno) NE 1) then begin
	if (n_elements(flight) EQ 1) then begin
		message, /continue, $
			string(flight, format='(%"Selecting flight %s.")')
		lid_flight_select, flight
	endif else begin
		message, 'No flight selected.'
	endelse
endif

horace  = (n_elements(hor) GT 0)
headers = (n_elements(nfiles) EQ 1 && nfiles GT 0)

openw, lgf, logfln, /get_lun, /append
printf, lgf, '--> LID_PRETRIG

pushd, lidar_path
lidar_file = file_search('*.raw', count=nlidf)
popd
if (nlidf LE 0) then message, 'No lidar data'

psfln = outfln + '_pretrig.ps'

set_plot, 'ps'
device, /color, /landscape, bits_per_pixel=8, filename=psfln
col27

charthick = 4
linethick = 4
charsize  = 1.15
axischarsize = 1.5
xstyle = 1
xrange = [2040,2150]
yrange = [-0.02, 0.1]
ytextpos = yrange[0] + 0.88 * (yrange[1] - yrange[0])
xtextmar = 0.005 * (xrange[1] - xrange[0])
;nchans = 4
nchans = 2
chans = indgen(nchans)

for j=0, nlidf-1 do begin

	openr, inp, lidar_path + lidar_file[j], /get_lun
	getheader_raw, inp, nprof=nprof, it=it0, res=res, nsign=nsign, $
		ad_gain=ad_gain, ad_offs=ad_offs, pct_gain=pct_gain, $
		blind=blindref0, cnt=blindcount

	blindref=smooth(blindref0, [1,blindsmooth], /edge_truncate)
	signal_raw = dblarr(4, blindcount)
	it = 0.0D
	for i=0, nprof-1 do begin
		getprofile_raw, inp, nsign, ad_gain, ad_offs, pct_gain, $
			signal_raw0, time=time, cnt=count
		if (count NE blindcount) then $
			message, 'Number of profile points varying...'
		signal_raw  += signal_raw0
		it += it0
		if (i EQ 0) then start_time = time
	endfor
	free_lun, inp

	signal_raw[0:1,*] /= nprof
	stop_time = time + ceil(it0)
	signal = signal_raw
	signal[0:1,*] -= blindref[*,*]

	if (headers) then begin
		f_idx = where(file.name EQ lidar_file[j], f_cnt)
		f_idx = f_idx[0]
	endif else f_cnt = 0

	if (f_cnt GT 0) then begin
		start_time += file[f_idx].toffs
		stop_time  += file[f_idx].toffs
	endif

	if (horace) then h_idx = where(hor.tim GE start_time $
		AND hor.tim LE stop_time, h_cnt)  else  h_cnt = 0

	if (h_cnt GT 0) then alt = mean(hor[h_idx].alt, /nan) $
		else alt = 0.0D

	if (start_time GE takeoff AND stop_time LE landing) then begin
		title = string(hhmmss(start_time), hhmmss(stop_time), $
			it, nprof, alt, $
			format='(%"%s - %s  %ds  %draw   %dm")')

		plot, signal[0,*], xrange=xrange, yrange=yrange, $
			xstyle=xstyle, ystyle=ystyle, title=title, $
			xtitle='Data bin', ytitle='Raw signal', $
			charsize=charsize, xcharsize=axischarsize, $
			ycharsize=axischarsize, charthick=charthick, $
			thick=linethick, xthick=linethick, ythick=linethick
		for i=1,nchans-1 do $
			oplot, signal[i,*] * signal[0,2150] / signal[i,2150], $
				color=1+i, thick=linethick
		oplot, [pre_trig, pre_trig], !y.crange, $
			color=6, thick=2*linethick
		xyouts, pre_trig-xtextmar, ytextpos, strtrim(pre_trig,2), $
			charsize=charsize, charthick=charthick, $
			orientation=90, color=6
		if (n_elements(pos) EQ 1) then begin
			oplot, [pos, pos], !y.crange, $
				color=22, thick=2*linethick
			xyouts, pos-xtextmar, ytextpos, strtrim(pos,2), $
				charsize=charsize, charthick=charthick, $
				orientation=90, color=22
		endif
		legend, string(chans, format='(%"Ch%d")'), linestyle=0, $
			color=[0,1+chans[1:*]], box=0, /right, $
			charsize=charsize, charthick=charthick, thick=linethick
	endif
endfor


@lid_plot_cleanup.include

end

