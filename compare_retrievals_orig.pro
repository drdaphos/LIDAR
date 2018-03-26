pro compare_retrievals, flno

col27

if (n_elements(flno) NE 1) then message, 'No flno specified.'
flno = strupcase(flno)

dir = '/data/local/fros/Faam_data/variable_Lr/'
pushd, dir
fl = file_search('????-??-??_'+flno+'_it060s_res045m_ext_dext*')
savfln = strmid(fl[0], 0, 39)
fl = file_search('????-??-??_'+flno+'_it0060s*')
layfln = strmid(fl[0], 0, 23)
popd
;suffix = ['debbie', 'franco']
suffix = ['fixlr', 'varlr']
psfln  = string(flno, format='(%"compare_retrievals_%s.ps")')
extrange = [-100,800]
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
lid0_l_hgt = double(reform(data.field01[i:(i+2*nlayers-1),*],2,nlayers,np)) $
	/ 1000.0
i += 2*nlayers

if (n_elements(lid0_tim) NE n_elements(lid0_start)) then $
	message, 'Layers file inconsistency: ', suffix[0]

lid0_trunc  = replicate(!values.f_nan,n_elements(lid0_start))
for p=0, n_elements(lid0_start)-1 $
	do lid0_trunc[p]=max([lid0_lsf[p],lid0_c_hgt[*,p]],/nan)

restore, dir + savfln + '_' + suffix[1] + '.sav'
lid1_tim = lid_time
lid1_hgt = lid_height/1000.0
lid1_ext = lid_extinc*1E6
lid1_unc = lid_unc_ext*1E6

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
lid1_l_hgt = double(reform(data.field01[i:(i+2*nlayers-1),*],2,nlayers,np)) $
	/ 1000.0
i += 2*nlayers

if (n_elements(lid1_tim) NE n_elements(lid1_start)) then $
	message, 'Layers file inconsistency: ', suffix[1]

lid1_trunc  = replicate(!values.f_nan,n_elements(lid1_start))
for p=0, n_elements(lid1_start)-1 $
	do lid1_trunc[p]=max([lid1_lsf[p],lid1_c_hgt[*,p]],/nan)

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

ps_plot, fln=dir+psfln
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
			string(lid0_f_lr[p], $
			format='(%"LR: %d")'), /data, charsize=1
		xyouts, !x.crange[0]+0.55*(!x.crange[1]-!x.crange[0]), $
			!y.crange[0]+0.81*(!y.crange[1]-!y.crange[0]), $
			string(lid0_trunc[p]*1000.0, $
			format='(%"TRUNC: %d")'), /data, charsize=1
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
			string(lid1_f_lr[p], $
			format='(%"LR: %d")'), /data, charsize=1
		xyouts, !x.crange[0]+0.55*(!x.crange[1]-!x.crange[0]), $
			!y.crange[0]+0.81*(!y.crange[1]-!y.crange[0]), $
			string(lid1_trunc[p]*1000.0, $
			format='(%"TRUNC: %d")'), /data, charsize=1
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
	endif
	
	plot, lid0_ext[p,*], lid0_hgt, /nodata, title='compare', xtitle='Ext'
	oplot, [0,0], !y.crange
	if (lid0_aerok[p]) then begin
		oplot, lid0_ext[p,*]+lid0_unc[p,*], lid0_hgt, col=23, linest=1
		oplot, lid0_ext[p,*]-lid0_unc[p,*], lid0_hgt, col=23, linest=1
	endif
	if (lid1_aerok[p]) then begin
		oplot, lid1_ext[p,*]+lid1_unc[p,*], lid1_hgt, col=20, linest=1
		oplot, lid1_ext[p,*]-lid1_unc[p,*], lid1_hgt, col=20, linest=1
		oplot, lid1_ext[p,*], lid1_hgt, col=20
	endif
	if (lid0_aerok[p]) then begin
		oplot, lid0_ext[p,*], lid0_hgt, col=23
	endif
	legend, suffix, color=[23,20], linestyle=0, box=0, charsize=1, /right
	
	xyouts, 0.5, 0.97, title, /normal, alignment=0.5
endfor

ps_plot, /close, /gzip, /display

stop
end
