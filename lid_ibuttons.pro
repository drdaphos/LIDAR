pro lid_iButtons, fln=fln, legend=legend, file_begin=file_begin, $
	raw=raw, prof=prof, scatter=scatter, scatrange=scatrange, $
	scatmin=scatmin, scatname=scatname, display=display

; fln:          list of CSV iButtons files [strarr]
; legend:       legends to use in plots [strarr]
; file_begin:   pick all files with this beginning;
;               the rest of the filename is the legend [string]
; raw=1:        plot raw iButton data (as is in the file) [int]
; raw=[t1,t2]:  set trange for raw data plot [dblarr]
; prof=1:       plot iButton data for lidar profiles [int]
; prof=[t1,t2]: set trange for plot data plot [dblarr]
; scatter=y:    do scatter plot with given y variable [dblarr(nprofiles)]      
; scatmin:      y-threshold for data discard in the scatter plot [double]
; scatname:     y-axis title [string]


@lid_settings.include

common __iButtons, t_path, iButt, n_iButt, n_inter, $
	iButt_inter_jday, iButt_inter_temp, iButt_inter_dew, iButt_inter_rh


lidar_data = 1
bottom_legend = 1
right_legend  = 1
base = 'laser'
mint_ok = -100.0D

if (n_elements(nprofiles) NE 1 || nprofiles LE 1L) then begin
	lidar_data = 0
	nprofiles = 1
	logfln = '/tmp/lid_iButtons.log'
	outfln = '/tmp/lid_iButtons'
	prof = 0
	scatter = 0
endif

openw, lgf, logfln, /get_lun, /append
printf, lgf, '--> LID_iBUTTONS'
	

if (~keyword_set(prof) && ~keyword_set(raw) && ~keyword_set(scatter)) $
   then begin
	prof = lidar_data
	raw  = 1
endif

t_path = '/home/h02/frmo/Faam/iButtons/'
max_read = 8192
time_tolerance = 2
remove = '._ '
iButtonstit = 'iButtons'

if (n_elements(file_begin) EQ 1) then begin
	iButtonstit += ' ' + file_begin
	pushd, t_path
	fln = file_search(file_begin + '*.csv', count=nfiles, /fold_case)
	popd
	skip1 = strlen(file_begin)
	skip2 = strlen('.csv')
	legend = strarr(nfiles)
	for i=0, nfiles-1 do begin
		fln2 = strmid(fln[i], skip1, strlen(fln[i]) - skip1 - skip2)
		for k=0, strlen(fln2)-1 do begin
			c = strmid(fln2, k, 1)
			if (strpos(remove, c) LT 0) then break
		endfor
		fln2 = strmid(fln2, k)
		for k=strlen(fln2)-1, 0, -1 do begin
			c = strmid(fln2, k, 1)
			if (strpos(remove, c) LT 0) then break
		endfor
		fln2 = strmid(fln2, 0, k+1)
		legend[i] = fln2
	endfor
	cnt = 0
	if (keyword_set(base)) $
		then idx = where(strmatch(legend, base, /fold_case), cnt)
	if (cnt GT 0 && nfiles GT 1) then begin
		idx = idx[0]
		fln2       = strarr(nfiles)
		legend2    = strarr(nfiles)
		fln2[0]    = fln[idx]
		legend2[0] = legend[idx]
		if (idx EQ 0) then idx2 = 1 + indgen(nfiles-1) $
			else if (idx EQ nfiles-1) then idx2 = indgen(nfiles-1) $
			else idx2 = [indgen(idx), idx+1+indgen(nfiles-idx-1)]
		fln2[1:*]  = fln[idx2]
		legend2[1:*] = legend[idx2]
		fln    = fln2
		legend = legend2
	endif
endif

monthname = ['', 'January', 'February', 'March', 'April', 'May', 'June', $
	'July', 'August', 'September', 'October', 'November', 'December']


iButt0 = {file:'', serial:'', type:'', legend:'', n_header:0, $
	humidity:0, readings:0, sampling:0.0D, month:'', $
	raw:	{jday:replicate(_dundef_, max_read), $
		temp:replicate(_dundef_, max_read), $
		dew:replicate(_dundef_, max_read), $
		rh:replicate(_dundef_, max_read)}, $
	prof:	{temp:replicate(_dundef_, nprofiles), $
		dew:replicate(_dundef_, nprofiles), $
		rh:replicate(_dundef_, nprofiles)} }

