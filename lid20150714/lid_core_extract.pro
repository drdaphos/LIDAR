pro lid_core_extract, flight, coarse=coarse, angstrom=angstrom, $
	neph_rh_threshold=neph_rh_thresh, neph_tcorr=neph_tcorr, $
	psap_spot_diameter=psap_spot_diam, psap_Cflow=psap_Cflow, $
	frequency=frequency, coredata=coredata, verbose=verbose


@lid_settings.include


; input: mrfread parameters - see corresponding table
; data will be set to NaN when flag larger than in flagsaccept

params      = [618, 517, 520, 525, 529, 576, 574, 740, 782, 770, 771, 772, $
	760, 761, 768, 762, 763, 764, 648, 649, 723, 714, 715]

flagsaccept = [  0,   0,   0,   0,   2,   0,   0,   0,   0,   0,   0,   0, $
	  0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0]

; output structure

coredata0 = {time:0.0, timesec:0.0, lat:0.0, lon:0.0, alt:0.0, hdg:0.0, $
	pitch:0.0, roll:0.0, off_nadir:0.0, dist:0.0, orog:0.0, $
	tas:0.0, temp:0.0, tdew: 0.0, rh:0.0, press:0.0, $
	o3:0.0, so2:0.0, co:0.0, no:0.0, no2:0.0, nox:0.0, $
	neph_rh:0.0, neph_blue:0.0, neph_green:0.0, neph_red:0.0, $
	neph_angstrom:0.0, psap_green:0.0, ext_green:0.0, ssa_green:0.0, $
	ext_355:0.0, heimann_bt:0.0, wind_dir:0.0, wind_spd:0.0}


if (n_elements(flno) NE 1 && n_elements(flight) EQ 1) then begin
	lid_flight_select, flight, verbose=verbose
	lid_horace_read, verbose=verbose
endif else if (n_elements(flight) EQ 1) then begin
	info_str = string(flight, '(%"Additional argument ignored: %s.")')
	message, info_str, /continue
endif

if (n_elements(flno) NE 1 || n_elements(hor) LE 0) then $
	message, 'lid_flight_select and lid_horace_read must be called first.'


;;;;;;;;;;; options and keywords ;;;;;;;;;;;

coarse = keyword_set(coarse)

if (n_elements(frequency) NE 1) then frequency = 5

if (n_elements(angstrom) EQ 1) then angstrom=[angstrom, angstrom] $
	else if (n_elements(angstrom) NE 2) then $
	angstrom = (coarse ? [0.0D, 0.0D] : [2.0D, 1.0D])
; scattering and absorption angstrom exponents, respectively

if (n_elements(neph_rh_thresh) NE 1) then neph_rh_thresh = 50.0

if (n_elements(neph_tcorr) NE 1) then neph_tcorr = 1

if (n_elements(psap_spot_diam) EQ 1) then $
	psap_Cspot = cspot_calc(psap_spot_diam)

if (n_elements(psap_Cflow) NE 1) then psap_Cflow = 0.99
; current Cflow value as per Claire and Kate - e-mail on 8/1/2013

psap_linthresh = 5D-5
psap_smooth = 30
psap_shift  = 30

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


corefile_search = string( $
	format='(%"core_faam_%04d%02d%02d_v004_r?_%s_1hz.nc")', $
	yy, mth, dd, strlowcase(flno_core))

pushd, core_path
corefile = file_search(corefile_search, count=cnt, /fold_case)
popd
if (cnt GT 0) then begin
	corefile = corefile[cnt-1]
endif else begin
	message, 'No core file: ' + corefile_search, /continue
	return
endelse


openw, lgf, logfln, /get_lun, /append
printf, lgf, '--> LID_CORE_EXTRACT'

openw, info, infofln, /get_lun, /append
printf, info, ''

info_str = string(frequency, (coarse ? 'Coarse' : 'Fine'), angstrom, $
	format = '(%"Extracting core data (%d Hz) to SAV: %s particles; ' $
	+ 'Angstrom exponent: scatt %0.2f, abs %0.2f")')
if (verbose) then print, info_str
printf, lgf, info_str
printf, info, info_str

savfln = outfln + '_coredata.sav'

status = mrfread(core_path + corefln, params, data, flags, $
	start=takeoff, stop=landing, time=time)

; temperature before flag check so as not to lose any neph data
; note: if change the param list, then must change this index too!
temp_raw = reform(double(data[2,*]))

for i=0, n_elements(params)-1 do begin
	idx = where(flags[i,*] GT flagsaccept[i], cnt)
	if (cnt GT 0) then data[i,idx] = !values.f_nan
endfor

ndata = n_elements(time)
coredata1 = replicate(coredata0, ndata)

