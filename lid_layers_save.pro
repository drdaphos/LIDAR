pro lid_layers_save, lgf, verbose=verbose


@lid_settings.include


openlog = (n_elements(lgf) NE 1)
if (openlog) then openw, lgf, logfln, /get_lun, /append

if (n_elements(nprofiles) NE 1 || nprofiles LE 0L) then $
	message, 'No data. lid_data_read must be called first.'


; check for layer errors

idx_ok = where(profinfo.aerok NE 0 AND profinfo.aerok NE 1, n_ok)
idx_lr = where(profinfo.f_lidratio LE 0.0D $
	AND (profinfo.f_idx[0] NE 0 OR profinfo.f_idx[1] NE 0), n_lr)

idx_pi = where(profinfo.p_idx[1] LT profinfo.p_idx[0], n_pi)
idx_po = where((profinfo.p_idx[0] NE 0 OR profinfo.p_idx[1] NE 0) $
	AND profinfo.p_idx[0] LE ovl, n_po)
idx_pn = where((profinfo.p_idx[0] NE 0 OR profinfo.p_idx[1] NE 0) $
	AND profinfo.p_cal LE 0.0D, n_pn)

idx_fi = where(profinfo.f_idx[1] LT profinfo.f_idx[0], n_fi)
idx_fo = where((profinfo.f_idx[0] NE 0 OR profinfo.f_idx[1] NE 0) $
	AND profinfo.f_idx[0] LE ovl, n_fo)
idx_fn = where((profinfo.f_idx[0] NE 0 OR profinfo.f_idx[1] NE 0) $
	AND profinfo.f_br LE 0.0D, n_fn)

idx_di = where(profinfo.d_idx[1] LT profinfo.d_idx[0], n_di)
idx_df = where((profinfo.d_idx[0] NE 0 OR profinfo.d_idx[1] NE 0) $
	AND profinfo.f_idx[0] LE profinfo.d_idx[1], n_df)
idx_dn = where((profinfo.d_idx[0] NE 0 OR profinfo.d_idx[1] NE 0) $
	AND profinfo.d_br LE 0.0D, n_dn)

n_err = n_ok + n_lr + n_pi + n_po + n_pn $
	+ n_fi + n_fo + n_fn + n_di + n_df + n_dn

if (n_err GT 0) then begin
	info_str = 'Errors in layers found. Please check!'
	message, info_str, /continue
	printf, lgf, 'lid_layers_save: ', info_str
endif

if (n_ok GT 0) then begin
	info_str = string(n_ok, format='(%"%d profs with weird aerok")')
	if (keyword_set(verbose)) then print, '  ', info_str
	printf, lgf, 'lid_layers_save: ', info_str
	printf, lgf, 'Faulty profiles: ', idx_ok
endif

if (n_lr GT 0) then begin
        info_str = string(n_lr, format='(%"%d profs with negative lidratio")')
        if (keyword_set(verbose)) then print, '  ', info_str
        printf, lgf, 'lid_layers_save: ', info_str
        printf, lgf, 'Faulty profiles: ', idx_lr
endif

if (n_pi GT 0) then begin
        info_str = string(n_pi, format='(%"%d profs with decreasing ' $
		+ 'depol indices")')
        if (keyword_set(verbose)) then print, '  ', info_str
        printf, lgf, 'lid_layers_save: ', info_str
        printf, lgf, 'Faulty profiles: ', idx_pi
endif

if (n_po GT 0) then begin
        info_str = string(n_po, format='(%"%d profs with depol range ' $
		+ 'within overlap")')
        if (keyword_set(verbose)) then print, '  ', info_str
        printf, lgf, 'lid_layers_save: ', info_str
        printf, lgf, 'Faulty profiles: ', idx_po
endif

if (n_pn GT 0) then begin
        info_str = string(n_pn, format='(%"%d profs with negative ' $
		+ 'depol cal")')
        if (keyword_set(verbose)) then print, '  ', info_str
        printf, lgf, 'lid_layers_save: ', info_str
        printf, lgf, 'Faulty profiles: ', idx_pn
endif

if (n_fi GT 0) then begin
        info_str = string(n_fi, format='(%"%d profs with decreasing ' $
                + 'Fern indices")')
        if (keyword_set(verbose)) then print, '  ', info_str
        printf, lgf, 'lid_layers_save: ', info_str
        printf, lgf, 'Faulty profiles: ', idx_fi
endif

if (n_fo GT 0) then begin
        info_str = string(n_fo, format='(%"%d profs with Fern range ' $
                + 'within overlap")')
        if (keyword_set(verbose)) then print, '  ', info_str
        printf, lgf, 'lid_layers_save: ', info_str
        printf, lgf, 'Faulty profiles: ', idx_fo