n_iButt = n_elements(fln)
if (n_iButt LE 0) then message, 'No iButtons specified'
n_legend = n_elements(legend)

iButt = replicate(iButt0, n_iButt)


for i=0, n_iButt-1 do begin
	openr, inp, t_path + fln[i], /get_lun
	iButt[i].file = fln[i]
	if (i LT n_legend) then iButt[i].legend=legend[i] $
		else iButt[i].legend=fln[i]
	k = 0
	while (iButt[i].n_header LE 0) do begin
		readheader, inp, name, val, delimiter=',', maxargs=0
		case name of
			'logger type:':    iButt[i].type = val
			'serial number:':  iButt[i].serial = val
			'readings:':       iButt[i].readings = val
			'1':               iButt[i].n_header = k
			else:
		endcase
		++k
	endwhile
	jdate = replicate(_dundef_, iButt[i].readings)
	temp  = replicate(_dundef_, iButt[i].readings)
	dew   = replicate(_dundef_, iButt[i].readings)
	rh    = replicate(_dundef_, iButt[i].readings)
	nn = fix(strsplit(val[0], '/: ', count=ni, /extract))
	if (i EQ 0) then begin
		jdate0 = julday(nn[1], 1, nn[2], 0, 0, 0) - 1
		month0 = string(monthname[nn[1]], nn[2], format='(%"%s %d")')
	endif
	jdate[0] = julday(nn[1],nn[0],nn[2],nn[3],nn[4],nn[5])
	temp[0]  = val[1]
	if (n_elements(val) GT 2) then begin
		iButt[i].humidity = 1
		rh[0]   = val[2]
		dew[0]  = val[3]
	endif
	for k=1, iButt[i].readings-1 do begin
		readheader, inp, name, val, delimiter=',', maxargs=0
		nn = fix(strsplit(val[0], '/: ', count=ni, /extract))
		jdate[k] = julday(nn[1],nn[0],nn[2],nn[3],nn[4],nn[5])
		temp[k] = val[1]
		if (iButt[i].humidity) then begin
			rh[k]   = val[2]
			dew[k]  = val[3]
		endif
	endfor
	free_lun, inp

	idx = where(~finite(temp), cnt)
	if (cnt GT 0) then temp[idx] = _dundef_
	idx = where(~finite(dew), cnt)
	if (cnt GT 0) then dew[idx] = _dundef_
	idx = where(~finite(rh), cnt)
	if (cnt GT 0) then rh[idx] = _dundef_

	iButt[i].sampling = mean(jdate[1:*] - jdate[0:*]) * 1440.0D

	iButt[i].raw.jday[0:(iButt[i].readings-1)] = jdate - jdate0
	iButt[i].raw.temp[0:(iButt[i].readings-1)] = temp
	iButt[i].raw.dew[0:(iButt[i].readings-1)]  = dew
	iButt[i].raw.rh[0:(iButt[i].readings-1)]   = rh
	iButt[i].month = month0

	if (lidar_data) then begin
		profhh = fix(floor(profinfo.time / 3600L))
		profmm = fix(floor((profinfo.time MOD 3600L) / 60L))
		profss = fix(floor(profinfo.time MOD 60L))
		profjdate = julday(mth, dd, yy, profhh, profmm, profss)
		minprofjd = min(profjdate, max=maxprofjd)
		minrawjd = min(jdate, max=maxrawjd)
		idx = where(jdate GE minprofjd AND jdate LE maxprofjd, cnt)
		if (cnt GT 0) then begin
			iButt[i].prof.temp $
				= interpol(temp[idx], jdate[idx], profjdate)
			iButt[i].prof.dew  $
				= interpol(dew[idx], jdate[idx], profjdate)
			iButt[i].prof.rh   $
				= interpol(rh[idx], jdate[idx], profjdate)
		endif
		idx = where(profjdate LT minrawjd OR profjdate GT maxrawjd, cnt)
		if (cnt GT 0) then begin
			iButt[i].prof.temp[idx] = _dundef_
			iButt[i].prof.dew[idx]  = _dundef_
			iButt[i].prof.rh[idx]   = _dundef_
		endif
	endif