i=0
coredata1.time      = time/3600.0
coredata1.timesec   = time
coredata1.lat        = hor.lat
coredata1.lon        = hor.lon
coredata1.alt        = hor.alt
coredata1.hdg        = reform(double(data[i++,*]))
coredata1.pitch      = hor.ptc
coredata1.roll       = hor.rll
coredata1.off_nadir  = hor.ofn
coredata1.dist       = hor.dis
coredata1.orog       = hor.osf
coredata1.tas        = reform(double(data[i++,*]))
coredata1.temp       = reform(double(data[i++,*]))
non_deiced_temp      = reform(double(data[i++,*]))
coredata1.tdew       = reform(double(data[i++,*]))	; General Eastern
coredata1.press      = reform(double(data[i++,*]))
coredata1.o3         = reform(double(data[i++,*]))
coredata1.so2        = reform(double(data[i++,*]))
coredata1.co         = reform(double(data[i++,*]))
coredata1.no         = reform(double(data[i++,*]))
coredata1.no2        = reform(double(data[i++,*]))
coredata1.nox        = reform(double(data[i++,*]))
neph_press           = reform(double(data[i++,*]))
neph_temp            = reform(double(data[i++,*]))
neph_rh              = reform(double(data[i++,*]))
neph_blue_uncorr     = reform(double(data[i++,*]))
neph_green_uncorr    = reform(double(data[i++,*]))
neph_red_uncorr      = reform(double(data[i++,*]))
psap_green_uncorr    = reform(double(data[i++,*]))
psap_log_uncorr      = reform(double(data[i++,*]))
coredata1.heimann_bt = reform(double(data[i++,*]))

northward_wind       = reform(double(data[i++,*]))
eastward_wind        = reform(double(data[i++,*]))
coredata1.wind_spd   = sqrt(northward_wind^2 + eastward_wind^2)
coredata1.wind_dir   = (180/!pi) * atan(-eastward_wind, -northward_wind)
idx = where(coredata1.wind_dir LT 0, cnt)
if (cnt GT 0) then coredata1[idx].wind_dir += 360.0


;;;;;;;;;;; humidity calculations ;;;;;;;;;;

Tc  = coredata1.temp-273.15      ; temp in Celsius
Tdc = coredata1.tdew-273.15      ; dew in Celsius
Es  = 6.11 * 10.0 ^ (7.5*Tc/(237.7+Tc))
E   = 6.11 * 10.0 ^ (7.5*Tdc/(237.7+Tdc))
coredata1.rh = (E/Es) * 100.0


;;;;;;;;;;; SAMBBA neph case ;;;;;;;;;;;;;;;

if (yy EQ 2012 AND (mth EQ 9 OR mth EQ 10)) then begin
	sambba_neph, coredata1.timesec, neph_blue_uncorr, neph_green_uncorr, $
		neph_red_uncorr, neph_press, neph_temp, neph_rh=neph_rh, lgf
	neph_rh_thresh = 90.0
endif


;;;;;;;;;;; neph+psap corrections ;;;;;;;;;;

psap_temp = 273.15
psap_press = 1013.25

if (neph_tcorr) then begin
; Kate; correction can be a factor of 2 (Fennec B710)
	neph_fact = (coredata1.press / temp_raw) $
		* spike_filter(neph_temp/neph_press)
endif else begin
; Claire Ryder
	neph_fact = 1.0
endelse

psap_fact = (coredata1.press / temp_raw) * (psap_temp / psap_press)
nephpsap_fact = neph_fact / psap_fact

if (coarse) then begin
	neph_correct_coarse, neph_green_uncorr, neph_red_uncorr, $
		neph_blue_uncorr, neph_green, neph_red, neph_blue, $
		angstrom0, /quiet
endif else begin
	neph_correct_fine, neph_green_uncorr, neph_red_uncorr, $
		neph_blue_uncorr, neph_green, neph_red, neph_blue, $
		angstrom0, /quiet
endelse

idx = where(psap_green_uncorr GT psap_linthresh, cnt)
if (cnt GT 0) then psap_green_uncorr[idx] = psap_log_uncorr[idx]

psap_green_uncorr = smooth(psap_green_uncorr, psap_smooth, /nan, /edge_truncate)
psap_green_uncorr[0:(ndata-psap_shift-1)] = psap_green_uncorr[psap_shift:*]
psap_green_uncorr[(ndata-psap_shift):*] = 0.0

psap_correct, psap_green_uncorr, psap_green, $
	neph_green_uncorr*nephpsap_fact, neph_red_uncorr*nephpsap_fact, $
	Cspot=psap_Cspot, Cflow=psap_Cflow, /quiet

neph_blue  *= neph_fact
neph_green *= neph_fact
neph_red   *= neph_fact
psap_green *= psap_fact

idx = where(neph_rh GT neph_rh_thresh, cnt)
if (cnt GT 0) then begin
	neph_blue[idx]  = !values.f_nan
	neph_green[idx] = !values.f_nan
	neph_red[idx]   = !values.f_nan
	angstrom0[idx]  = !values.f_nan
endif

coredata1.neph_rh       = neph_rh
coredata1.neph_blue     = neph_blue
coredata1.neph_green    = neph_green
coredata1.neph_red      = neph_red
coredata1.neph_angstrom = angstrom0
coredata1.psap_green    = psap_green
coredata1.ext_green     = neph_green + psap_green
coredata1.ssa_green     = neph_green / coredata1.ext_green
coredata1.ext_355       = neph_blue * ((450.0 / 355.0) ^ angstrom[0]) $
	+ psap_green * ((550.0 / 355.0) ^ angstrom[1])

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


coredata = coredata1[0:*:frequency]
save, filename=savfln, coredata

printf, lgf, file_basename(savfln)

free_lun, info
free_lun, lgf

end

