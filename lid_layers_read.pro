pro lid_layers_read, lgf, read_in, verbose=verbose


@lid_settings.include


openlog = (n_elements(lgf) NE 1)
if (openlog) then openw, lgf, logfln, /get_lun, /append

if (n_elements(nprofiles) NE 1 || nprofiles LE 0L) then $
	message, 'No data. lid_data_read must be called first.'

read_in = 0
laysht = string(format='(%"%s_it%04ds.lay")', shortfln, target_it)
layfln = info_path + laysht

if (~file_test(layfln, /read, /regular)) then return

info_str = 'Reading layers from '  + laysht
printf, lgf, 'lid_layers_read: ', info_str
if (keyword_set(verbose)) then print, info_str

data = read_ascii(layfln)

i=0
start  = long(reform(data.field01[i++,*]))
stop   = long(reform(data.field01[i++,*]))
aerok  = byte(reform(data.field01[i++,*]))
p_hgt  = double(reform(data.field01[i++:i++,*]))
p_cal  = double(reform(data.field01[i++,*]))
f_hgt  = double(reform(data.field01[i++:i++,*]))
f_br   = double(reform(data.field01[i++,*]))
f_lr   = double(reform(data.field01[i++,*]))
d_hgt  = double(reform(data.field01[i++:i++,*]))
d_br   = double(reform(data.field01[i++,*]))
lsf    = double(reform(data.field01[i++,*]))

c_hgt = double(reform(data.field01[i:(i+nclouds-1),*]))
i += nclouds

np = n_elements(start)
l_hgt = double(reform(data.field01[i:(i+2*nlayers-1),*],2,nlayers,np))
i += 2*nlayers

nfields = i

layers_it = mean(stop - start) + 1
short_it = (target_it LE layers_it * 1.1)

c_idx = lonarr(nclouds)
l_idx = lonarr(2, nlayers)

undef0 = 0L
ambig0 = 0L
for p=0, nprofiles-1 do begin
	pinfo = profinfo[p]
	prof  = profile[p]
	skip = 0
	undef = 0
	ambig = 0

	if (short_it) then begin
		idx = where(pinfo.time GE start AND pinfo.time LE stop, cnt)
		if (cnt LE 0) then begin
			undef = 1
			skip = 1
		endif else if (cnt GT 1) then begin
			ambig = 1
		endif
		idx = idx[0]
	endif else begin
		idx = where(start LE pinfo.stop AND stop GE pinfo.start, cnt)
		if (cnt LE 0) then begin
			undef = 1
			skip = 1
		endif else begin
			k0 = idx[0]
			for j=1, cnt-1 do begin
				k = idx[j]
				for i=2, nfields-1 do if (data.field01[i,k] $
					NE data.field01[i,k0]) then ambig = 1
			endfor
			skip = ambig
		endelse
	endelse
	undef0 += undef
	ambig0 += ambig
	if (undef || ambig) then begin
		info_str = undef ? 'No layers defined' : 'Ambiguous layers'
		info_str += string(format='(%": %5d (%s)")', $
			p, hhmmss(pinfo.start))
		printf, lgf, info_str
		if (keyword_set(verbose) && verbose GE 2) then print, info_str
	endif
	if (skip) then continue

	hi = where(prof.range GE overlap AND prof.height GE p_hgt[0,idx] $
		AND prof.height LE p_hgt[1,idx], hn)
	if (hn GT 0 && p_hgt[0,idx] GE ymin && p_hgt[1,idx] GE ymin) then begin
		p_idx = [hi[0], hi[hn-1]]
	endif else begin
		p_idx = [0L, 0L]
	endelse

	hi = where(prof.range GE overlap AND prof.height GE f_hgt[0,idx] $
		AND prof.height LE f_hgt[1,idx], hn)
	if (hn GT 0 && f_hgt[0,idx] GE ymin && f_hgt[1,idx] GE ymin) then begin
		f_idx = [hi[0], hi[hn-1]]
	endif else begin
		f_idx = [0L, 0L]
	endelse

	hi = where(prof.range GE overlap AND prof.height GE d_hgt[0,idx] $
		AND prof.height LE d_hgt[1,idx], hn)
	if (hn GT 0 && d_hgt[0,idx] GE ymin && d_hgt[1,idx] GE ymin) then begin
		d_idx = [hi[0], hi[hn-1]]
	endif else begin
		d_idx = [0L, 0L]
	endelse

	for i=0, nclouds-1 do begin
		hi = where(prof.height GE c_hgt[i,idx]-pinfo.vres/2.0D $
			AND prof.height LE c_hgt[i,idx]+pinfo.vres/2.0D, hn)
		if (hn GT 0 && c_hgt[i,idx] GE ymin) then begin
			c_idx[i] = hi[0]
		endif else begin
			c_idx[i] = 0L
		endelse
	endfor

	for i=0, nlayers-1 do begin
		hi = where(prof.height GE l_hgt[0,i,idx] $
			AND prof.height LE l_hgt[1,i,idx], hn)
		if (hn GT 0 && l_hgt[0,i,idx] GE ymin $
			&& l_hgt[1,i,idx] GE ymin) then begin
				l_idx[*,i] = [hi[0], hi[hn-1]]
		endif else begin
			l_idx[*,i] = [0L, 0L]
		endelse
	endfor

	pinfo.aerok      = aerok[idx]
        pinfo.p_idx      = p_idx
	pinfo.p_cal      = p_cal[idx]
	pinfo.f_idx      = f_idx
	pinfo.f_br       = f_br[idx]
	pinfo.f_lidratio = f_lr[idx]
	pinfo.d_idx      = d_idx
	pinfo.d_br       = d_br[idx]
	pinfo.lsf        = lsf[idx]
	pinfo.layer_idx  = l_idx
	pinfo.ct_idx     = c_idx
	profinfo[p] = pinfo
endfor

if (undef0 GT 0L) then begin
	info_str = string(format='(%"There were %d profiles with ' $
		+ 'undefined layers")', undef0)
	printf, lgf, info_str
	message, info_str, /continue
endif

if (ambig0 GT 0L) then begin
	info_str = string(format='(%"There were %d profiles with ' $
		+ 'ambiguous  layers")', ambig0)
	printf, lgf, info_str
	message, info_str, /continue
endif


read_in = 1

if (openlog) then free_lun, lgf

end