endfor


if (n_elements(prof) EQ 2) then begin
	prof_idx = where(profinfo.time/3600.0D GE prof[0] $
		AND profinfo.time/3600.0D LE prof[1], prof_cnt)
	if (prof_cnt LE 0) then message, 'No Prof data.'
	minhh = prof[0]
	maxhh = prof[1]
endif else if (lidar_data) then begin
	prof_idx = lindgen(nprofiles)
	minhh = floor(min(profinfo.time)/3600.0D - 0.1D)
	maxhh = ceil(max(profinfo.time)/3600.0D + 0.1D)
endif

minjd  = _dlarge_
maxjd  = _dsmall_
mint   = _dlarge_
maxt   = _dsmall_
mint2  = _dlarge_
maxt2  = _dsmall_
mindt2 = _dlarge_
maxdt2 = _dsmall_
minrh  = _dlarge_
maxrh  = _dsmall_
minrh2 = _dlarge_
maxrh2 = _dsmall_
for i=0, n_iButt-1 do begin
	raw_idx = lindgen(iButt[i].readings)
	raw_cnt = iButt[i].readings
	if (n_elements(raw) EQ 2) then begin
		raw_idx = where(iButt[i].raw.jday[raw_idx] GE raw[0] AND $
			iButt[i].raw.jday[raw_idx] LE raw[1], raw_cnt)
	endif
	if (raw_cnt GT 0) then begin
		minjd0 = min(iButt[i].raw.jday[raw_idx], max=maxjd0)
		minjd  = min([minjd, minjd0])
		maxjd  = max([maxjd, maxjd0])
		mint0  = min(iButt[i].raw.temp[raw_idx], max=maxt0)
		mint   = min([mint, mint0])
		maxt   = max([maxt, maxt0])
		if (iButt[i].humidity) then begin
			mint0  = min(iButt[i].raw.dew[raw_idx], max=maxt0)
			mint   = min([mint, mint0])
			maxt   = max([maxt, maxt0])
			minrh0 = min(iButt[i].raw.rh[raw_idx], max=maxrh0)
			minrh  = min([minrh, minrh0])
			maxrh  = max([maxrh, maxrh0])
		endif
	endif
	if (lidar_data) then begin
		pt2 = iButt[i].prof.temp[prof_idx]
		if (i EQ 0) then pt20 = pt2
		idx = where(pt2 GT mint_ok, cnt)
		if (cnt GT 0) then begin
			mint20 = min(pt2[idx], max=maxt20)
			mint2  = min([mint2, mint20])
			maxt2  = max([maxt2, maxt20])
		endif
		if (iButt[i].humidity) then begin
			pd2 = iButt[i].prof.dew[prof_idx]
			ph2 = iButt[i].prof.rh[prof_idx]
			idx = where(pd2 GT mint_ok AND ph2 GT mint_ok, cnt)
			if (cnt GT 0) then begin
				mint20  = min(pd2[idx], max=maxt20)
				mint2   = min([mint2, mint20])
				maxt2   = max([maxt2, maxt20])
				minrh20 = min(ph2[idx], max=maxrh20)
				minrh2  = min([minrh2, minrh20])
				maxrh2  = max([maxrh2, maxrh20])
			endif
		endif
		if (i GT 0) then begin
			idx = where(pt2 GT mint_ok AND pt20 GT mint_ok, cnt)
			if (cnt GT 0) then begin
				mindt20 = min(pt2[idx] - pt20[idx], max=maxdt20)
				mindt2 = min([mindt2, mindt20])
				maxdt2 = max([maxdt2, maxdt20])
			endif
		endif
	endif
endfor


inter_jd_step = max(iButt.sampling) / 1440.0D
inter_jd_min  = floor(minjd / inter_jd_step) * inter_jd_step
inter_jd_max  = ceil(maxjd / inter_jd_step) * inter_jd_step
n_inter = 1L + long(ceil((inter_jd_max - inter_jd_min) / inter_jd_step))

