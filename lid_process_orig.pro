pro lid_process, digirolamo=digirolamo, ash=ash, aod_cutoff=aod_cutoff, $
	yexisting=yexisting, verbose=verbose, display=display, $
	d_lr=d_lr, d_ref_rel=d_ref_rel, d_ref_abs=d_ref_abs


@lid_settings.include


showinfo = 0
showcont = 0

if (n_elements(yexisting)) NE 1 then yexisting = 1
if (n_elements(display)) NE 1 then display = 1
if (n_elements(aod_cutoff) EQ 1) then showinfo = display $
	else showcont = display

if (keyword_set(ash)) then begin
	ash_dr   = 0.34D
	ash_lr   = 82D
	other_lr = 35D
	hgt_range=[0,5000]
	ext_range=[0,5e-4]
	showcont = 0
endif

lid_layers_auto, verbose=verbose
exclude_data
lid_data_process, digirolamo=digirolamo,  ash_process=ash, $
	ash_dr=ash_dr, ash_lr=ash_lr, other_lr=other_lr, $
	d_lr=d_lr, d_ref_rel=d_ref_rel, d_ref_abs=d_ref_abs, verbose=verbose
if (keyword_set(digirolamo)) then lid_ratio_save, verbose=verbose
lid_data_grid, type='pr2tot',  yexisting=yexisting, verbose=verbose
lid_data_grid, type='extinc',  /yexisting, verbose=verbose
lid_data_grid, type='unc_ext', /yexisting, verbose=verbose
lid_data_grid, type='totdep',  /yexisting, verbose=verbose
lid_data_grid, type='aerdep',  /yexisting, verbose=verbose
if (keyword_set(ash)) then begin
	lid_data_grid, type='ext_ash', /yexisting, verbose=verbose
	lid_data_grid, type='ext_other', /yexisting, verbose=verbose
endif
lid_data_save, type=['extinc','unc_ext'], verbose=verbose

lid_plot_profiles, type='pr2',    yrange=hgt_range, display=0
lid_plot_profiles, type='extinc', yrange=hgt_range, xrange=ext_range, $
	mol=0, aer=0, sfc=0, display=0
lid_plot_profiles, type='totdep', yrange=hgt_range, display=0
lid_plot_profiles, type='aerdep', yrange=hgt_range, display=0

idx = where(profinfo.aerosol, n_aer)
if (n_aer GT 1) then begin
	lid_plot_contour,  type=['extinc', 'aerdep'], $
		yrange=hgt_range, xrange=ext_range, display=0
	lid_plot_contour,  type=['extinc', 'totdep'], $
		yrange=hgt_range, xrange=ext_range, display=showcont
	if (keyword_set(ash)) then $
		lid_plot_contour, type=['ext_ash', 'ext_other'], $
			yrange=hgt_range, xrange=[ext_range, ext_range], $
			display=display
	lid_plot_info, aod_cutoff=aod_cutoff, display=showinfo
endif


end
