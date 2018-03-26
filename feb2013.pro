pro feb2013

; source Rayleigh scattering portion of flights


dir = '~/Faam/Data-post-flight/Rayleigh/feb2013/'

flno0  = [ 'B756']
flno1  = [ 'B756']
start0 = [  11.42]
stop0  = [  11.64]


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