iButt_inter_jday = inter_jd_min + dindgen(n_inter) * inter_jd_step
iButt_inter_temp = replicate(_dundef_, n_inter, n_iButt)
iButt_inter_dew  = replicate(_dundef_, n_inter, n_iButt)
iButt_inter_rh   = replicate(_dundef_, n_inter, n_iButt)
for i=0, n_iButt-1 do begin
	idx = where(iButt_inter_jday GE iButt[i].raw.jday[0] $
		AND iButt_inter_jday LE iButt[i].raw.jday[iButt[i].readings-1])
	iButt_inter_temp[idx,i] $
		= interpol(iButt[i].raw.temp[0:(iButt[i].readings-1)], $
		iButt[i].raw.jday[0:(iButt[i].readings-1)], $
		iButt_inter_jday[idx])
	iButt_inter_dew[idx,i] $
		= interpol(iButt[i].raw.dew[0:(iButt[i].readings-1)], $
		iButt[i].raw.jday[0:(iButt[i].readings-1)], $
		iButt_inter_jday[idx])
	iButt_inter_rh[idx,i] $
		= interpol(iButt[i].raw.rh[0:(iButt[i].readings-1)], $
		iButt[i].raw.jday[0:(iButt[i].readings-1)], $
		iButt_inter_jday[idx])
endfor


mindt  = _dlarge_
maxdt  = _dsmall_
for i=1, n_iButt-1 do begin
	idx = where(iButt_inter_temp[*,0] GT mint_ok $
		AND iButt_inter_temp[*,i] GT mint_ok, cnt)
	if (cnt GT 0) then begin
		mindt0 = min(iButt_inter_temp[idx,i] $
			- iButt_inter_temp[idx,0], max=maxdt0)
		mindt = min([mindt, mindt0])
		maxdt = max([maxdt, maxdt0])
	endif
endfor


if (keyword_set(raw) && minjd GE _dlarge_ / 10.0D $
	|| maxjd LE _dsmall_ / 10.0D) then message, 'No Raw data.'

minjd  = floor(minjd - 0.1D)
maxjd  = ceil(maxjd + 0.1D)
mint   = floor(mint - 0.1D)
maxt   = ceil(maxt + 0.1D)
mindt  = floor(mindt - 0.1D)
maxdt  = ceil(maxdt + 0.1D)
mint2  = floor(mint2 - 0.1D)
maxt2  = ceil(maxt2 + 0.1D)
mindt2 = floor(mindt2 - 0.1D)
maxdt2 = ceil(maxdt2 + 0.1D)
minrh  = floor(minrh - 0.1D)
maxrh  = ceil(maxrh + 0.1D)
minrh2 = floor(minrh2 - 0.1D)
maxrh2 = ceil(maxrh2 + 0.1D)


if (n_elements(raw) EQ 2) then begin
	minjd = raw[0]
	maxjd = raw[1]
endif


psfln = outfln + '_iButtons.ps'
set_plot, 'ps'
device, /color, /landscape, bits_per_pixel=8, filename=psfln
col27
charthick = 4
linethick = 4
charsize  = 1.15
axischarsize = 1.5
barcharsize = 1.2
symsize = 1.2
cols = [4, 2, 3, 7, 8, 23]

