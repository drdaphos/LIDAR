pro lid_data_read, smooth_signal=smooth_signal, merge=merge, $
	verbose=verbose, float=float


@lid_settings.include

smooth_signal = keyword_set(smooth_signal)
; smooth_signal is the old scheme - new scheme smoothes pr2
; smooth_signal distorts profile in near range!

if (n_elements(merge) NE 1) then merge = default_merge
; it seems that in some flights (e.g. B589) merging introduces
; a non-linearity in the pr2; better turn it off?

openw, lgf, logfln, /get_lun, /append
printf, lgf, '--> LID_DATA_READ'
printf, lgf, 'smooth_signal = ', smooth_signal
printf, lgf, 'merge = ', merge

openw, info, infofln, /get_lun, /append
printf, info, ''

if (n_elements(maxprofiles) NE 1 || maxprofiles LE 0L) then $
	message, 'No data selection made. lid_data_select must be called first.'

if (keyword_set(float)) then begin
	dtype = 4
	dsize = size_float
endif else begin
	dtype = 5
	dsize = size_double
endelse


; allocate profile storage

pinfo = profinfo_def

prof =  {$
	range      : make_array(type=dtype, maxaltitudes), $
	height     : make_array(type=dtype, maxaltitudes), $
	signal     : make_array(type=dtype, maxaltitudes, nchannels), $
	pr2        : make_array(type=dtype, maxaltitudes, nchannels), $
	pr2tot     : make_array(type=dtype, maxaltitudes), $
	mol_beta   : make_array(type=dtype, maxaltitudes), $
	mol_pr2    : make_array(type=dtype, maxaltitudes), $
	mol_corr   : make_array(type=dtype, maxaltitudes, nchannels), $
	totdepol   : make_array(type=dtype, maxaltitudes), $
	aerdepol   : make_array(type=dtype, maxaltitudes), $
	beta       : make_array(type=dtype, maxaltitudes), $
	alpha      : make_array(type=dtype, maxaltitudes), $
	d_alpha    : make_array(type=dtype, maxaltitudes), $
	alpha_ash  : make_array(type=dtype, maxaltitudes), $
	alpha_oth  : make_array(type=dtype, maxaltitudes), $
	conc       : make_array(type=dtype, maxaltitudes) }

pinfo0 = pinfo
prof0  = prof

prof_size = (7 + 3 * nchannels) * maxaltitudes * dsize

lid_cleanup

profinfo2 = replicate(pinfo, maxprofiles)

use_assoc = default_use_assoc

if (keyword_set(use_assoc)) then begin
	openw, assc, assocfln, /get_lun
	profile = assoc(assc, prof)
	info_str = string(format='(%"Using assoc file %s")', assocfln)
endif else begin
	profile = replicate(prof, maxprofiles)
	info_str = 'Keeping profile array in memory'
endelse
printf, lgf, info_str


; merge threshold

merge_idxmin = pre_trig + long(merge_start / range_res)
merge_thresh = dblarr(nchannels)
for ch=0, nchannels-1 do merge_thresh[ch] = mean(merge_pct[*,ch])


; indgen arrays

r_index = dindgen(maxaltitudes)
m_index = lindgen(pre_trig + maxaltitudes)


; background subtraction indices (pre-trig)

nmargin = max([pre_trig0/10, blindsmooth/2])
bgidx1_0 = nmargin
bgidx2_0 = pre_trig0 - nmargin


; rayleigh profile normalization indices

molidx = lonarr(2)
molidx[0] = 2 * ovl
molidx[1] = molidx[0] + min([5000L, maxaltitudes])

moldelta = lonarr(2)
moldelta[0] = 0.9 * molidx[0]
moldelta[1] = molidx[0] - moldelta[0] - 1


; read and integrate profiles

next_raw_profile, /init, lgf=lgf, lidar_path=lidar_path, file_name=file.name, $
	file_start=file.start, file_toffs=file.toffs, file_idx=file_idx, $
	blindsmooth=blindsmooth

next_raw_profile, raw_signal, raw_start, cnt, res, it, endfile
raw_stop = raw_start + long(it) - 1L
cnt -= pre_trig

