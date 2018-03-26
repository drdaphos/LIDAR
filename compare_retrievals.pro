pro compare_retrievals, flno

col27

if (n_elements(flno) NE 1) then message, 'No flno specified.'
flno = strupcase(flno)

dir = '/project/obr/Lidar_data/Faam_data/comp_ret/'
pushd, dir
fl = file_search('????-??-??_'+flno+'_it060s_res045m_ext_dext*')
savfln = strmid(fl[0], 0, 39)
fl = file_search('????-??-??_'+flno+'_it0060s*')
layfln = strmid(fl[0], 0, 23)
popd
;suffix = ['debbie', 'franco']
;suffix = ['fixlr', 'varlr']
suffix = ['v1', 'v2']
psfln  = string(flno, format='(%"compare_retrievals_%s.ps")')
pblfl = flno + '_marine_bl_top_' + suffix + '.txt'
extrange  = [-100,800]
extrange2 = [-300,2500]
extrange3 = [-500,5000]
aodrange  = [0, 3]
yrange = [0,8]
nclouds = 3
nlayers = 4

l_plt = 1
l_col = [4, 6, 7, 17]

restore, dir + savfln + '_' + suffix[0] + '.sav'
lid0_tim = lid_time
lid0_hgt = lid_height/1000.0
lid0_ext = lid_extinc*1E6
lid0_unc = lid_unc_ext*1E6
vertres0 = mean(lid_height[1:*]-lid_height)

data = read_ascii(dir + layfln + '_' + suffix[0] + '.lay')
i=0
lid0_start  = long(reform(data.field01[i++,*]))
lid0_stop   = long(reform(data.field01[i++,*]))
lid0_aerok  = byte(reform(data.field01[i++,*]))
lid0_p_hgt  = double(reform(data.field01[i++:i++,*]))/1000.0
lid0_p_cal  = double(reform(data.field01[i++,*]))
lid0_f_hgt  = double(reform(data.field01[i++:i++,*]))/1000.0
lid0_f_br   = double(reform(data.field01[i++,*]))
lid0_f_lr   = double(reform(data.field01[i++,*]))
lid0_d_hgt  = double(reform(data.field01[i++:i++,*]))/1000.0
lid0_d_br   = double(reform(data.field01[i++,*]))
lid0_lsf    = double(reform(data.field01[i++,*]))/1000.0
lid0_c_hgt  = double(reform(data.field01[i:(i+nclouds-1),*]))/1000.0
i += nclouds
np = n_elements(lid0_start)
lid0_slope = (lid0_f_br - 1.0D GE 1D-6)
lid0_l_hgt = double(reform(data.field01[i:(i+2*nlayers-1),*],2,nlayers,np)) $
	/ 1000.0
i += 2*nlayers
lid0_boundz = reform(lid0_l_hgt[1,0,*])
idx = where(lid0_boundz LT -9, cnt)
if (cnt GT 0) then lid0_boundz[idx] = !values.f_nan 

if (n_elements(lid0_tim) NE n_elements(lid0_start)) then $
	message, 'Layers file inconsistency: ', suffix[0]

lid0_trunc  = replicate(!values.f_nan,n_elements(lid0_start))
for p=0, n_elements(lid0_start)-1 $
	do lid0_trunc[p]=max([lid0_lsf[p],lid0_c_hgt[*,p]],/nan)

lid0_d_ext  = replicate(!values.f_nan,n_elements(lid0_start))
for p=0, n_elements(lid0_start)-1 do begin
	if (lid0_aerok[p] && lid0_d_hgt[0,p] GT 0.0 $
	   && lid0_d_hgt[1,p] GT 0.0) then begin
		idx = where(lid0_hgt GE lid0_d_hgt[0,p] $
		   AND lid0_hgt LE lid0_d_hgt[1,p], cnt)
		if (cnt GT 0) then lid0_d_ext[p] = mean(lid0_ext[p,idx], /nan)
	endif
endfor

restore, dir + savfln + '_' + suffix[1] + '.sav'
lid1_tim = lid_time
lid1_hgt = lid_height/1000.0
lid1_ext = lid_extinc*1E6
lid1_unc = lid_unc_ext*1E6
vertres1 = mean(lid_height[1:*]-lid_height)