if (keyword_set(raw)) then begin
	plot, iButt_inter_jday, iButt_inter_temp[*,0], min_value=mint_ok, $
		/nodata, xtitle='Day of '+month0, ytitle='Temperature (C)', $
		title=iButtonstit, /xstyle, /ystyle, $
		xrange=[minjd,maxjd], yrange=[mint,maxt], $
		charsize=charsize, xcharsize=axischarsize, $
		ycharsize=axischarsize, charthick=charthick, $
		thick=linethick, xthick=linethick, ythick=linethick
	for i=0, n_iButt-1 do oplot, iButt_inter_jday, iButt_inter_temp[*,i], $
		min_value=mint_ok, color=cols[i], thick=linethick
	legend, iButt.legend, color=cols[0:(n_iButt-1)], linestyle=0, $
		charthick=charthick, thick=linethick, $
		bottom_legend=bottom_legend, right_legend=right_legend, box=0

	plot, iButt_inter_jday, iButt_inter_temp[*,0], min_value=mint_ok, $
		/nodata, xtitle='Day of '+month0, ytitle='Temperature (C)', $
		title=iButtonstit, /xstyle, /ystyle, $
		xrange=[minjd,maxjd], yrange=[mint,maxt], $
		charsize=charsize, xcharsize=axischarsize, $
		ycharsize=axischarsize, charthick=charthick, $
		thick=linethick, xthick=linethick, ythick=linethick
	for i=0, n_iButt-1 do oplot, iButt_inter_jday, iButt_inter_temp[*,i], $
		min_value=mint_ok, color=cols[i], thick=linethick
	for i=0, n_iButt-1 do if (iButt[i].humidity) $
		then oplot, iButt_inter_jday, iButt_inter_dew[*,i], $
			min_value=mint_ok, color=cols[i], thick=linethick, $
			linestyle=1
	legend, iButt.legend, color=cols[0:(n_iButt-1)], linestyle=0, $
		charthick=charthick, thick=linethick, $
		bottom_legend=bottom_legend, right_legend=right_legend, box=0

	if (total(iButt.humidity) GT 0) then begin
		plot, iButt_inter_jday, iButt_inter_rh[*,0], min_value=mint_ok, $
			/nodata, title=iButtonstit, xtitle='Day of '+month0, $
			ytitle='Relative Humidity (%)', /xstyle, /ystyle, $
			xrange=[minjd,maxjd], yrange=[minrh,maxrh], $
			charsize=charsize, xcharsize=axischarsize, $
			ycharsize=axischarsize, charthick=charthick, $
			thick=linethick, xthick=linethick, ythick=linethick
		for i=0, n_iButt-1 do if (iButt[i].humidity) $
			then oplot, iButt_inter_jday, iButt_inter_rh[*,i], $
				min_value=mint_ok, color=cols[i], thick=linethick
		legend, iButt.legend, color=cols[0:(n_iButt-1)], linestyle=0, $
			charthick=charthick, thick=linethick, box=0, $
			bottom_legend=bottom_legend, right_legend=right_legend
	endif

	if (n_iButt GT 1) then begin
		plot, iButt_inter_jday, $
			iButt_inter_temp[*,1]-iButt_inter_temp[*,0], $
			min_value=mint_ok, /nodata, title=iButtonstit, $
			xtitle='Day of '+month0, ytitle='Temp. difference (C)',$
			/xstyle, /ystyle, xrange=[minjd,maxjd], $
			yrange=[mindt, maxdt], $
			charsize=charsize, xcharsize=axischarsize, $
			ycharsize=axischarsize, charthick=charthick, $
			thick=linethick, xthick=linethick, ythick=linethick
		for i=1, n_iButt-1 do oplot, iButt_inter_jday, $
			iButt_inter_temp[*,i]-iButt_inter_temp[*,0], $
			min_value=mint_ok, max_value=100, color=cols[i], $
			thick=linethick
		legend, iButt[1:*].legend + '-' + iButt[0].legend, $
			color=cols[1:(n_iButt-1)], linestyle=0, $
			charthick=charthick, thick=linethick, box=0, $
			bottom_legend=bottom_legend, right_legend=right_legend
	endif
endif

