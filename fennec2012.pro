pro fennec2012

; source Rayleigh scattering portion of flights


dir = '~/Faam/Data-post-flight/Rayleigh/fennec2012/'

flno0  = [ 'B699',  'B700',  'B701',  'B701',  'B703',  'B705',  'B709']
flno1  = ['B699a', 'B700a', 'B701a', 'B701b', 'B703a', 'B705a', 'B709a']
start0 = [  12.90,    8.70,    8.70,   12.20,   16.50,   12.19,   12.93]
stop0  = [  13.23,    9.24,    8.88,   12.39,   16.83,   12.40,   13.03]

flno0  = [flno0,   'B709',   'B709']
flno1  = [flno1,  'B709b',  'B709c']
start0 = [start0,   13.08,    16.29]
stop0  = [stop0,    13.17,    16.44]


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
