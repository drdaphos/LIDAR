pro monsoon_test

; source Rayleigh scattering portion of flight

dir = '~/lidar/Rayleigh/monsoon/'

flno0  = ['B972', 'B973', 'B974', 'B974', 'B975','B976', 'B976', 'B976'   ]
flno1  = ['B972c','B973', 'B974a','B974b','B975','B976a','B976b', 'B976c' ]
start0 = [ 04.51,  03.32,  04.85,  05.89,  04.96, 04.80,  05.10, 05.62  ]
stop0  = [ 04.63,  03.85,  04.92,  05.97,  06.03, 04.94,  05.55, 05.69 ]


@lid_settings.include


append = '_pr2_rdp'
for i=0, n_elements(flno0)-1 do begin
	lid_init, flno0[i], start=start0[i], stop=stop0[i], $
		overlap=0.0, /no_overlap_correct
	sav_fln = string(format='(%"%s_it%03ds_res%03dm%s.sav")', outfln, $
		target_it, round(range_res * smooth), append)
	file_move, sav_fln, dir + flno1[i] + '.sav'
endfor

end
