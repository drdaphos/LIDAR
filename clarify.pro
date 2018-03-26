pro clarify

; source Rayleigh scattering portion of flights

dir = '~/lidar/Rayleigh/clarify/'

flno0  = [ 'C028', 'C028', 'C028', 'C028', 'C028', 'C029', 'C030' ]
flno1  = [ 'C028a','C028b','C028c','C028d','C028e','C029a','C030a']
start0 = [  10.53,  10.68,  11.55,  11.67,  12.24,  9.26 ,  14.54 ]
stop0  = [  10.58,  10.74,  11.66,  12.07,  12.31,  9.56 ,  14.89 ]

flno0  = [  flno0,  'C030', 'C031', 'C032' ]
flno1  = [  flno1,  'C030b','C031a','C032a']
start0 = [ start0,   16.12,  12.84,  10.99 ]
stop0  = [  stop0,   16.21,  13.05,  11.04 ]

;flno0  = [  flno0,  'C032', 'C032', 'C033', 'C036', 'C037', 'C037' ]
;flno1  = [  flno1,  'C032c','C032d','C033a','C036a','C037a','C037b']
;start0 = [ start0,   10.96,  13.39,  9.38 ,  11.53,  14.36,  14.75 ]
;stop0  = [  stop0,   11.04,  13.53,  9.54 ,  11.69,  14.43,  14.95 ]

;flno0  = [  flno0,  'C037' ]
;flno1  = [  flno1,  'C037c']
;start0 = [ start0,   16.37 ]
;stop0  = [  stop0,   16.50 ]


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