if (keyword_set(prof)) then begin
	plot, profinfo.time/3600.0D, iButt[0].prof.temp, min_value=mint_ok, $
		/nodata, title = globaltitle, xtitle='Time (h)', $
		ytitle='Temperature (C)', /xstyle, /ystyle, $
		xrange=[minhh, maxhh], yrange=[mint2,maxt2], $
		charsize=charsize, xcharsize=axischarsize, $
		ycharsize=axischarsize, charthick=charthick, $
		thick=linethick, xthick=linethick, ythick=linethick
	for i=0, n_iButt-1 do oplot, profinfo.time/3600.0D, iButt[i].prof.temp,$
		min_value=mint_ok, color=cols[i], thick=linethick
	for i=0, n_iButt-1 do if (iButt[i].humidity) $
		then oplot, profinfo.time/3600.0D, iButt[i].prof.dew, $
			min_value=mint_ok, color=cols[i], thick=linethick, $
			linestyle=1
	legend, iButt.legend, color=cols[0:(n_iButt-1)], linestyle=0, $
		charthick=charthick, thick=linethick, box=0, $
		bottom_legend=bottom_legend, right_legend=right_legend

	if (total(iButt.humidity) GT 0) then begin
		plot, profinfo.time/3600.0D,iButt[0].prof.rh,min_value=mint_ok,$
			/nodata, title=globaltitle, xtitle='Time (h)', $
			ytitle='Relative Humidity (%)', /xstyle, /ystyle, $
			xrange=[minhh,maxhh], yrange=[minrh2,maxrh2], $
			charsize=charsize, xcharsize=axischarsize, $
			ycharsize=axischarsize, charthick=charthick, $
			thick=linethick, xthick=linethick, ythick=linethick
		for i=0, n_iButt-1 do if (iButt[i].humidity) $
			then oplot, profinfo.time/3600.0D, iButt[i].prof.rh, $
				min_value=mint_ok,color=cols[i],thick=linethick
		legend, iButt.legend, color=cols[0:(n_iButt-1)], linestyle=0, $
			charthick=charthick, thick=linethick, box=0, $
			bottom_legend=bottom_legend, right_legend=right_legend
	endif

	if (n_iButt GT 1) then begin
		plot, profinfo.time/3600.0D, $
			iButt[1].prof.temp-iButt[0].prof.temp, $
			min_value=mint_ok, /nodata, title = globaltitle, $
			xtitle='Time (h)', ytitle='Temp. difference (C)', $
			/xstyle, /ystyle, xrange=[minhh, maxhh], $
			yrange=[mindt2,maxdt2], $
			charsize=charsize, xcharsize=axischarsize, $
			ycharsize=axischarsize, charthick=charthick, $
			thick=linethick, xthick=linethick, ythick=linethick
		for i=1, n_iButt-1 do oplot, profinfo.time/3600.0D, $
			iButt[i].prof.temp-iButt[0].prof.temp, $
			min_value=mint_ok, color=cols[i], thick=linethick
		legend, iButt[1:*].legend + '-' + iButt[0].legend, $
			color=cols[1:(n_iButt-1)], linestyle=0, $
			charthick=charthick, thick=linethick, box=0, $
			bottom_legend=bottom_legend, right_legend=right_legend
	endif
endif

if (keyword_set(scatter)) then begin
	if (n_elements(scatter) NE nprofiles) then message, 'Scatter dimension.'
	for i=0, n_iButt-1 do begin
		idx = where(iButt[i].prof.temp[prof_idx] GT mint_ok, cnt)
		if (cnt LE 0) then continue
		prof_idx2 = prof_idx[idx]
		plot, iButt[i].prof.temp[prof_idx2], scatter[prof_idx2], $
			min_value=scatmin, title=globaltitle, psym=4, $
			xtitle=iButt[i].legend + ' Temperature (C)', $
			ytitle=scatname, /ystyle, yrange=scatrange, $
			charsize=charsize, xcharsize=axischarsize, $
			ycharsize=axischarsize, charthick=charthick, $
			thick=linethick, xthick=linethick, ythick=linethick, $
			symsize=symsize
		oplot, iButt[i].prof.temp[prof_idx2], scatter[prof_idx2], $
			min_value=scatmin, thick=linethick

		if (iButt[i].humidity) then begin
			plot, iButt[i].prof.dew[prof_idx2], scatter[prof_idx2],$
				min_value=scatmin, title=globaltitle, psym=4, $
				xtitle=iButt[i].legend + ' Dew point (C)', $
				ytitle=scatname, /ystyle, yrange=scatrange, $
				charsize=charsize, xcharsize=axischarsize, $
				ycharsize=axischarsize, charthick=charthick, $
				thick=linethick, xthick=linethick, $
				ythick=linethick, symsize=symsize
			oplot, iButt[i].prof.dew[prof_idx2],scatter[prof_idx2],$
				min_value=scatmin, thick=linethick

			plot, iButt[i].prof.rh[prof_idx2], scatter[prof_idx2], $
				min_value=scatmin, title=globaltitle, psym=4, $
				xtitle=iButt[i].legend+' Relative Humidity', $
				ytitle=scatname, /ystyle, yrange=scatrange, $
				charsize=charsize, xcharsize=axischarsize, $
				ycharsize=axischarsize, charthick=charthick, $
				thick=linethick, xthick=linethick, $
				ythick=linethick, symsize=symsize
			oplot, iButt[i].prof.rh[prof_idx2],scatter[prof_idx2],$
				min_value=scatmin, thick=linethick
		endif
	endfor
endif

@lid_plot_cleanup.include


end