data = read_ascii(dir + layfln + '_' + suffix[1] + '.lay')
i=0
lid1_start  = long(reform(data.field01[i++,*]))
lid1_stop   = long(reform(data.field01[i++,*]))
lid1_aerok  = byte(reform(data.field01[i++,*]))
lid1_p_hgt  = double(reform(data.field01[i++:i++,*]))/1000.0
lid1_p_cal  = double(reform(data.field01[i++,*]))
lid1_f_hgt  = double(reform(data.field01[i++:i++,*]))/1000.0
lid1_f_br   = double(reform(data.field01[i++,*]))
lid1_f_lr   = double(reform(data.field01[i++,*]))
lid1_d_hgt  = double(reform(data.field01[i++:i++,*]))/1000.0
lid1_d_br   = double(reform(data.field01[i++,*]))
lid1_lsf    = double(reform(data.field01[i++,*]))/1000.0
lid1_c_hgt  = double(reform(data.field01[i:(i+nclouds-1),*]))/1000.0
i += nclouds
np = n_elements(lid1_start)
lid1_slope = (lid1_f_br - 1.0D GE 1D-6)
lid1_l_hgt = double(reform(data.field01[i:(i+2*nlayers-1),*],2,nlayers,np)) $
	/ 1000.0
i += 2*nlayers
lid1_boundz = reform(lid1_l_hgt[1,0,*])
idx = where(lid1_boundz LT -9, cnt)
if (cnt GT 0) then lid1_boundz[idx] = !values.f_nan

if (n_elements(lid1_tim) NE n_elements(lid1_start)) then $
	message, 'Layers file inconsistency: ', suffix[1]

lid1_trunc  = replicate(!values.f_nan,n_elements(lid1_start))
for p=0, n_elements(lid1_start)-1 $
	do lid1_trunc[p]=max([lid1_lsf[p],lid1_c_hgt[*,p]],/nan)

lid1_d_ext  = replicate(!values.f_nan,n_elements(lid1_start))
for p=0, n_elements(lid1_start)-1 do begin
	if (lid1_aerok[p] && lid1_d_hgt[0,p] GT 0.0 $
	   && lid1_d_hgt[1,p] GT 0.0) then begin
		idx = where(lid1_hgt GE lid1_d_hgt[0,p] $
		   AND lid1_hgt LE lid1_d_hgt[1,p], cnt)
		if (cnt GT 0) then lid1_d_ext[p] = mean(lid1_ext[p,idx], /nan)
	endif
endfor

if (~(array_equal(lid0_tim,lid1_tim) && array_equal(lid0_hgt,lid1_hgt))) $
	then message, 'Time and/or height array discrepancy'

idx = where(lid0_ext LT -1E10, cnt)
if (cnt GT 0) then lid0_ext[idx] = !values.f_nan
idx = where(lid0_unc LT -1E10, cnt)
if (cnt GT 0) then lid0_unc[idx] = !values.f_nan
idx = where(lid1_ext LT -1E10, cnt)
if (cnt GT 0) then lid1_ext[idx] = !values.f_nan
idx = where(lid1_unc LT -1E10, cnt)
if (cnt GT 0) then lid1_unc[idx] = !values.f_nan

nprofiles = n_elements(lid0_tim)

openw, out0, dir + pblfl[0], /get_lun
openw, out1, dir + pblfl[1], /get_lun
printf, out0, '   Prof#      Time(s)        BLtop(m)'
printf, out0, ''
printf, out1, '   Prof#      Time(s)        BLtop(m)'
printf, out1, ''
for p=0, nprofiles-1 do begin
	if (lid0_aerok[p] && finite(lid0_boundz[p]) && lid0_boundz[p] GE 0) $
		then printf, out0, p, lid0_tim[p], lid0_boundz[p]*1E3
	if (lid1_aerok[p] && finite(lid1_boundz[p]) && lid1_boundz[p] GE 0) $
		then printf, out1, p, lid1_tim[p], lid1_boundz[p]*1E3
endfor
free_lun, out0
free_lun, out1


ps_plot, fln=dir+psfln

simplestat, lid0_d_ext, l0freq, l0x, avg=l0avg, std=l0std
simplestat_plot, l0freq, l0x, avg=l0avg, std=l0std, xcharsize=0.75, $
	title=suffix[0] + ' - Extinction at Digi range'