p = 0L
nrawtot = 0L
mincnt  = _llarge_
maxcnt  = 0L
minres  = _dlarge_
maxres  = _dsmall_
minit   = _dlarge_
maxit   = _dsmall_
while (~endfile) do begin

	intsignal = raw_signal
	pinfo = pinfo0
	prof  = prof0
	pinfo.cnt       = cnt
	pinfo.res       = res
	pinfo.start     = raw_start
	pinfo.stop      = raw_stop
	pinfo.nraw      = 1
	pinfo.it        = it
	pinfo.pa_ratio  = _dundef_
	pinfo.pa_thresh = _dundef_
	pinfo.pa_idx    = 0L
	pinfo.totdep    = 0B
	pinfo.aerdep    = 0B
	pinfo.aerosol   = 0B
	pinfo.inv_type  = _undef_
	pinfo.after_dep = 0B
	old_it = it
	i = 0

	nint = max([fix(ceil(target_it / it)), 1])

	repeat begin
		next_raw_profile, raw_signal, raw_start, cnt, res, it, endfile
		raw_stop = raw_start + long(it) - 1L
		cnt -= pre_trig

		++i
		integrate = (i LT nint  &&  raw_start GE pinfo.start  $
		   && raw_stop  LE  pinfo.start + 1.5D * target_it    $
		   && it EQ old_it  &&  cnt EQ pinfo.cnt              $
		   && res EQ pinfo.res)
		if (integrate) then begin
			intsignal += raw_signal
			pinfo.it += it
			pinfo.stop = raw_stop
			++pinfo.nraw
		endif
	endrep until (endfile || (~integrate))

	; swap channels when connections were swapped :D

	if (swap_chan) then begin
		intsignal_tmp = intsignal
		intsignal_tmp[0,*] = intsignal[1,*]
		intsignal_tmp[1,*] = intsignal[0,*]
		intsignal_tmp[2,*] = intsignal[3,*]
		intsignal_tmp[3,*] = intsignal[2,*]
		intsignal = intsignal_tmp
	endif


	; profile selection / rejection

	if (pinfo.start GE tstart && pinfo.stop LE tstop) then begin

		pinfo.time = (pinfo.start + pinfo.stop) / 2.0D
		intsignal /= pinfo.nraw

		; associate aircraft data

		idx = where(hor.tim GE pinfo.start $
			AND hor.tim LE pinfo.stop, hor_n)
		pinfo.hor_idx = [idx[0], idx[hor_n-1]]
		pinfo.alt = mean(hor[idx].alt, /nan)
		pinfo.lat = mean(hor[idx].lat, /nan)
		pinfo.lon = mean(hor[idx].lon, /nan)
		pinfo.ofn = mean(hor[idx].ofn, /nan)
		pinfo.con = mean(hor[idx].con, /nan)
		pinfo.dis = mean(hor[idx].dis, /nan)
		pinfo.rsf = mean(hor[idx].rsf, /nan)
		pinfo.osf = mean(hor[idx].osf, /nan)
		pinfo.lsf = _hundef_
		pinfo.d_alt  = stddev(hor[idx].alt, /nan)
		pinfo.d_ofn  = stddev(hor[idx].ofn, /nan)
		pinfo.m_alt  = max(abs(hor[idx].alt - pinfo.alt), /nan)
		pinfo.m_ofn  = max(abs(hor[idx].ofn - pinfo.ofn), /nan)
		pinfo.mx_ofn = max(hor[idx].ofn, /nan)

		; generate range and height arrays

		pinfo.vres = pinfo.res * pinfo.con
		vrange = pinfo.vres * r_index * (view EQ _nadir_ ? -1.0D : 1.0D)
		prof.height = pinfo.alt + vrange
		prof.range  = pinfo.res * r_index
		range2 = pinfo.res * dindgen(pinfo.cnt)

		; generate analog/photoncount merged profiles

		if (merge) then begin
		    m_index = lindgen(pre_trig + pinfo.cnt)
		    intsignal2 = smooth(intsignal, [1,smooth], /edge_truncate)
		    mergedsignal = dblarr(nchannels, pre_trig + pinfo.cnt)
		    for ch=0, nchannels-1 do begin
			parat0 = 0.0D
			parat  = 0.0D
			idx = where(m_index GE merge_idxmin[ch] $
				AND m_index LT maxaltitudes $
				AND intsignal2[ch+2,*] GE merge_pct[0,ch] $
				AND intsignal2[ch+2,*] LE merge_pct[1,ch], n_pa)
			if (n_pa GT 0) then begin
				parat0 = mean(intsignal[ch+2,idx] $
					/ intsignal[ch,idx], /nan)
			endif
			if (n_pa GT 0 AND parat0 GT 0.0D) then begin
				max_a = merge_pct[1,ch] / parat0
				idx = where(m_index GE merge_idxmin[ch] $
				   AND m_index LT maxaltitudes $
				   AND intsignal2[ch+2,*] GE merge_pct[0,ch] $
				   AND intsignal2[ch+2,*] LE merge_pct[1,ch] $
				   AND intsignal2[ch,*] LE max_a, n_pa)
			endif
			if (n_pa GT 1) then begin
				idx_top = where(idx[1:*]-idx GT 1, n_top)
				if (n_top GT 0) then begin
					idx = idx[0:idx_top[0]]
					n_pa = n_elements(idx)
				endif
				parat = mean(intsignal[ch+2,idx] $
					/ intsignal[ch,idx], /nan)
			endif
			if (n_pa GT 1 AND parat GT 0.0D) then begin
				thresh_a = merge_thresh[ch] / parat
				idx_p = where((m_index LT pre_trig $
					OR m_index GE merge_idxmin[ch]) $
					AND intsignal2[ch,*] LE thresh_a, $
					n_p, complement=idx_a, ncomplement=n_a)
				idx_h = where(m_index GE merge_idxmin[ch] $
					AND m_index LT maxaltitudes + pre_trig $
					AND intsignal2[ch,*] LE thresh_a, $
					n_h) - pre_trig
			endif else begin
				n_pa = 0
			endelse
			if (n_pa GT 100 && n_h GT 0) then begin
				pinfo.pa_ratio[ch] = parat
				pinfo.pa_thresh[ch] = thresh_a
				pinfo.pa_idx[ch] = idx_h[0]
				if (n_a GT 0) then $
				   mergedsignal[ch,idx_a] $
					= intsignal[ch,idx_a]
				if (n_p GT 0) then $
				   mergedsignal[ch,idx_p] $
					= intsignal[ch+2,idx_p] $
					/ pinfo.pa_ratio[ch]
			endif else begin
				mergedsignal[ch,*] = intsignal[ch,*]
				info_str = string(format='(%"Merging ' $
					+ 'impossible: %s ch %d (%d)")', $
					hhmmss(pinfo.start), ch, p)
				printf, lgf, info_str
