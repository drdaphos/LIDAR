pro lid_horace_read, core=core, horace=horace, $
	press_alt=press_alt, no_gin=no_gin, aimms=use_aimms, verbose=verbose
;
; default behaviour is try reading core and if it does not exist read horace
; if /horace, ignore core; if /core, ignore horace
;


@lid_settings.include

if (n_elements(flno) NE 1) then $
	message, 'No flight selected. lid_flight_select must be called first.'


openw, lgf, logfln, /get_lun, /append
printf, lgf, '--> LID_HORACE_READ'


tmp = {generalflightinfo, $
	tim:0.0D, alt:0.0D, lat:0.0D, lon:0.0D, ptc:0.0D, rll:0.0D, $
	rhg:0.0D, ofn:0.0D, con:0.0D, dis:0.0D, osf:0.0D, rsf:0.0D, $
	invalid:0B}


; bypass core/horace data if ground based

if (gnd_based) then begin

	n = long(landing - takeoff + 1.0D)
	hor = replicate({generalflightinfo}, n)

	hor.tim = takeoff + dindgen(n)
	hor.alt = gnd_alt
	hor.lat = gnd_lat
	hor.lon = gnd_lon
	hor.con = cos(gnd_offzenith * !dpi / 180.0D)

	hor.rhg = replicate(_hundef_, n)

	info_str = string($
		format='(%"Ground based - Altitude %dm")', gnd_alt)
	printf, lgf, info_str
	if (keyword_set(verbose)) then print, info_str

	goto, skip

endif



; determine which file we are going to use

msg = ''
coretried = 0

if (~keyword_set(horace)) then begin

	coretried = 1

	corefile_search = string( $
		format='(%"core_faam_%04d%02d%02d_v004_r?_%s_1hz.nc")', $
		yy, mth, dd, strlowcase(flno_core))

	pushd, core_path
	corefile = file_search(corefile_search, count=cnt, /fold_case)
	popd
	if (cnt GT 0) then begin
		corefile = corefile[cnt-1]
	endif else begin
		corefile = corefile_search
	endelse

	if (cnt LE 0 ||  $
	   ~file_test(core_path + corefile, /read, /regular)) then begin
		msg += corefile + ' '
		if (keyword_set(core)) then begin
			message, msg + 'not found or not readable'
		endif else begin
			horace = 1
		endelse
	endif

endif

if (keyword_set(horace)) then begin

	horacefile = string(format='(%"horace_%04d_%02d_%02d.dat")',yy,mth,dd)

	if (~file_test(horc_path + horacefile, /read, /regular)) then begin
		msg += horacefile + ' '
		message, msg + 'not found or not readable'
	endif else if (coretried) then begin
		info_str = msg + 'not found; using ' + horacefile
		printf, lgf, info_str
		message, info_str, /continue
	endif

endif


if (~keyword_set(horace)) then begin

; option 1 - read 1 Hz core data file downloaded from Faam

	info_str = 'Reading aircraft data from ' + corefile
	printf, lgf, info_str
	if (keyword_set(verbose)) then print, info_str
	corefln = corefile

	params = [612, 610, 611, 618, 617, 616, $
		582, 580, 581, 562, 561, 560, 575, 578]
	status = mrfread(core_path + corefln, params, data, flags, $
		start=takeoff, stop=landing, time=tim2)

	info_str = ''

	if (keyword_set(no_gin)) then begin
		info_str = 'No-GIN option selected. Will use backup GPS.'
		data[0:5,*] = data[6:11,*]
	endif else begin
		for i=0, 5 do begin
			index  = where(flags[i,*] NE 0  $
				OR  ~finite(data[i,*]), cnt)
			if (cnt GE 1) then begin
				info_str = 'Some navigation data missing. ' $
				   + 'Will try to fill gaps with backup GPS.'
				data[i,index]  = data[i+6, index]
			endif
		endfor
	endelse

	if (info_str NE '') then begin
		printf, lgf, info_str
		message, info_str, /continue
	endif

	if (keyword_set(press_alt)) then begin
		data[0,*] = data[13,*]
		info_str = 'Pressure altitude option selected instead of GPS.'
		printf, lgf, info_str
		message, info_str, /continue
	endif

	n = n_elements(tim2)
	hor = replicate({generalflightinfo}, n)

	hor.tim = double(tim2)
	hor.alt = reform(double(data[0,*]))
	hor.lat = reform(double(data[1,*]))
	hor.lon = reform(double(data[2,*]))
	hdg     = reform(double(data[3,*]))
	hor.ptc = reform(double(data[4,*]))
	hor.rll = reform(double(data[5,*]))
	hor.rhg = reform(double(data[12,*]))

	index = where(flags[12,*] NE 0, cnt)
	if (cnt GE 1) then hor[index].rhg = _hundef_

