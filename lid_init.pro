pro lid_init, flight, start=start, stop=stop, it=it, $
	merge=merge, smooth=smooth0, guess=guess, overlap=overl2, $
	no_overlap_correct=no_overlap_correct, nocore=nocore, $
	netcdf=netcdf, no_gin=no_gin, press_alt=press_alt, aimms=aimms, $
	verbose=verbose, display=display

@lid_settings.include

if (n_elements(display)) NE 1 then display = 1

time1 = systime(/seconds)
lid_flight_select, flight, verbose=verbose
lid_horace_read, no_gin=no_gin, press_alt=press_alt,aimms=aimms,verbose=verbose
if (~keyword_set(nocore)) then lid_core_extract, verbose=verbose
lid_headers_read, verbose=verbose
lid_data_select, start=start, stop=stop, it=it, smooth=smooth0, verbose=verbose
lid_data_read, merge=merge, verbose=verbose
if (~keyword_set(no_overlap_correct)) then lid_overlap_correct
lid_layers_guess, noguess=~keyword_set(guess), verbose=verbose
lid_data_grid, type='pr2', overlap=overl2, verbose=verbose
lid_data_grid, type='reldep', overlap=overl2, /yexisting, verbose=verbose
exclude_data
lid_data_save, type=['pr2', 'reldep'], netcdf=netcdf, verbose=verbose
if (nprofiles GT 1) then $
	lid_plot_contour, type=['pr2','reldep'], display=display
time2 = systime(/seconds)
if (verbose) then print, long(time2-time1), $
	format='(%"Processing took %d seconds.")'

end