;				message, info_str, /continue
			endelse
		    endfor
		endif else begin
			mergedsignal = intsignal
		endelse

		; calculate background

		case bgd_mode of
			_pretrig_ : begin
				bgidx1 = bgidx1_0
				bgidx2 = bgidx2_0
			   end
			_tail_ : begin
				bgidx2 = pre_trig + pinfo.cnt - nmargin
				bgidx1 = bgidx2 - bgd_tail_pts
			   end
		endcase

		for ch=0, nchannels-1 do begin
			pinfo.bgd[ch] = mean(mergedsignal[ch,bgidx1:bgidx2])
			pinfo.bst[ch] = stddev(mergedsignal[ch,bgidx1:bgidx2])
		endfor

		; smoothing: signal and pr2 schemes available

		nsign = min([maxaltitudes, pinfo.cnt])
		pinfo.smooth = smooth
		squarerange  = prof.range * prof.range
		squarerange2 = range2 * range2

		if (smooth_signal) then begin

			; remove pre-trigger, smooth, transpose
			; subtract background, and compute pr2

			mergedsignal2 = smooth(mergedsignal[*,pre_trig:*], $
				[1,smooth], /edge_truncate)

			prof.signal[0:(nsign-1),*] = $
				transpose(mergedsignal2[*,0:(nsign-1)])

			for ch=0, nchannels-1 do begin
				prof.signal[*,ch] -= pinfo.bgd[ch]
				prof.pr2[*,ch] = prof.signal[*,ch] * squarerange
			endfor

		endif else begin

			; remove pre-trigger, subtract background,
			; compute pr2, smooth, re-compute signal

			mergedsignal2 = mergedsignal[*,pre_trig:*]
			rangecorrected = dblarr(nchannels, pinfo.cnt)
			for ch=0, nchannels-1 do begin
				mergedsignal2[ch,*] -= pinfo.bgd[ch]
				rangecorrected[ch,*] $
					= smooth(mergedsignal2[ch,*] $
					* squarerange2, smooth, /edge_truncate)
				prof.pr2[0:(nsign-1),ch] $
					= rangecorrected[ch,0:(nsign-1)]
				prof.signal[1:*,ch] $
					= prof.pr2[1:*,ch] / squarerange[1:*]
			endfor
			prof.signal[0,*] = _dundef_

		endelse

		; compute Rayleigh profile

		mol = molidx
		if (view EQ _nadir_) then begin
			mol[1] = min([long(pinfo.alt/pinfo.vres), nsign]) $
				- molidx[0]
			mol[1] = max(mol)
			mi = 0
			while (mol[1] LE mol[0] && mi LT 2) do begin
				mol[0] -= moldelta[mi]
				mol[1] += moldelta[mi]
				++mi
			endwhile
		endif

		rayleigh, prof.height, cos_offnadir=pinfo.con, $
			beta=betamol, pr2=pr2mol

		for ch=0, nchannels-1 do begin
			kmol = normalize(prof.pr2[*,ch],pr2mol,mol,0.0D)
			prof.mol_corr[*,ch] = kmol * pr2mol
		endfor

		prof.mol_pr2 = prof.mol_corr[*,0]
		prof.mol_beta = betamol

		; set profile title string

		pinfo.title = string(format='(%"%s %s-%s ' $
		   + '%ds/%draw/%dsm %s %s %d±%dm %d±%d°")', $
		   flno_sub, hhmmss(pinfo.start), hhmmss(pinfo.stop), $
		   round(pinfo.it), pinfo.nraw, pinfo.smooth, $
		   dectomin(pinfo.lat, 'N', 'S'), $
		   dectomin(pinfo.lon, 'E', 'W'), round(pinfo.alt), $
		   round(pinfo.m_alt), round(pinfo.ofn), round(pinfo.m_ofn))
		info_str = string(format='(%"%s (%d)")', pinfo.title, p)
		printf, lgf, info_str
		flush, lgf

		; compute global information

		nrawtot += pinfo.nraw
		mincnt  = min([mincnt, pinfo.cnt])
		maxcnt  = max([maxcnt, pinfo.cnt])
		minres  = min([minres, pinfo.res])
		maxres  = max([maxres, pinfo.res])
		minit   = min([minit,  pinfo.it])
		maxit   = max([maxit,  pinfo.it])

		profile[p]   = prof
		profinfo2[p] = pinfo
		if (p EQ 0) then trange1 = hhmmss(pinfo.start)
		++p
	endif