endif else begin

; option 2 - read horace data file produced by the on-board viewer lidardisplay
; data will be interpolated to 1 Hz

	info_str = 'Reading aircraft data from ' + horacefile
	printf, lgf, info_str
	if (keyword_set(verbose)) then print, info_str

	readhoracedata, dir=horc_path, takeoffdate=[dd,mth,yy], $
		tim2, alt2press, alt2, lat2, lon2, ptc2, rll2, rhg2, $
		/report_always

	if (keyword_set(press_alt)) then begin
		alt2 = alt2press
		info_str = 'Pressure altitude option selected instead of GPS.'
		printf, lgf, info_str
		message, info_str, /continue
	endif

	idx = where(finite(tim2) AND finite(alt2), cnt)
	t1 = floor(tim2[idx[0]])
	t2 = ceil(tim2[idx[cnt-1]])
	n = long(t2 - t1 + 1.0D)
	hor = replicate({generalflightinfo}, n)

	hor.tim = t1 + dindgen(n)
	hor.alt = interpol(alt2[idx], tim2[idx], hor.tim)
	hor.lat = interpol(lat2[idx], tim2[idx], hor.tim)
	hor.lon = interpol(lon2[idx], tim2[idx], hor.tim)
	hor.ptc = interpol(ptc2[idx], tim2[idx], hor.tim)
	hor.rll = interpol(rll2[idx], tim2[idx], hor.tim)
	hor.rhg = interpol(rhg2[idx], tim2[idx], hor.tim)

endelse

if (keyword_set(use_aimms)) then begin
	info_str = 'Using AIMMS GPS for aircraft position.'
	printf, lgf, info_str
	if (keyword_set(verbose)) then print, info_str

	lid_aimms_read, lgf=lgf, aimms=aimms, verbose=verbose
	hor.alt = aimms.alt
	hor.lat = aimms.lat
	hor.lon = aimms.lon
	;hor.ptc = aimms.ptc	; not validated
	;hor.rll = aimms.rll	; not validated
endif

latint = hor.lat
lonint = hor.lon

; flag and fix invalid data

index = where(~finite(hor.alt), cnt, complement=valid, ncomplement=nvalid)
if (nvalid LE 0) then message, 'No valid altitude data!'
if (cnt GT 1) then begin
	hor[index].alt = $
		interpol(hor[valid].alt, hor[valid].tim, hor[index].tim)
	hor[index].invalid = 1
	info_str = 'Some altitude data are undefined. Interpolated.'
	printf, lgf, info_str
	message, info_str, /continue
endif

index = where(~finite(hor.ptc) OR ~finite(hor.rll), cnt)
if (cnt GT 1) then begin
	hor[index].ptc = 0.0D
	hor[index].rll = 0.0D
	hor[index].invalid = 1
	info_str = 'Some pitch/roll data are undefined. Set to zero.'
	printf, lgf, info_str
	message, info_str, /continue
endif

index = where(~finite(hor.lat) OR ~finite(hor.lon) $
	OR (hor.lat EQ 0.0D AND hor.lon EQ 0.0D), cnt, $
	complement=valid, ncomplement=nvalid)
