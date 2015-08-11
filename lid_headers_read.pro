pro lid_headers_read, verbose=verbose

; go through file headers, associate with aicraft data,
; and build header info database

@lid_settings.include

if (n_elements(flno) NE 1 || n_elements(hor) LE 0) then $
	message, 'lid_flight_select and lid_horace_read must be called first.'


openw, lgf, logfln, /get_lun, /append
printf, lgf, '--> LID_READ_HEADERS'

openw, info, infofln, /get_lun, /append
printf, info, ''

pushd, lidar_path
lidar_file = file_search('*.raw', count=nfiles)
popd
if (nfiles LE 0) then message, 'No lidar data'


tmp = {lidarfileinfo, $
	name:'', start:0L, stop:0L, duration:0L, toffs:0L, nprof:0, $
	cnt:0L, it:0.0D, res:0.0D, alt:0.0D, lat:0.0D, lon:0.0D, ofn:0.0D}

file2 = replicate({lidarfileinfo}, nfiles)


k = 0
firstprof = 1
oldtime   = 0L
lidartimeoffs = 0L
for j=0, nfiles-1 do begin

	openr, inp, lidar_path + lidar_file[j], /get_lun
	getheader_raw, inp, start=file_start0, stop=file_stop0, $
		nprof=file_nprof0, it=file_it0, cnt=file_cnt0, $
		res=file_res0, /get_time
	free_lun, inp

	if (firstprof && file_start0 LT takeoff $
	   && file_start0 + 86400L GE takeoff $
	   && file_start0 + 86400L LE landing) then begin
		info_str = 'Measurements start on next day'
		printf, lgf, info_str
		if (keyword_set(verbose)) then message, info_str, /continue
		lidartimeoffs = 86400L
	endif
	file_start0 += lidartimeoffs
	file_stop0  += lidartimeoffs
	if (file_start0 LT oldtime) then begin
		info_str = 'Midnight encountered.'
		printf, lgf, info_str
		if (keyword_set(verbose)) then message, info_str, /continue
		lidartimeoffs += 86400L
		file_start0 += 86400L
		file_stop0  += 86400L
	endif
	firstprof = 0
	oldtime = file_start0

	if (file_start0 LT takeoff OR file_stop0 GT landing) then begin
		printf, lgf, format='(%"Skipping %s")', lidar_file[j]
		continue
	endif
	file2[k].name  = lidar_file[j]
	file2[k].start = file_start0
	file2[k].stop  = file_stop0
	file2[k].toffs = lidartimeoffs
	file2[k].nprof = file_nprof0
	file2[k].it    = file_it0
	file2[k].cnt   = file_cnt0 - pre_trig
	file2[k].res   = file_res0
	index = where(hor.tim GE file_start0 AND hor.tim LE file_stop0, cnt)
	if (cnt LE 0) then $
		message, 'Cannot associate aircraft data to ' + file2[k].name
	index = index[0]
	file2[k].alt = hor[index].alt
	file2[k].lat = hor[index].lat
	file2[k].lon = hor[index].lon
	file2[k].ofn = hor[index].ofn
	++k
endfor

file2.duration = file2.stop - file2.start + 1L

nfiles = k
file = file2[0:(k-1)]
if (nfiles LE 0) then message, 'Lidar data are ouside takeoff-landing interval'

global_nproftot = long(total(file[0:(k-1)].nprof))
global_nprofmin = min(file[0:(k-1)].nprof,    max=global_nprofmax)
global_itmin    = min(file[0:(k-1)].it,       max=global_itmax)
global_cntmin   = min(file[0:(k-1)].cnt,      max=global_cntmax)
global_resmin   = min(file[0:(k-1)].res,      max=global_resmax)
global_durmin   = min(file[0:(k-1)].duration, max=global_durmax)

info_str = string(format='(%"%d raw signal profiles in %d files ' $
	+ '(%8s - %8s)")', global_nproftot, nfiles, hhmmss(file[0].start), $
	hhmmss(file[nfiles-1].stop))
printf, lgf, info_str
printf, info, info_str
if (keyword_set(verbose)) then print, info_str

info_str = string(format='(%"Raw data integration time: %d-%d s")', $
	global_itmin, global_itmax)
printf, lgf, info_str
printf, info, info_str
if (keyword_set(verbose)) then print, info_str

info_str = string(format='(%"File duration: %d-%d s")', $
	global_durmin, global_durmax)
printf, lgf, info_str
printf, info, info_str
if (keyword_set(verbose) && verbose GE 2) then print, info_str

info_str = string(format='(%"Raw profiles per file: %d-%d raw")', $
	global_nprofmin, global_nprofmax)
printf, lgf, info_str
printf, info, info_str
if (keyword_set(verbose) && verbose GE 2) then print, info_str

info_str = string(format='(%"Data points per profile: %d-%d pt")', $
	global_cntmin, global_cntmax)
printf, lgf, info_str
printf, info, info_str
if (keyword_set(verbose) && verbose GE 2) then print, info_str

info_str = string(format='(%"Range resolution: %3.1f-%3.1f m")', $
	global_resmin, global_resmax)
printf, lgf, info_str
printf, info, info_str
if (keyword_set(verbose) && verbose GE 2) then print, info_str

printf, info, ''

for k=0, nfiles-1 do begin
	info_str = string(format='(%"%4d) %8s %8s %8s %5dm %4ds %3draw %2ds ' $
		+ '%5dpt %3.1fm %d°")', k, hhmmss(file[k].start), $
		dectomin(file[k].lat, 'N', 'S', ndec=0), $
		dectomin(file[k].lon, 'E', 'W', ndec=0), file[k].alt, $
		file[k].duration, file[k].nprof, file[k].it, $
		file[k].cnt, file[k].res, file[k].ofn)
	printf, lgf, info_str
	printf, info, info_str
endfor

free_lun, info
free_lun, lgf


end