endwhile

trange2   = hhmmss(pinfo.stop)
profinfo  = profinfo2[0:(p-1)]
nprofiles = p

next_raw_profile, /cleanup

if (keyword_set(use_assoc)) then begin
	free_lun, assc
	assc_size = double(prof_size) * nprofiles
	info_str = string(assc_size, assc_size / (1024L*1024L), $
		format='(%"Calculated Assoc file size: %d bytes - %6.1f MB")')
	printf, lgf, info_str
	if (!version.os_family EQ 'unix') then begin
		cmd = du_ux + ' ' + assocfln
	endif else begin
		cmd = du_win + ' ' + assocfln
	endelse
	spawn, cmd, info_str
	printf, lgf, '> ', info_str
	openu, assc, assocfln, /get_lun, /delete
	info_str = string(format='(%"Assoc file unit: %d (%s)")',assc,assocfln)
	printf, lgf, info_str 
endif

if (nprofiles LE 0) then message, 'No data.'

globaltitle = string(format='(%"%s %d-%d-%d %s-%s %d:%dpt %d:%ds ' $
	+ '%dsm %dpr (%draw)")', flno_sub, dd, mth, yy, trange1, trange2, $
	mincnt, maxcnt, round(minit), round(maxit), smooth, nprofiles, nrawtot)
printf, lgf, globaltitle
printf, info, globaltitle
if (keyword_set(verbose)) then print, globaltitle

info_str = string(format='(%"Integrated dataset: %d pr (%d raw) ;  %s - %s")',$
	nprofiles, nrawtot, trange1, trange2)
printf, lgf, info_str
printf, info, info_str
if (keyword_set(verbose) && verbose GE 2) then print, info_str

info_str = string(format='(%"Integration times: %d - %d s")', minit, maxit)
printf, lgf, info_str
printf, info, info_str
if (keyword_set(verbose) && verbose GE 2) then print, info_str

info_str = string(format='(%"Points per profile and range resolution: ' $
	+ '%d - %d pt, %3.1f - %3.1f m")', mincnt, maxcnt, minres, maxres)
printf, lgf, info_str
printf, info, info_str
if (keyword_set(verbose) && verbose GE 2) then print, info_str


free_lun, info
free_lun, lgf


end