if (cnt GT 1) then begin
	latint[index] = interpol(hor[valid].lat, hor[valid].tim, hor[index].tim)
	lonint[index] = interpol(hor[valid].lon, hor[valid].tim, hor[index].tim)
	hor[index].lat = !values.d_nan
	hor[index].lon = !values.d_nan
	hor[index].invalid = 1
	info_str = 'Some latitude/longitude data are undefined.'
	printf, lgf, info_str
	message, info_str, /continue
endif

index = where(hor.alt LT ymin, cnt)
if (cnt GT 0) then begin
	info_str = 'Some altitudes are too small!'
	printf, lgf, info_str
	message, info_str, /continue
endif

index = where(hor.alt GT ymax, cnt)
if (cnt GT 0) then begin
	info_str = 'Some altitudes are too large!'
	printf, lgf, info_str
	message, info_str, /continue
endif


; off-nadir angle

hor.con = cos((hor.ptc-pitch_offset)*!dpi/180.0D) * cos(hor.rll*!dpi/180.0D)


; geoid correction

avg_lat = mean(hor.lat, /nan)
avg_lon = mean(hor.lon, /nan)

if (keyword_set(geoid_corr)) then begin
	if (!version.os_family EQ 'unix') then begin
		cmd = './' + intpt_ux
		tmpfl = '/tmp/intpt.inp'
	endif else begin
		cmd = '.\' + intpt_win
		tmpfl = tmpdir + 'intpt.inp'
	endelse
	geoid = 0.0D
	openw, dat, tmpfl, /get_lun
	printf, dat, format='(%"%12.8f %12.8f")', avg_lat, avg_lon
	free_lun, dat
	pushd, f77_path
	spawn, cmd, geoid
	popd
	geoid = double(geoid[0])
	;geoid = read_ascii(tmpdir + 'intpt.out')
	hor.alt -= geoid

	info_str = string(format='(%"AVGLAT=%7.3f   AVGLON=%7.3f   ' $
		+ 'GEOID=%6.1fm")', avg_lat, avg_lon, geoid)
endif else begin
	info_str = string(format='(%"AVGLAT=%7.3f   AVGLON=%7.3f   ' $
		+ '*** geoid correction disabled ***")', avg_lat, avg_lon)
endelse

printf, lgf, info_str
if (keyword_set(verbose)) then print, info_str


; compute along-track distance

inc_distance = sqrt((latint[1:*] - latint)^2 $
	+ cos(!dpi * (latint + latint[1:*]) / 360.0D)^2 $
	* (lonint[1:*] - lonint)^2) * 60.0D * 1852.0D
idx = where(~finite(inc_distance) $
	OR inc_distance GT (hor[1:*].tim - hor.tim) * 3.0D * default_speed, cnt)
if (cnt GT 0) then $
	inc_distance[idx] = (hor[idx+1].tim - hor[idx].tim) * default_speed
hor[0].dis   = 0.0D
hor[1:*].dis = total(inc_distance, /cumulative)


skip:

n = n_elements(hor)


; orography
if (orogfln NE '') then begin
	info_str = string(format='(%"Orography: %s")', orogfln)
	printf, lgf, info_str
	if (keyword_set(verbose)) then print, info_str

	; the restore produces the arrays orog_lat, orog_lon, orog_surf
	restore, orog_path + orogfln

	hor.osf = interpolate2d(hor.lon, hor.lat, $
		orog_lon, orog_lat, orog_surf, outbound=_hundef_)
endif else begin
	hor.osf = _hundef_
endelse


; compute some other flight info

hor.rsf = hor.alt - hor.rhg		; surface (radar)
index = where(hor.rhg LE -2000.0D OR hor.alt GE 2000.0D)
hor[index].rsf = _hundef_
hor.ofn = acos(hor.con) * 180.0D / !dpi


free_lun, lgf


end