endif

if (n_fn GT 0) then begin
        info_str = string(n_fn, format='(%"%d profs with negative Fern BR")')
        if (keyword_set(verbose)) then print, '  ', info_str
        printf, lgf, 'lid_layers_save: ', info_str
        printf, lgf, 'Faulty profiles: ', idx_fn
endif

if (n_di GT 0) then begin
        info_str = string(n_di, format='(%"%d profs with decreasing ' $
                + 'Digi indices")')
        if (keyword_set(verbose)) then print, '  ', info_str
        printf, lgf, 'lid_layers_save: ', info_str
        printf, lgf, 'Faulty profiles: ', idx_di
endif

if (n_df GT 0) then begin
        info_str = string(n_df, format='(%"%d profs with Digi far range")')
        if (keyword_set(verbose)) then print, '  ', info_str
        printf, lgf, 'lid_layers_save: ', info_str
        printf, lgf, 'Faulty profiles: ', idx_df
endif

if (n_dn GT 0) then begin
        info_str = string(n_dn, format='(%"%d profs with negative Digi BR")')
        if (keyword_set(verbose)) then print, '  ', info_str
        printf, lgf, 'lid_layers_save: ', info_str
        printf, lgf, 'Faulty profiles: ', idx_dn
endif


; save layers

laysht = string(format='(%"%s_it%04ds.lay")', shortfln, target_it)
layfln = string(format='(%"%s_it%04ds.lay")', outfln, target_it)
openw, out, layfln, /get_lun

t_fmt = ' %6d'		; time
o_fmt = ' %1d'		; flag
h_fmt = ' %7.1f'	; height
c_fmt = ' %5.3f'	; backscatter ratio
p_fmt = ' %7.5f'	; depolarization ratio
l_fmt = ' %6.2f'	; lidar ratio
s_fmt = ' %7.1f'	; surface altitude

h2_fmt  = h_fmt + h_fmt
h2c_fmt = h2_fmt + c_fmt
h2p_fmt = h2_fmt + p_fmt

format = '(%"' + t_fmt + t_fmt + o_fmt + h2p_fmt + h2c_fmt $
	+ l_fmt + h2c_fmt + s_fmt
for i=0, nclouds-1 do format += h_fmt
for i=0, nlayers-1 do format += h2_fmt
format += '")'

_h2undef_ = [_hundef_, _hundef_]
c_hgt = dblarr(nclouds)
l_hgt = dblarr(2, nlayers)


for p=0, nprofiles-1 do begin
	pinfo = profinfo[p]
	prof  = profile[p]
	start = p EQ 0 ? pinfo.start : stop+1
	stop  = p EQ nprofiles-1 ? pinfo.stop : $
		floor((pinfo.stop + profinfo[p+1].start) / 2.0D)
	p_def = (pinfo.p_idx[1] NE 0L AND pinfo.p_idx[1] GE pinfo.p_idx[0])
	f_def = (pinfo.f_idx[1] NE 0L AND pinfo.f_idx[1] GE pinfo.f_idx[0])
	d_def = (pinfo.d_idx[1] NE 0L AND pinfo.d_idx[1] GE pinfo.d_idx[0])
	c_def = (pinfo.ct_idx NE 0)
	l_def = (pinfo.layer_idx[1,*] NE 0L $
		AND pinfo.layer_idx[1,*] GE pinfo.layer_idx[0,*])
	p_hgt = (p_def ? ordered(prof.height[pinfo.p_idx]) : _h2undef_)
	f_hgt = (f_def ? ordered(prof.height[pinfo.f_idx]) : _h2undef_)
	d_hgt = (d_def ? ordered(prof.height[pinfo.d_idx]) : _h2undef_)
	for i=0, nclouds-1 do $
		c_hgt[i] = (c_def[i] ? prof.height[pinfo.ct_idx[i]] : _hundef_)
	for i=0, nlayers-1 do $
		l_hgt[*,i] = (l_def[i] ?  ordered( $
			prof.height[pinfo.layer_idx[*,i]]) : _h2undef_)
	printf, out, format=format, start, stop, pinfo.aerok, $
		p_hgt, pinfo.p_cal, f_hgt, pinfo.f_br, pinfo.f_lidratio, $
		d_hgt, pinfo.d_br, pinfo.lsf, c_hgt, l_hgt
endfor


free_lun, out


info_str = string(format='(%"Layers saved in %s (%s)")', laysht, $
	strmid(systime(),4,12))

if (keyword_set(verbose)) then print, info_str
printf, lgf, 'lid_layers_save: ', info_str


if (openlog) then free_lun, lgf


end

