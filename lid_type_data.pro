function lid_type_data, type, pinfo, prof, chan=chan, gridded=gridded


@lid_settings.include


if (n_elements(type) NE 1) then type = _default_type_
type0 = type
if (size(type0, /type) EQ 7 || type0 LT 0 || type0 GE ntypes) then $
	type0 = lid_type_select(type0)

if (n_elements(chan) NE 1) then chan = indgen(nchannels)
nchans = n_elements(chan)
if (~issignal[type0]) then nchans = 1


if (keyword_set(gridded)) then begin
	case type0 of
		_uncorr_  : data = lid_uncorr[*,*,chan]
		_signal_  : data = lid_signal[*,*,chan]
		_pr2_     : data = lid_pr2[*,*,chan]
		_pr2tot_  : data = lid_pr2tot
		_reldep_  : data = lid_reldep
		_totdep_  : data = lid_totdep
		_aerdep_  : data = lid_aerdep
		_extinc_  : data = lid_extinc
		_backsc_  : data = lid_backsc
		_bratio_  : data = lid_bratio
		_ext_ash_ : data = lid_ash_ext
		_ext_oth_ : data = lid_oth_ext
		_conc_    : data = lid_conc
		_unc_ext_ : data = lid_unc_ext
	endcase
	exp_dims = (nchans LE 1 ? [nprofiles, nheights] $
		: [nprofiles, nheights, nchans])
endif else begin
	case type0 of
		_uncorr_ : begin
			data = dblarr(maxaltitudes, nchans)
			for ch=0, nchans-1 do $
				data[*,ch] = prof.signal[*,chan[ch]] $
					+ pinfo.bgd[chan[ch]]
		   end
		_signal_  : data = prof.signal[*,chan]
		_pr2_     : data = prof.pr2[*,chan]
		_pr2tot_  : data = prof.pr2tot
		_reldep_  : begin
			!except = 0
			data = prof.pr2[*,1] / prof.pr2[*,0]
			dummy = check_math()
			!except = default_except
		   end
		_totdep_  : data = prof.totdepol
		_aerdep_  : data = prof.aerdepol
		_extinc_  : data = prof.alpha
		_backsc_  : data = prof.beta
		_bratio_  : data = 1.0D + prof.beta/prof.mol_beta
		_ext_ash_ : data = prof.alpha_ash
		_ext_oth_ : data = prof.alpha_oth
		_conc_    : data = prof.conc
		_unc_ext_ : data = prof.d_alpha
	endcase
	exp_dims = (nchans LE 1 ? [maxaltitudes] : [maxaltitudes, nchans])
endelse


if (~array_equal(size(data, /dimensions), exp_dims)) then $
	message, 'Array dimensions inconsistency.'


return, data


end

