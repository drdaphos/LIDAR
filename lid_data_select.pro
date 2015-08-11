pro lid_data_select, start=start, stop=stop, $
	it=it, smooth=smooth0, verbose=verbose

@lid_settings.include

openw, lgf, logfln, /get_lun, /append
printf, lgf, '--> LID_DATA_SELECT'

openw, info, infofln, /get_lun, /append
printf, info, ''

if (n_elements(nfiles) NE 1 || nfiles LE 0) then $
	message, 'No file information. lid_headers_read must be called first.'


; start-stop interval

if (n_elements(start) EQ 1) then begin
	tstart = start * 3600.0D
endif else begin
	tstart = takeoff
endelse

if (n_elements(stop) EQ 1) then begin
	tstop = stop * 3600.0D
endif else begin
	tstop = landing
endelse

if (tstop LT tstart) then message, 'stop must be later than start'

file_idx = where(file[0:(nfiles-1)].stop GE tstart $
	AND file[0:(nfiles-1)].start LE tstop, file_n)
if (file_n LE 0) then message, 'No files selected.'

nraw = total(file[file_idx].nprof)

info_str = string(format='(%"Interval: %8s - %8s ' $
	+ '(%d files, containing %d raw profiles).")', $
	hhmmss(tstart), hhmmss(tstop), file_n, nraw)
printf, lgf, info_str
printf, info, info_str
if (keyword_set(verbose)) then print, info_str


; integration time and smooth

if (n_elements(it)) EQ 1 then begin
	target_it = double(it)
endif else begin
	target_it = default_it
endelse

if (n_elements(smooth0)) EQ 1 then begin
	smooth = fix(smooth0)
endif else begin
	smooth = default_smooth
endelse

info_str = string(format='(%"Target integration time: %d s. Smooth: %d sm")', $
	target_it, smooth)
printf, lgf, info_str
printf, info, info_str
if (keyword_set(verbose)) then print, info_str


; determine integration pattern estimate
; will integrate across files upon certain conditions

raw_start  = dblarr(nraw)
raw_k      = lonarr(nraw)

prof_nraw  = lonarr(nraw)
prof_it    = dblarr(nraw)
prof_start = dblarr(nraw)
prof_stop  = dblarr(nraw)
prof_cnt   = lonarr(nraw)
prof_res   = dblarr(nraw)

j = 0L
for i=0, file_n-1 do begin
	k = file_idx[i]
	np = file[k].nprof
	raw_start[j:(j+np-1)] = file[k].start + file[k].it * dindgen(np)
	raw_k[j:(j+np-1)]     = k
	j += np
endfor
nj = j


j = 0L
p = 0L
while (j LT nj) do begin
	nint = max([fix(ceil(target_it / file[raw_k[j]].it)), 1])
	i = 0
	j0 = j
	repeat begin
		++i
		++j
		integrate = (i LT nint  &&  j LT nj               $
		   &&  raw_start[j] GE raw_start[j0]              $
		   &&  raw_start[j] + file[raw_k[j]].it           $
		     LE raw_start[j0] + 1.5D * target_it          $
		   &&  file[raw_k[j]].it EQ file[raw_k[j0]].it    $
		   &&  file[raw_k[j]].cnt EQ file[raw_k[j0]].cnt  $
		   &&  file[raw_k[j]].res EQ file[raw_k[j0]].res)
	endrep until (~integrate)
;	if (i LE 0) then continue
	prof_nraw[p]  = i
	prof_it[p]    = i * file[raw_k[j0]].it
	prof_start[p] = raw_start[j0]
	prof_stop[p]  = raw_start[j0] + prof_it[p] - 1.0D
	prof_cnt[p]   = file[raw_k[j0]].cnt
	prof_res[p]   = file[raw_k[j0]].res
	if (prof_start[p] GE tstart && prof_stop[p] LE tstop $
	   && prof_it[p] GE 0.5 * target_it) then $
		++p
