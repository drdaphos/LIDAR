pro readhoracedata, dir=dir, takeoffdate=takeoffdate, $
	tim, alt_p, alt_gps, lat, lon, ptc, rll, alt_rad, $
	report_always=report_always

compile_opt strictarr, strictarrsubs

common rhd, timeback

if (n_elements(dir) NE 1) then dir=''
if (n_elements(takeoffdate) NE 3) then takeoffdate = [0, 0, 0]
if (n_elements(timeback) NE 1 || keyword_set(report_always)) then timeback = 0

horfl = string(format='(%"%shorace_%04d_%02d_%02d.dat")', $
	dir, takeoffdate[2], takeoffdate[1], takeoffdate[0])

if (~file_test(horfl, /read)) then begin
	message2, 'File ' + horfl + ' not found.', /continue
	tim     = [0.0D]
	alt_p   = [0.0D]
	alt_gps = [0.0D]
	lat     = [0.0D]
	lon     = [0.0D]
	ptc     = [0.0D]
	rll     = [0.0D]
	alt_rad = [0.0D]
	return
endif

data = read_ascii(horfl)
datadim = size(data.field1, /dimensions)

tim     = double(reform(data.field1[0,*]))
alt_p   = double(reform(data.field1[1,*]))
alt_gps = double(reform(data.field1[2,*]))
lat     = double(reform(data.field1[3,*]))
lon     = double(reform(data.field1[4,*]))
ptc     = double(reform(data.field1[5,*]))
rll     = double(reform(data.field1[6,*]))

if (datadim[0] GE 8) then alt_rad = double(reform(data.field1[7,*])) $
	else alt_rad = dblarr(datadim[1])

; check that data do not go back in time

ndata = n_elements(tim)

start = 0
stop  = ndata-1

idx = where(tim[1:*] LE tim[0:(ndata-2)], cnt) + 1
if (cnt GT 0) then start = idx[cnt-1]

if (start GT 0) then begin
	if (~timeback) then begin
		msg = string('Horace/Decades data go back in time in', $
			horfl, tim[start], format='(%"%s %s: %0.1f")')
		message2, msg, /continue
	endif
	timeback = 1
	tim     = tim[start:stop]
	alt_p   = alt_p[start:stop]
	alt_gps = alt_gps[start:stop]
	alt_rad = alt_rad[start:stop]
	lat     = lat[start:stop]
	lon     = lon[start:stop]
	ptc     = ptc[start:stop]
	rll     = rll[start:stop]
endif else begin
	if (timeback) then $
		message2, 'Horace/Decades data fixed. Thank you :-)', /continue
	timeback = 0
endelse

end
