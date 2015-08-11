pro lid_data_integrate, profs, prof=prof, pinfo=pinfo, verbose=verbose


@lid_settings.include


openw, lgf, logfln, /get_lun, /append
printf, lgf, '--> LID_DATA_INTEGRATE'


if (n_elements(nprofiles) NE 1 || nprofiles LE 0L) then $
	message, 'No data. lid_data_read must be called first.'

if (n_elements(profs) LE 0) then message, 'Specify profile numbers'

if (min(profs) LT 0 || max(profs) GE nprofiles) then $
	message, 'Profiles selected are out of range.'

profs = profs[uniq(profs, sort(profs))]
nprofs = n_elements(profs)

info_str = string(nprofs, format='(%"Integrating %d profiles")')
if (keyword_set(verbose)) then print, '  ', info_str
printf, lgf, info_str


hidx = 0L
for k=0, nprofs-1 do begin
	p = profs[k]
	hor_idx  = profinfo[p].hor_idx
	hor_idx2 = hor_idx[0] + lindgen(hor_idx[1]-hor_idx[0]+1)
	hidx = [hidx, hor_idx2]
endfor
hidx = hidx[1:*]

pinfo = profinfo_def
pinfo.time      = mean(profinfo[profs].time)
pinfo.start     = min(profinfo[profs].start)
pinfo.stop      = max(profinfo[profs].stop)
pinfo.cnt       = profinfo[profs[0]].cnt
pinfo.nraw      = total(profinfo[profs].nraw)
pinfo.it        = total(profinfo[profs].it)
pinfo.res       = profinfo[profs[0]].res
pinfo.vres      = pinfo.res
pinfo.smooth    = profinfo[profs[0]].smooth
pinfo.hor_idx   = [min(hidx), max(hidx)]
pinfo.alt       = mean(hor[hidx].alt, /nan)
pinfo.lat       = mean(hor[hidx].lat, /nan)
pinfo.lon       = mean(hor[hidx].lon, /nan)
pinfo.ofn       = mean(hor[hidx].ofn, /nan)
pinfo.con       = mean(hor[hidx].con, /nan)
pinfo.dis       = mean(hor[hidx].dis, /nan)
pinfo.rsf       = mean(hor[hidx].rsf, /nan)
pinfo.osf       = mean(hor[hidx].osf, /nan)
pinfo.lsf       = max(profinfo[profs].lsf)
pinfo.d_alt     = stddev(hor[hidx].alt, /nan)
pinfo.d_ofn     = stddev(hor[hidx].ofn, /nan)
pinfo.m_alt     = max(abs(hor[hidx].alt - pinfo.alt), /nan)
pinfo.m_ofn     = max(abs(hor[hidx].ofn - pinfo.ofn), /nan)
pinfo.mx_ofn    = max(hor[hidx].ofn, /nan)
pinfo.pa_ratio  = _dundef_
pinfo.pa_thresh = _dundef_
pinfo.pa_idx    = 0L
pinfo.totdep    = 0B
pinfo.aerdep    = 0B
pinfo.aerosol   = 0B
pinfo.inv_type  = _undef_
pinfo.after_dep = 0B
pinfo.bgd       = mean(profinfo[profs].bgd)
pinfo.bst       = mean(profinfo[profs].bst)
pinfo.title     = string(format='(%"%s Integrated Profile %s-%s ' $
	   + '%ds/%draw/%dsm %s %s %d±%dm %d±%d°")', $
	   flno_sub, hhmmss(pinfo.start), hhmmss(pinfo.stop), $
	   round(pinfo.it), pinfo.nraw, pinfo.smooth, $
	   dectomin(pinfo.lat, 'N', 'S'), $
	   dectomin(pinfo.lon, 'E', 'W'), round(pinfo.alt), $
	   round(pinfo.m_alt), round(pinfo.ofn), round(pinfo.m_ofn))

prof = profile[profs[0]]
cnt = n_elements(prof.range)
prof.height    = pinfo.alt + prof.range * (view EQ _nadir_ ? -1.0D : 1.0D)
prof.signal    = 0.0D
prof.pr2       = 0.0D
prof.pr2tot    = 0.0D
prof.totdepol  = 0.0D
prof.aerdepol  = 0.0D
prof.beta      = 0.0D
prof.alpha     = 0.0D
prof.alpha_ash = 0.0D
prof.alpha_oth = 0.0D
prof.conc      = 0.0D

molidx = [2 * ovl, min([5000L, maxaltitudes-2*ovl])]
k1 = 0.0D
k2 = 0.0D
for k=0, nprofs-1 do begin
	p = profs[k]
	prof0  = profile[p]
	pinfo0 = profinfo[p]
	weight = pinfo0.it / pinfo.it
	signal = dblarr(cnt, nchannels)
	pr2 = dblarr(cnt, nchannels)
	for ch=0, nchannels-1 do begin
		signal[*,ch] = interpol(prof0.signal[*,ch], $
			prof0.height, prof.height)
		pr2[*,ch] = interpol(prof0.pr2[*,ch], $
			prof0.height, prof.height)
	endfor
	prof.signal += signal * weight
	prof.pr2    += pr2 * weight
	rayleigh, prof0.height, cos_offnadir=pinfo0.con, pr2=pr2mol0
	k1 += normalize(prof0.mol_pr2, pr2mol0) * weight
	k2 += normalize(prof0.mol_corr[*,1],prof0.mol_corr[*,0],molidx) * weight
endfor

rayleigh, prof.height, cos_offnadir=pinfo.con, beta=betamol, pr2=pr2mol
prof.mol_beta = betamol
prof.mol_pr2  = k1 * pr2mol
prof.mol_corr[*,0] = prof.mol_pr2
prof.mol_corr[*,1] = k2 * prof.mol_corr[*,0]

printf, lgf, 'Profiles: ', profs
printf, lgf, pinfo.title
free_lun, lgf


end

