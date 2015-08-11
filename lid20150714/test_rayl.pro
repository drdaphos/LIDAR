pro test_rayl, ch0, ch1, mol, idxfit, idxmax, $
	rayl_itvl_idx, rayl_bad_idx, test, debug=debug


compile_opt strictarr, strictarrsubs


ndata = n_elements(ch0)
rayl_smooth = 50

diff = dblarr(ndata, 2)
dif2 = dblarr(ndata, 2)
kfit = dblarr(2)
kdif = dblarr(2)

i1  = max([idxfit[0], 0])
i2  = min([idxfit[1], ndata-1])
i01 = max([i1 - rayl_itvl_idx, 0])
i02 = min([i2 + rayl_itvl_idx, ndata-1])

dist  = double(mean([i1, i2])) / idxmax
bad   = 0.3D * (i1 LE rayl_bad_idx)
moln  = mol / mean(mol[i1:i2])
ch0n  = smooth(ch0, rayl_smooth) / mean(ch0[i1:i2])
ch1n  = smooth(ch1, rayl_smooth) / mean(ch1[i1:i2])
diff[*,0] = ch0n - moln
diff[*,1] = ch1n - moln
diffchan  = ch1n - ch0n
kfit[0]  = stddev(diff[i1:i2,0])
kfit[1]  = stddev(diff[i1:i2,1])
kfitchan = stddev(diffchan[i1:i2])

for i=0, 1 do begin
	if (max(diff[i01:i02,i]) GT 10.0D $
	   && mean(diff[i1:i2,i]) LE 1.0D) then begin
		dif2[*,i] = 0.0D
	endif else begin
		for j=0, ndata-1 do $
			dif2[j,i] = (diff[j,i] LT 0.0D ? -diff[j,i] : 0.0D)
	endelse
	kdif[i] = max(dif2[i01:i02,i])
endfor

dtst = kfit[0] + kfit[1] + kdif[0] + 0.5D*kdif[1] + dist + bad
ftst = 0.5D*kfit[0] + 0.2D*kfit[1] + kdif[0] + kdif[1] + (1.0D - dist)
ptst = kfit[0] + kfit[1] + kfitchan + kdif[0]

test = [dtst, ftst, ptst]

if (keyword_set(debug)) then begin
	print, i1, i2, kfit, kfitchan, kdif, dist, test, format='(2i5,9f6.3)'
endif

end

