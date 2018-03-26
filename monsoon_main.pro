pro monsoon

; source Rayleigh scattering portion of flight

dir = '~/lidar/Rayleigh/monsoon/'

flno0  = [ 'B957',  'B957',  'B958',  'B958',  'B961',  'B961'  ]
flno1  = [ 'B957a', 'B957b', 'B958a', 'B958b', 'B961a', 'B961b' ]
start0 = [  06.37,   06.93,   06.41,   08.96,   05.71,   05.92  ]
stop0  = [  06.42,   06.98,   06.76,   09.37,   05.83,   06.09  ]

flno0  = [  flno0,  'B965',  'B966',  'B966',  'B966' , 'B967'  ]
flno1  = [  flno1,  'B965',  'B966a', 'B966b', 'B966c', 'B967a' ]
start0 = [ start0,   12.41,   05.94,   06.26,   06.40,   08.34  ]
stop0  = [  stop0,   12.61 ,  06.06,   06.30,   06.56,   08.41  ]

flno0  = [  flno0,  'B967',  'B967' , 'B967',  'B968',  'B968'  ]
flno1  = [  flno1,  'B967b', 'B967c', 'B967d', 'B968a', 'B968b' ]
start0 = [ start0,   08.50,   08.64 ,  08.91,   03.96,   04.63  ]
stop0  = [  stop0,   08.59,   08.75 ,  09.04,   04.05,   04.69  ]

flno0  = [  flno0,  'B968',  'B972', 'B972',  'B973'  ]
flno1  = [  flno1,  'B968c', 'B972', 'B972c', 'B973'  ]
start0 = [ start0,   04.76,   04.51,  04.51,   03.32  ]
stop0  = [  stop0,   04.81,   04.63,  04.63,   03.85  ]

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
