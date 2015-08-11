pro sambba_neph, core_timesec, neph_blue_uncorr, neph_green_uncorr, $
	neph_red_uncorr, neph_press, neph_temp, neph_rh=neph_rh, lgf

@lid_settings.include

neph_fln = string(yy, mth, dd, strlowcase(flno_core), $
	format='(%"metoffice-neph1_faam_%04d%02d%02d_r1_%s.nc3")')

info_str = string(neph_fln, format = '(%"SAMBBA neph data - reading from %s")')
if (verbose) then message, info_str, /continue
printf, lgf, info_str

nc = ncdf_open(core_path + neph_fln)
finq = ncdf_inquire(nc)
nd = finq.ndims
dname   = strarr(nd)
dsize   = lonarr(nd)

dim = -1
for d=0, nd-1 do begin
	ncdf_diminq, nc, d, name, size
	dname[d] = name
	dsize[d] = size
	if (dname[d] EQ 'time') then dim = d
endfor

if (dim LT 0) then message, 'Incorrect NetCDF: ' + neph_fln

ndata = dsize[dim]
ncdf_varget, nc, 'neph_spm', neph_timesec0
ncdf_varget, nc, 'TSC_BLUU', neph_blue_uncorr0
ncdf_varget, nc, 'TSC_GRNU', neph_green_uncorr0
ncdf_varget, nc, 'TSC_REDU', neph_red_uncorr0
ncdf_varget, nc, 'NEPH_PR',  neph_press0
ncdf_varget, nc, 'NEPH_T',   neph_temp0
ncdf_varget, nc, 'NEPH_HUM', neph_rh0

ncore = n_elements(core_timesec)
idx = where(neph_timesec0 GE core_timesec[0] $
	AND neph_timesec0 LE core_timesec[ncore-1], cnt)

if (cnt LE 0) then message, 'No data.'

neph_timesec      = neph_timesec0[idx]
neph_blue_uncorr  = neph_blue_uncorr0[idx]
neph_green_uncorr = neph_green_uncorr0[idx]
neph_red_uncorr   = neph_red_uncorr0[idx]
neph_press        = neph_press0[idx]
neph_temp         = neph_temp0[idx]
neph_rh           = neph_rh0[idx]

if (cnt LT ncore) then begin
	neph_timesec = [neph_timesec, $
		neph_timesec[cnt-1] + 1 + dindgen(ncore-cnt)]
	fill = replicate(!values.d_nan, ncore-cnt)
	neph_blue_uncorr  = [neph_blue_uncorr,  fill]
	neph_green_uncorr = [neph_green_uncorr, fill]
	neph_red_uncorr   = [neph_red_uncorr,   fill]
	neph_press        = [neph_press,        fill]
	neph_temp         = [neph_temp,         fill]
	neph_rh           = [neph_rh,           fill]
endif

if (~array_equal(neph_timesec, core_timesec)) then $
	message, 'Non-matching times in data.'

end
