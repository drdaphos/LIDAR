pro lid_plot_profiles, type=type, chan=chan, $
	trange=trange, xrange=xrange, yrange=yrange, display=display, $
	mol=show_mol, aer=show_aer, cld=show_cld, ovl=show_ovl, sfc=show_sfc, $
	unprocessed=unprocessed, accepted=accepted


@lid_settings.include

openw, lgf, logfln, /get_lun, /append
printf, lgf, '--> LID_PLOT_PROFILES'

if (n_elements(nprofiles) NE 1 || nprofiles LE 0L) then $
	message, 'No data. lid_data_read must be called first.'

type = lid_type_select(type)
if (type EQ _ext_ash_ || type EQ _ext_oth_) then type = _extinc_
if (n_elements(chan) NE 1) then chan = 0

if (n_elements(show_mol) NE 1)    then show_mol = 1
if (n_elements(show_aer) NE 1)    then show_aer = 1
if (n_elements(show_cld) NE 1)    then show_cld = 1
if (n_elements(show_ovl) NE 1)    then show_ovl = 1
if (n_elements(show_sfc) NE 1)    then show_sfc = 1
if (n_elements(unprocessed) NE 1) then unprocessed = 0


; plot type dependent options

logscale = [1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
def_xmin =  [_dundef_, _dundef_, 0.0D,    0.0D,    0.0D, 0.0D, 0.0D, $
	0.0D, 0.0D, 1.0D, 0.0D, 0.0D, 0.0D, 0.0D]
def_xmax =  [_dundef_, _dundef_, 5000.0D, 5000.0D, 3.0D, 0.3D, 0.4D, $
	1D-3, 1D-5, _dundef_, 1D-3, 1D-3, 1000.0D, 1D-3]


charthick = 4
linethick = 4
charsize  = 1.15
bigchar = 2
axischarsize = 1.5
signcharsize = 0.8

ytit  = 'Altitude AMSL (m)'

aerfl1 = ['F', 'D', 'A']

if (n_elements(trange) EQ 2) then begin
	tran = long(trange * 3600.0D)
	idx = where(profinfo.start GE tran[0] AND profinfo.stop LE tran[1],nidx)
	if (nidx LE 0) then message, 'No data within trange'
	pstart = idx[0]
	pstop  = idx[nidx-1]
endif else begin
	pstart = 0
	pstop  = nprofiles - 1
endelse

if (n_elements(xrange) EQ 2) then begin
	xsty = 1
	xran = xrange
endif else begin
	xsty = 0
	xran = [def_xmin[type], def_xmax[type]]
endelse
if (dblcomp(xran[0], _dundef_)) then xran[0] = min(profinfo.bst[chan])
if (dblcomp(xran[1], _dundef_)) then begin
	if (type EQ _uncorr_ || type EQ _signal_) then begin
		alt_useful = ymin
	endif else begin
		alt_useful = surf_max_hgt
	endelse
	xmax0 = _dsmall_
	mstart = isdepol[type] ? ovl : 0
	for p=pstart, pstop do begin
		prof = profile[p]
		if (view NE _nadir_) then alt_useful = profinfo[p].alt + 5000.0D
		useful = max([long(round(abs(profinfo[p].alt - alt_useful) $
			/ profinfo[p].vres)), mstart])
		var = lid_type_data(type, pinfo, prof, chan=chan)
		xmx = max(var[mstart:useful])
		xmax0 = max([xmax0, xmx])
	endfor
	xran[1] = xmax0
endif

if (n_elements(yrange) EQ 2) then begin
	ysty = 1
	yran = yrange
endif else begin
	ysty = 0
	if (view EQ _nadir_) then begin
		yran = [ymin, max(profinfo.alt)]
	endif else begin
		yran = [min(profinfo.alt), ymax]
	endelse
endelse


append = '_prof_' + typeshort[type]
if (issignal[type]) then append += string(chan, format='(%"_ch%d")') 
append += '.ps'
psfln = outfln   + append

set_plot, 'ps'
device, /color, /landscape, bits_per_pixel=8, filename=psfln
col27

for p=pstart, pstop do begin
	prof  = profile[p]
	pinfo = profinfo[p]

	if (type EQ _totdep_ && ~pinfo.totdep $
		&& ~keyword_set(unprocessed)) then continue
	if (type EQ _aerdep_ && ~pinfo.aerdep $
		&& ~keyword_set(unprocessed)) then continue
	if (isaer[type] && ~pinfo.aerosol $
		&& ~keyword_set(unprocessed)) then continue
	if (~pinfo.aerok && keyword_set(accepted)) then continue

	var = lid_type_data(type, pinfo, prof, chan=chan)

	xtit=string(format='(%"%s - profile %d")', typetit[type], p)
	if (issignal[type]) then $
		xtit += string(format='(%" - channel %d")', chan)
	title = string(pinfo.title, p, format='(%"%s (%d)")')
	plot, var, prof.height, min_value=ymin, xlog=logscale[type], $
		xrange=xran, yrange=yran, xstyle=xsty, ystyle=ysty,  $
		xtitle=xtit, title=title, ytitle=ytit,  $
		charsize=charsize, xcharsize=axischarsize,	   $
		ycharsize=axischarsize, charthick=charthick,	 $
		thick=linethick, xthick=linethick, ythick=linethick, $
		ytickformat='(i)', /nodata
	xran0 = !x.crange
	yran0 = !y.crange
	if (xran0[0] LT 0.0D) then $
		oplot, [0, 0], yran0, thick=linethick
	if (yran0[0] LT 0.0D) then $
		oplot, xran0, [0, 0], thick=linethick

	mol_line = _hundef_
	if (keyword_set(show_mol) && isdepol[type] $
		&& (pinfo.totdep || (pinfo.p_idx[1] NE 0L $
		&& pinfo.p_idx[1] GE pinfo.p_idx[0]))) then mol_line = $
			[prof.height[pinfo.p_idx], mol_line]
	if (keyword_set(show_mol) && ~isdepol[type] $
		&& (pinfo.aerosol || (pinfo.f_idx[1] NE 0L $
		&& pinfo.f_idx[1] GE pinfo.f_idx[0]))) then mol_line = $
			[prof.height[pinfo.f_idx], mol_line]
	if (keyword_set(show_mol) && ~isdepol[type] $
		&& ((pinfo.aerosol && pinfo.inv_type EQ _digi_) $
		|| (~pinfo.aerosol && pinfo.d_idx[1] NE 0L $
		&& pinfo.d_idx[1] GE pinfo.d_idx[0]))) then mol_line = $
			[prof.height[pinfo.d_idx], mol_line]
	for i=0, n_elements(mol_line)-2 do $
		oplot, xran0, mol_line[[i,i]], color=14, thick=linethick

        aer_line = _hundef_
	idx = where(pinfo.layer_idx[1,*] NE 0L $
		AND pinfo.layer_idx[1,*] GE pinfo.layer_idx[0,*], cnt)
	if (keyword_set(show_aer) && cnt GT 0) then $
		aer_line = [prof.height[reform(pinfo.layer_idx[*,idx],2*cnt)], $
			aer_line]
	for i=0, n_elements(aer_line)-2 do $
		oplot, xran0, aer_line[[i,i]], color=10, thick=linethick

        cld_line = _hundef_
	idx = where(pinfo.ct_idx NE 0L, cnt)
	if (keyword_set(show_cld) && cnt GT 0) then $
		cld_line = [prof.height[pinfo.ct_idx[idx]], cld_line]
	for i=0, n_elements(cld_line)-2 do $
		oplot, xran0, cld_line[[i,i]], color=20, thick=linethick

	if (keyword_set(show_ovl)) then begin
		oplot, xran0, [pinfo.alt, pinfo.alt], $
			color=11, thick=linethick
		oplot, xran0, [prof.height[ovl],prof.height[ovl]], $
			color=11, thick=linethick
	endif

	if (keyword_set(show_sfc) && pinfo.lsf GE ymin) then $
		oplot, xran0, [pinfo.lsf, pinfo.lsf], $
			color=9, thick=linethick
	if (keyword_set(show_sfc) && pinfo.osf GE ymin) then $
		oplot, xran0, [pinfo.osf, pinfo.osf], $
			color=4, thick=linethick

	case type of
		_uncorr_ : oplot, [pinfo.bgd[chan], pinfo.bgd[chan]],$
				yran0, color=11, thick=linethick
		_signal_ : oplot, prof.mol_corr[*,chan] $
				/ (prof.range * prof.range), $
				prof.height, min_value=ymin, $
				thick=linethick, color=6
		_pr2_    : oplot, prof.mol_corr[*,chan], prof.height, $
				min_value=ymin,thick=linethick,color=6
		_extinc_ : begin
			if (pinfo.inv_type EQ _ash_) then begin
				oplot, prof.alpha_ash, prof.height, $
				   min_value=ymin, thick=linethick, color=2
				oplot, prof.alpha_oth, prof.height, $
				   min_value=ymin, thick=linethick, color=3
				legend, ['Ash', 'Other'], color=[2,3], $
				   linestyle=0, thick=linethick, $
				   charthick=charthick, box=0
			endif
			if (pinfo.unc_aerosol) then begin
				oplot, prof.alpha+prof.d_alpha, prof.height, $
				   min_value=ymin, thick=linethick, color=23
				oplot, prof.alpha-prof.d_alpha, prof.height, $
				   min_value=ymin, thick=linethick, color=23
			endif
		end
		else     :
	endcase

	if (issignal[type] && pinfo.pa_idx[chan] GT 0) then begin
		if (type EQ _uncorr_ || type EQ _signal_) then begin
			pathresh = pinfo.pa_thresh[chan] $
			   - (type EQ _signal_ ? pinfo.bgd[chan] : 0.0D)
			oplot, [pathresh, pathresh] , yran0, $
			   color=2, thick=linethick
		endif
		idx_h = pinfo.pa_idx[chan]
		oplot, [var[idx_h]], [prof.height[idx_h]], $
			psym=1, symsize=2, color=2, thick=linethick
	endif

	oplot, var, prof.height, min_value=ymin, thick=linethick
	if (pinfo.aerosol) then begin
		case pinfo.inv_type of
			_fern_ : lrflag = string(pinfo.f_lidratio, $
					format='(%" (LR %5.1f)")')
			_digi_ : lrflag = string(pinfo.d_lidratio, $
					format='(%" (LR %5.1f)")')
			else   : lrflag = ''
		endcase
		aerflag = string(aerfl1[pinfo.inv_type], $
			(pinfo.after_dep ? '+' : '-'), lrflag, $
			format='(%"%s%s%s")')
		xyouts, 0.8, 0.9, aerflag, $
			charsize=charsize, charthick=charthick, /normal
	endif
	if (~pinfo.aerok) then xyouts, 0.8, 0.85, 'REJECTED', $
		color=2, charsize=bigchar, charthick=charthick, /normal
	xyouts, 0.5, -0.05, bottomline, alignment=0.5, $
		charsize=signcharsize, charthick=charthick, /normal
endfor


@lid_plot_cleanup.include


end
