pro lid_simulate, flno=flight, alpha=alpha, height=height, lr=lr, it=it, $
	smooth=sm, klid=klid, bgd=bgd, noise=noise, seed=seed, title=title


@lid_settings.include


if (n_elements(flight) NE 1) then flight = 'SIMU'
if (n_elements(lr) LE 0)     then lr = default_lr
if (n_elements(it) LE 0)     then it = default_it
if (n_elements(sm) LE 0)     then sm = default_smooth
if (n_elements(klid) LE 0)   then klid = 1000.0D
if (n_elements(bgd) LE 0)    then bgd = 1.0D
if (n_elements(noise) LE 0)  then noise = 1.0D
if (n_elements(title) LE 0)  then title = ''

dd  = 1
mth = 1
yy  = 1001
takeoff = 0
landing = 86400
tstart  = takeoff
tstop   = landing

flno       = flight
flno_sub   = flno
flno_core  = flno
instrument = 'Simu'
platform   = 'Simu'
orogfln    = ''
swap_chan  = 0
gnd_based  = 0
shortfln   = string(format='(%"%d-%02d-%02d_%s")', yy, mth, dd, flno_sub)
outfln     = string(format='(%"%s/%s/%s")', out_path, shortfln, shortfln)
file_mkdir,  string(format='(%"%s/%s")', out_path, shortfln)
assocfln = tmpdir + shortfln + '.assoc'

info_str = string(format='(%"Generating simulated data (%s).")', flno)

logfln    = outfln + '.log'
openw, lgf, logfln, /get_lun
printf, lgf, '--> LID_SIMULATE'
printf, lgf, info_str

infofln   = outfln + '.info'
openw, info, infofln, /get_lun
printf, info, info_str

if (keyword_set(verbose)) then print, info_str

lid_cleanup


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


dims = size(alpha, /dimensions)
n_dims = size(alpha, /n_dimensions)
if (n_dims EQ 1) then begin
	nprofiles = 1
	nranges  = dims
endif else if (n_dims EQ 2) then begin
	nprofiles = dims[1]
	nranges   = dims[0]
endif else begin
	message, 'Alpha: dimensions unacceptable.'
endelse
if (nranges LT 5) then message, 'Too few ranges - this is nonsense'
alphaaer = alpha / 1D6

dims = size(height, /dimensions)
n_dims = size(height, /n_dimensions)
height0 = height
if (n_dims LT 1 || n_dims GT 2 || (n_dims EQ 1 && dims NE nranges) $
	|| (n_dims EQ 2 && ~array_equal(dims, [nranges,nprofiles]))) $
	then message, 'Range: dimensions unacceptable.'
if (n_dims EQ 1) then begin
	height0 = dblarr(nranges, nprofiles)
	for p=0, nprofiles-1 do height0[*,p] = height
endif

dims = size(lr, /dimensions)
n_dims = size(lr, /n_dimensions)
lr0 = lr
if (n_dims LT 0 || n_dims GT 1 || (n_dims EQ 1 && dims NE nprofiles)) $
	then message, 'LR: dimensions unacceptable'
if (n_dims EQ 0) then lr0 = replicate(lr0, nprofiles)

dims = size(it, /dimensions)
n_dims = size(it, /n_dimensions)
it0 = it
if (n_dims LT 0 || n_dims GT 1 || (n_dims EQ 1 && dims NE nprofiles)) $
	then message, 'IT: dimensions unacceptable'
if (n_dims EQ 0) then it0 = replicate(it0, nprofiles)

dims = size(sm, /dimensions)
n_dims = size(sm, /n_dimensions)
sm0 = sm
if (n_dims LT 0 || n_dims GT 1 || (n_dims EQ 1 && dims NE nprofiles)) $
	then message, 'Smooth: dimensions unacceptable'
if (n_dims EQ 0) then sm0 = replicate(sm0, nprofiles)

dims = size(klid, /dimensions)
n_dims = size(klid, /n_dimensions)
klid0 = klid / 4D-6
if (n_dims LT 0 || n_dims GT 1 || (n_dims EQ 1 && dims NE nprofiles)) $
	then message, 'Klid: dimensions unacceptable'
if (n_dims EQ 0) then klid0 = replicate(klid0, nprofiles)

dims = size(bgd, /dimensions)
n_dims = size(bgd, /n_dimensions)
bgd0 = bgd * 2.5E-5
if (n_dims LT 0 || n_dims GT 1 || (n_dims EQ 1 && dims NE nprofiles)) $
	then message, 'Bgd: dimensions unacceptable'
if (n_dims EQ 0) then bgd0 = replicate(bgd0, nprofiles)

dims = size(noise, /dimensions)
n_dims = size(noise, /n_dimensions)
noise0 = noise
if (n_dims LT 0 || n_dims GT 1 || (n_dims EQ 1 && dims NE nprofiles)) $
	then message, 'Noise: dimensions unacceptable'
if (n_dims EQ 0) then noise0 = replicate(noise0, nprofiles)
noise_const = noise0 * 4D-3 / sqrt(it)

dims = size(title, /dimensions)
n_dims = size(title, /n_dimensions)
title0 = title
if (n_dims LT 0 || n_dims GT 1 || (n_dims EQ 1 && dims NE nprofiles)) $
	then message, 'Title: dimensions unacceptable'
if (n_dims EQ 0) then title0 = replicate(title0, nprofiles)


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


