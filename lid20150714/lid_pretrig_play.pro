pro lid_pretrig_play, flight, start=start, stop=stop, pretrig=pretrig, $
	xrange=xrange, yrange=yrange, display=display

; force non-standard pre_trig and plot PR2


@lid_settings.include

if (n_elements(pretrig) NE 1) then pretrig = pre_trig0 + pre_trig1
pre_trig_force = pretrig

if (n_elements(display) NE 1) then display = 1

lid_flight_select, flight
lid_horace_read
lid_headers_read
lid_data_select, start=start, stop=stop
lid_data_read
lid_plot_profiles, xrange=xrange, yrange=yrange, display=0
lid_data_grid, type='pr2', overlap=0.0
lid_data_save, type='pr2'

savfln = outfln + string(pretrig, format='(%"_skip%d.sav")')
file_move, outfln + '_it060s_res045m_pr2.sav', savfln

psfln = outfln + string(pretrig, format='(%"_skip%d.ps")')
file_move, outfln + '_prof_pr2_ch0.ps', psfln

if (display) then spawn, psview_ux + ' ' + psfln + ' &'

end