endwhile

nproftot = p

if (nproftot GT 0) then begin
	nrawtot = total(prof_nraw[0:(p-1)])
	minit   = min(prof_it[0:(p-1)], max=maxit)
	mincnt  = min(prof_cnt[0:(p-1)], max=maxcnt)
	minres  = min(prof_res[0:(p-1)], max=maxres)
	trange  = string(format='(%";  %s - %s")', hhmmss(prof_start[0]), $
		hhmmss(prof_stop[p-1]))
endif else begin
	message, 'No profiles selected', /continue
	nrawtot = 0L
	minit   = 0.0D
	maxit   = 0.0D
	mincnt  = 0L
	maxcnt  = 0L
	minres  = 0.0D
	maxres  = 0.0D
	trange  = ''
endelse
	

info_str = string(format='(%"Integrated dataset estimate: %d pr (%d raw) %s")',$
	nproftot, nrawtot, trange)
printf, lgf, info_str
if (keyword_set(verbose) && verbose GE 2) then print, info_str

info_str = string(format='(%"Integration times: %d - %d s")', minit, maxit)
printf, lgf, info_str
if (keyword_set(verbose) && verbose GE 2) then print, info_str

info_str = string(format='(%"Points per profile and range resolution: ' $
	+ '%d - %d pt, %3.1f - %3.1f m")', mincnt, maxcnt, minres, maxres)
printf, lgf, info_str
if (keyword_set(verbose) && verbose GE 2) then print, info_str


; flight info

idx = where(hor.tim GE tstart AND hor.tim LE tstop, flight_n)
if (flight_n LE 0) then message, 'No aircraft data within interval'
maxlat = max(hor[idx].lat, min=minlat)
maxlon = max(hor[idx].lon, min=minlon)
maxalt = max(hor[idx].alt, min=minalt)
maxofn = max(hor[idx].ofn, min=minofn)
if (view EQ _nadir_) then begin
	maxvertical = max((hor[idx].alt - ymin) / hor[idx].con)
	vert_lo = ymin
	vert_hi = maxalt
endif else begin
	maxvertical = max((ymax - hor[idx].alt) / hor[idx].con)
	vert_lo = minalt
	vert_hi = ymax
endelse

info_str = string(format='(%"Flying area: %s - %s, %s - %s")', $
	dectomin(minlat,'N','S',ndec=0), dectomin(maxlat,'N','S',ndec=0), $
	dectomin(minlon,'E','W',ndec=0), dectomin(maxlon,'E','W',ndec=0))
printf, lgf, info_str
printf, info, info_str
if (keyword_set(verbose) && verbose GE 2) then print, info_str

info_str = string(format='(%"Aircraft altitude: %d - %d m ;  ' $
	+ 'Off-nadir angle: %4.1f° - %4.1f°")', minalt, maxalt, minofn, maxofn)
printf, lgf, info_str
printf, info, info_str
if (keyword_set(verbose) && verbose GE 2) then print, info_str

info_str = string(format='(%"Data height range: %d - %d m")', vert_lo, vert_hi)
printf, lgf, info_str
if (keyword_set(verbose) && verbose GE 2) then print, info_str


; set array dimensions

margin = long(max([15, 0.05*file_n]))

if (nproftot GT 0) then begin
	maxprofiles  = long(min([nproftot + margin, nraw]))
	maxaltitudes = long(min([ceil(maxvertical / minres), maxcnt]))
endif else begin
	maxprofiles  = 0L
	maxaltitudes = 0L
endelse

info_str = string(format='(%"Array dimensions:  ' $
	+ 'maxprofiles = %d ;  maxaltitudes = %d")', maxprofiles, maxaltitudes)
printf, lgf, info_str
if (keyword_set(verbose)) then print, info_str


free_lun, info
free_lun, lgf


; the following are needed to track the correct routine call sequence

nprofiles = 0L
lid_cleanup

end