simplestat, lid1_d_ext, l1freq, l1x, avg=l1avg, std=l1std
simplestat_plot, l1freq, l1x, avg=l1avg, std=l1std, xcharsize=0.75, $
	title=suffix[1] + ' - Extinction at Digi range'

!p.multi = [0, 3, 0]
!x.range = extrange
!y.range = yrange
!x.style = 1
!y.style = 1
!x.margin = [6,2]
!y.margin = [4,5]

for p=0, nprofiles-1 do begin
	if (total(finite(lid0_ext[p,*])) EQ 0 $
	   && total(finite(lid1_ext[p,*])) EQ 0) then continue
	if (~lid0_aerok[p] && ~lid1_aerok[p]) then continue
	aod0 = total(lid0_ext[p,*], /nan)*vertres0/1E6
	aod1 = total(lid1_ext[p,*], /nan)*vertres1/1E6

	!x.range = extrange
	rescale = 0
	idx0 = where(lid0_hgt GT lid0_trunc[p], cnt)
	idx1 = where(lid1_hgt GT lid1_trunc[p], cnt)
	if (max(lid1_ext[p,idx1], /nan) GT extrange2[1]) then begin
		!x.range = extrange3
		rescale = 2
	endif else if (max(lid1_ext[p,idx1], /nan) GT extrange[1]) then begin
		!x.range = extrange2
		rescale = 1
	endif

	title = string(flno, hhmmss(lid0_tim[p]), p, format='(%"%s   %s (%d)")')

	plot, lid0_ext[p,*], lid0_hgt, /nodata, title=suffix[0], xtitle='Ext', $
		ytitle='Hgt'
	oplot, [0,0], !y.crange
	if (lid0_aerok[p]) then begin
		oplot, !x.crange, lid0_p_hgt[0,p]*[1,1], col=4, lines=1, thi=10
		oplot, !x.crange, lid0_p_hgt[1,p]*[1,1], col=4, lines=1, thi=10
		oplot, !x.crange, lid0_f_hgt[0,p]*[1,1], col=2
		oplot, !x.crange, lid0_f_hgt[1,p]*[1,1], col=2
		oplot, !x.crange, lid0_d_hgt[0,p]*[1,1], col=2
		oplot, !x.crange, lid0_d_hgt[1,p]*[1,1], col=2
		oplot, !x.crange, lid0_trunc[p]*[1,1]
		oplot, lid0_ext[p,*]+lid0_unc[p,*], lid0_hgt, col=23, linest=1
		oplot, lid0_ext[p,*]-lid0_unc[p,*], lid0_hgt, col=23, linest=1
		oplot, lid0_ext[p,*], lid0_hgt, col=23
		xyouts, !x.crange[0]+0.55*(!x.crange[1]-!x.crange[0]), $
			!y.crange[0]+0.93*(!y.crange[1]-!y.crange[0]), $
			string(lid0_f_hgt[*,p]*1000.0, $
			format='(%"F: %d-%d")'), /data, charsize=1, col=2
		xyouts, !x.crange[0]+0.55*(!x.crange[1]-!x.crange[0]), $
			!y.crange[0]+0.90*(!y.crange[1]-!y.crange[0]), $
			string(lid0_d_hgt[*,p]*1000.0, $
			format='(%"D: %d-%d")'), /data, charsize=1, col=2
		xyouts, !x.crange[0]+0.55*(!x.crange[1]-!x.crange[0]), $
			!y.crange[0]+0.87*(!y.crange[1]-!y.crange[0]), $
			string(lid0_p_hgt[*,p]*1000.0, $
			format='(%"P: %d-%d")'), /data, charsize=1, col=4
		xyouts, !x.crange[0]+0.55*(!x.crange[1]-!x.crange[0]), $
			!y.crange[0]+0.84*(!y.crange[1]-!y.crange[0]), $
			string(lid0_f_lr[p], lid0_f_br[p], $
			(lid0_slope[p] ? '' : '*'), $
			format='(%"LR: %d  BR: %0.2f%s")'), /data, charsize=1
		xyouts, !x.crange[0]+0.55*(!x.crange[1]-!x.crange[0]), $
			!y.crange[0]+0.81*(!y.crange[1]-!y.crange[0]), $
			string(lid0_trunc[p]*1000.0, $
			format='(%"TRUNC: %d")'), /data, charsize=1
		xyouts, !x.crange[0]+0.18*(!x.crange[1]-!x.crange[0]), $
			!y.crange[0]+0.93*(!y.crange[1]-!y.crange[0]), $
			string(aod0, $
			format='(%"AOD:%5.2f")'), /data, charsize=1
		if (l_plt) then for l=0, nlayers-1 do begin
			if (lid0_l_hgt[0,l,p] LT 0) then continue
			ypos = 0.55 - l*0.03
			xyouts, !x.crange[0]+0.55*(!x.crange[1]-!x.crange[0]), $
				!y.crange[0]+ypos*(!y.crange[1]-!y.crange[0]), $
				string(l, lid0_l_hgt[*,l,p]*1000.0, $
				format='(%"L%d: %d-%d")'), /data, charsize=1, $
				col=l_col[l]
			if (lid0_l_hgt[1,l,p] LT lid0_trunc[p]) then continue
			oplot, !x.crange, lid0_l_hgt[0,l,p]*[1,1], col=l_col[l]
			oplot, !x.crange, lid0_l_hgt[1,l,p]*[1,1], col=l_col[l]
		endfor
		if (lid0_boundz[p] GE 0) then oplot, !x.crange, $
			lid0_boundz[p]*[1,1], linestyle=5, thi=10
		idx = where(lid0_ext[p,*] LT -500, cnt)
		if (cnt GT 0) then begin
			oplot, fltarr(cnt), lid0_hgt[idx], col=2, psym=1
			xyouts, !x.crange[0]+0.18*(!x.crange[1]-!x.crange[0]), $
				!y.crange[0]+0.90*(!y.crange[1]-!y.crange[0]), $
				string(max(lid0_hgt[idx])*1000.0, $
				format='(%"NEG: %d")'), /data, charsize=1, col=2
		endif
	endif
	
	plot, lid0_ext[p,*], lid0_hgt, /nodata, title=suffix[1], xtitle='Ext'
	oplot, [0,0], !y.crange
	if (lid1_aerok[p]) then begin
		oplot, !x.crange, lid1_p_hgt[0,p]*[1,1], col=4, lines=1, thi=10
		oplot, !x.crange, lid1_p_hgt[1,p]*[1,1], col=4, lines=1, thi=10
		oplot, !x.crange, lid1_f_hgt[0,p]*[1,1], col=3
		oplot, !x.crange, lid1_f_hgt[1,p]*[1,1], col=3
		oplot, !x.crange, lid1_d_hgt[0,p]*[1,1], col=3
		oplot, !x.crange, lid1_d_hgt[1,p]*[1,1], col=3
		oplot, !x.crange, lid1_trunc[p]*[1,1]
		oplot, lid1_ext[p,*]+lid1_unc[p,*], lid1_hgt, col=20, linest=1
		oplot, lid1_ext[p,*]-lid1_unc[p,*], lid1_hgt, col=20, linest=1
		oplot, lid1_ext[p,*], lid1_hgt, col=20
		xyouts, !x.crange[0]+0.55*(!x.crange[1]-!x.crange[0]), $
			!y.crange[0]+0.93*(!y.crange[1]-!y.crange[0]), $
			string(lid1_f_hgt[*,p]*1000.0, $
			format='(%"F: %d-%d")'), /data, charsize=1, col=3
		xyouts, !x.crange[0]+0.55*(!x.crange[1]-!x.crange[0]), $
			!y.crange[0]+0.90*(!y.crange[1]-!y.crange[0]), $
			string(lid1_d_hgt[*,p]*1000.0, $
			format='(%"D: %d-%d")'), /data, charsize=1, col=3
		xyouts, !x.crange[0]+0.55*(!x.crange[1]-!x.crange[0]), $
			!y.crange[0]+0.87*(!y.crange[1]-!y.crange[0]), $
			string(lid1_p_hgt[*,p]*1000.0, $
			format='(%"P: %d-%d")'), /data, charsize=1, col=4
		xyouts, !x.crange[0]+0.55*(!x.crange[1]-!x.crange[0]), $
			!y.crange[0]+0.84*(!y.crange[1]-!y.crange[0]), $
			string(lid1_f_lr[p], lid1_f_br[p], $
			(lid1_slope[p] ? '' : '*'), $
			format='(%"LR: %d  BR: %0.2f%s")'), /data, charsize=1
		xyouts, !x.crange[0]+0.55*(!x.crange[1]-!x.crange[0]), $
			!y.crange[0]+0.81*(!y.crange[1]-!y.crange[0]), $
			string(lid1_trunc[p]*1000.0, $
			format='(%"TRUNC: %d")'), /data, charsize=1
		xyouts, !x.crange[0]+0.18*(!x.crange[1]-!x.crange[0]), $
			!y.crange[0]+0.93*(!y.crange[1]-!y.crange[0]), $
			string(aod1, $ 
			format='(%"AOD: %4.2f")'), /data, charsize=1
		if (l_plt) then for l=0, nlayers-1 do begin
			if (lid1_l_hgt[0,l,p] LT 0) then continue
			ypos = 0.55 - l*0.03
			xyouts, !x.crange[0]+0.55*(!x.crange[1]-!x.crange[0]), $
				!y.crange[0]+ypos*(!y.crange[1]-!y.crange[0]), $
				string(l, lid1_l_hgt[*,l,p]*1000.0, $
				format='(%"L%d: %d-%d")'), /data, charsize=1, $
				col=l_col[l]
			if (lid1_l_hgt[1,l,p] LT lid1_trunc[p]) then continue
			oplot, !x.crange, lid1_l_hgt[0,l,p]*[1,1], col=l_col[l]
			oplot, !x.crange, lid1_l_hgt[1,l,p]*[1,1], col=l_col[l]
		endfor
		if (lid1_boundz[p] GE 0) then oplot, !x.crange, $
			lid1_boundz[p]*[1,1], linestyle=5, thi=10
		idx = where(lid1_ext[p,*] LT -500, cnt)
		if (cnt GT 0) then begin
			oplot, fltarr(cnt), lid1_hgt[idx], col=2, psym=1
			xyouts, !x.crange[0]+0.18*(!x.crange[1]-!x.crange[0]), $
				!y.crange[0]+0.90*(!y.crange[1]-!y.crange[0]), $
				string(max(lid1_hgt[idx])*1000.0, $
				format='(%"NEG: %d")'), /data, charsize=1, col=2
		endif
	endif
	
	plot, lid0_ext[p,*], lid0_hgt, /nodata, xtitle='Ext', xstyle=8
	oplot, [0,0], !y.crange
	if (lid0_aerok[p]) then begin
		oplot, lid0_ext[p,*], lid0_hgt, col=23
	endif
	if (lid1_aerok[p]) then begin
		oplot, lid1_ext[p,*]+lid1_unc[p,*], lid1_hgt, col=20, linest=1
		oplot, lid1_ext[p,*]-lid1_unc[p,*], lid1_hgt, col=20, linest=1
		oplot, lid1_ext[p,*], lid1_hgt, col=20
		if (lid1_boundz[p] GE 0) then $
			oplot,!x.crange,lid1_boundz[p]*[1,1],linestyle=5,thi=10
	endif
	if (lid0_aerok[p]) then begin
		oplot, lid0_ext[p,*]+lid0_unc[p,*], lid0_hgt, col=23, linest=1
		oplot, lid0_ext[p,*]-lid0_unc[p,*], lid0_hgt, col=23, linest=1
	endif
	legend, suffix, color=[23,20], linestyle=0, box=0, charsize=1, /right
	if (rescale NE 0) then begin
		xyouts, !x.crange[0]+0.3*(!x.crange[1]-!x.crange[0]), $
			!y.crange[0]+0.7*(!y.crange[1]-!y.crange[0]), $
			'PLOT SCALE!', col=2*rescale
	endif

	axis, /xaxis, xrange=aodrange, xtitle='AOD', /save
	oplot, total(reverse(reform(lid1_ext[p,*])), /cumulative, /nan) $
		* (vertres1/1E6), reverse(lid1_hgt), linestyle=5
	
	xyouts, 0.5, 0.97, title, /normal, alignment=0.5
endfor

ps_plot, /close, /gzip, /display

end
