pro next_raw_profile, signal_raw, rstart, cnt, res, it, done, raw_k, $
	init=init, cleanup=cleanup, lgf=logfile, lidar_path=path, $
	file_name=fln, file_start=fstart, file_toffs=toffs, file_idx=idx, $
	blindsmooth=blndsm


compile_opt strictarr, strictarrsubs


common __next_raw_profile, initialized, fileopen, inp, lgf, i, j, k, $
	lidar_path, file_name, file_start, file_toffs, file_idx, file_n, $
	blindsmooth, blindref, blindcnt, nsign, ad_gain, ad_offs, pct_gain, $
	res0, it0, nprof


if (keyword_set(init)) then begin
	if keyword_set(initialized) then begin
		message, 'next_raw_profile had not been cleaned up.', /continue
		next_raw_profile, /cleanup
	endif
	lgf = logfile
	lidar_path  = path
	file_name   = fln
	file_start  = fstart
	file_toffs  = toffs
	file_idx    = idx
	file_n      = n_elements(file_idx)
	blindsmooth = blndsm
	i = 0
	j = 0
	initialized = 1
	fileopen = 0
	return
endif


if (keyword_set(cleanup)) then begin
	if (fileopen) then free_lun, inp
	fileopen = 0
	initialized = 0
	return
endif


if (~initialized) then message, 'next_raw_profile has not been initialized.'


if (j LE 0) then begin
	k = file_idx[i]
	if (fileopen) then $
		message, 'next_raw_profile anomalous call (file open)'
	openr, inp, lidar_path + file_name[k], /get_lun
	fileopen = 1
	getheader_raw, inp, res=res0, it=it0, nprof=nprof, $
		nsign=nsign, ad_gain=ad_gain, ad_offs=ad_offs, $
		pct_gain=pct_gain, blind=blindref0, cnt=blindcnt, $
		filename=file_name[k]
	blindref=smooth(blindref0, [1,blindsmooth], /edge_truncate)
	info_str = string(format='(%"%4d) %8s  %3draw  %2ds  %s")', $
		k, hhmmss(file_start[k]), nprof, it0, file_name[k])
	printf, lgf, info_str
endif else if (~fileopen) then begin
	message, 'next_raw_profile anomalous call (file not open)'
endif


getprofile_raw, inp, nsign, ad_gain, ad_offs, pct_gain, $
	signal_raw, time=rstart, cnt=cnt, filename=file_name[k]
if (cnt NE blindcnt) then $
	message, 'profile length different than blind reference'
rstart += file_toffs[k]
signal_raw[0:1,*] -= blindref[*,*]
res = res0
it  = it0
raw_k = k
info_str = string(format='(%"        %8s")', hhmmss(rstart))
printf, lgf, info_str
++j


done = 0


if (j GE nprof) then begin
	if (fileopen) then free_lun, inp
	fileopen = 0
	j = 0
	++i
	if (i GE file_n) then done = 1
endif


end
