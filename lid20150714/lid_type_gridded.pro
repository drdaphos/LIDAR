function lid_type_gridded, type


@lid_settings.include


if (n_elements(type) NE 1) then type = _default_type_
type0 = type
if (size(type0, /type) EQ 7 || type0 LT 0 || type0 GE ntypes) then $
	type0 = lid_type_select(type0)

exp_dims = (issignal[type0] ? [nprofiles, nheights, nchannels] $
	: [nprofiles, nheights])

case type0 of
	_uncorr_  : data_size = size(lid_uncorr,  /dimensions)
	_signal_  : data_size = size(lid_signal,  /dimensions)
	_pr2_     : data_size = size(lid_pr2,     /dimensions)
	_pr2tot_  : data_size = size(lid_pr2tot,  /dimensions)
	_reldep_  : data_size = size(lid_reldep,  /dimensions)
	_totdep_  : data_size = size(lid_totdep,  /dimensions)
	_aerdep_  : data_size = size(lid_aerdep,  /dimensions)
	_extinc_  : data_size = size(lid_extinc,  /dimensions)
	_backsc_  : data_size = size(lid_backsc,  /dimensions)
	_bratio_  : data_size = size(lid_bratio,  /dimensions)
	_ext_ash_ : data_size = size(lid_ash_ext, /dimensions)
	_ext_oth_ : data_size = size(lid_oth_ext, /dimensions)
	_conc_    : data_size = size(lid_conc,    /dimensions)
	_unc_ext_ : data_size = size(lid_unc_ext, /dimensions)
endcase

return, array_equal(data_size, exp_dims)


end