maxaltitudes = nranges
maxprofiles  = nprofiles

profinfo = replicate(profinfo_def, maxprofiles)

dtype = 5	; double precision
dsize = size_double

prof0 =	{$
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

prof_size = (7 + 3 * nchannels) * maxaltitudes * dsize

use_assoc = default_use_assoc

if (keyword_set(use_assoc)) then begin
	openw, assc, assocfln, /get_lun
	profile = assoc(assc, prof0)
	info_str = string(format='(%"Using assoc file %s")', assocfln)
endif else begin
	profile = replicate(prof, maxprofiles)
	info_str = 'Keeping profile array in memory'
endelse
printf, lgf, info_str


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


for p=0, nprofiles-1 do begin
	alt = height0[0,p]

	hdiff = height0[1:*,p] - height0[*,p]
	vres = mean(hdiff)
	view1 = (vres GT 0 ? _zenith_ : _nadir_)
	if (p EQ 0) then view = view1
	if (view1 NE view) then message, 'Inconsistent view'
	if (max(abs(hdiff - vres)) / abs(vres) GT 0.1) $
		then message, 'Irregular vertical resolution'
	vres = abs(vres)

	pinfo = profinfo_def
	pinfo.start = p * 60.0
	pinfo.time  = pinfo.start + 30.0
	pinfo.stop  = pinfo.start + 60.0
	pinfo.alt   = alt
	pinfo.con   = 1.0D
	pinfo.cnt   = nranges
	pinfo.res   = vres
	pinfo.vres  = vres
	pinfo.nraw  = 1
	pinfo.lsf   = _hundef_
	pinfo.it     = it0[p]
	pinfo.smooth = sm0[p]
	pinfo.pa_ratio  = _dundef_
	pinfo.pa_thresh = _dundef_
	pinfo.pa_idx    = 0L
	pinfo.totdep    = 0B
	pinfo.aerdep    = 0B
	pinfo.aerosol   = 0B
	pinfo.inv_type  = _undef_
	pinfo.after_dep = 0B
	pinfo.bgd[0] = bgd0[p]
	pinfo.bst[0] = noise_const[p] * sqrt(bgd0[p]/sm0[p])
	pinfo.f_lidratio = lr0[p]
	if (title0[p] EQ '') then begin
		pinfo.title = string(format='(%"%s %s-%s ' $
			+ '%ds/%draw/%dsm %s %s %d±%dm %d±%d°")', $
			flno_sub, hhmmss(pinfo.start), hhmmss(pinfo.stop), $
			round(pinfo.it), pinfo.nraw, pinfo.smooth, $
			dectomin(pinfo.lat, 'N', 'S'), $
			dectomin(pinfo.lon, 'E', 'W'), round(pinfo.alt), $
			round(pinfo.m_alt), round(pinfo.ofn), $
			round(pinfo.m_ofn))
	endif else begin
		pinfo.title = flno_sub + ' - ' + title0[p]
	endelse
	if (p EQ 0) then trange1 = hhmmss(pinfo.start)

	prof = prof0
	prof.height = height0[*,p]
	prof.range  = abs(prof.height - pinfo.alt)

	rayleigh, prof.height, cos_offnadir=pinfo.con, $
		beta=betamol, tau=taumol, pr2=pr2mol
	prof.mol_beta = betamol
	prof.mol_pr2  = klid0[p] * pr2mol
	prof.mol_corr[*,0] = prof.mol_pr2
	prof.mol_corr[*,1] = prof.mol_pr2

	dtauaer = dblarr(nranges)
	sig = dblarr(nranges)
	rnd0 = randomn(seed, nranges, /double)
	rnd1 = randomn(seed, nranges, /double)
	dtauaer[1:*] = alphaaer[1:*,p] * abs(prof.height[1:*]-prof.height)
	tauaer = total(dtauaer, /cumulative)
	betaaer = alphaaer[*,p] / lr0[p]
	pr2 = klid0[p] * (betamol+betaaer) * exp(-2.0D*(taumol+tauaer))
	sig[1:*] = pr2[1:*] / (prof.range[1:*]*prof.range[1:*])
	sig2 = sig + noise_const[p] * sqrt(sig + bgd0[p]) * rnd0
	sig3 = smooth(sig2, sm0[p], /edge_truncate)
	sig2d = sig + noise_const[p] * sqrt(sig + bgd0[p]) * rnd1
	sig3d = smooth(sig2d, sm0[p], /edge_truncate)

	prof.signal[*,0] = sig3
	prof.signal[*,1] = sig3d
	prof.pr2[*,0]    = sig3  * prof.range * prof.range
	prof.pr2[*,1]    = sig3d * prof.range * prof.range

	profinfo[p] = pinfo
	profile[p]  = prof
endfor

trange2   = hhmmss(pinfo.stop)
target_it = mean(it0)
smooth    = mean(sm0)

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

globaltitle = string(format='(%"%s %d-%d-%d %s-%s %d:%dpt %d:%ds ' $
	+ '%d:%dsm %dpr (%draw)")', flno_sub, dd, mth, yy, trange1, trange2, $
	nranges, nranges, round(min(it0)), round(max(it0)), round(min(sm0)), $
	round(max(sm0)), nprofiles, nprofiles)
printf, lgf, globaltitle
printf, info, globaltitle
if (keyword_set(verbose)) then print, globaltitle


free_lun, lgf
free_lun, info


end
