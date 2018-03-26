pro mevali

; source Rayleigh scattering portion of flights


dir = '~/Faam/Data-post-flight/Rayleigh/mevali/'

flno0  = [ 'B679',  'B682',  'B682',  'B685',  'B685',  'B685']
flno1  = ['B679a', 'B682a', 'B682b', 'B685a', 'B685b', 'B685c']
start0 = [   9.45,   8.05,     11.3,    9.05,   12.55,   13.10]
stop0  = [   9.80,   8.90,     11.7,    9.40,   12.90,   13.65]


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
