
flt_no = 'B923'

dir    = '/project/obr/Lidar_data/Faam_data/ICE-D/lidar/'
restore, dir + '/2015-08-12_B923_it060s_res045m_ext_dext.sav'

lid_time = LID_TIME         ;FLOAT Array[223]
lid_height = LID_HEIGHT / 1000    ;FLOAT Array[157]
lid_altitude = LID_ALTITUDE / 1000 ;FLOAT Array[223]
lid_extinc = LID_EXTINC     ;FLOAT Array[223, 157]
lid_ext = lid_extinc*1E6

restore, dir + '2015-08-12_B923_cloudtop.sav'

cloud_time = CLOUD_TIME        ;FLOAT Array[6658]
cloud_top_h = CLOUD_TOP_HEIGHT / 1000 ;DOUBLE Array [6658, 3]

min_ext = MIN(lid_ext)
max_ext = MAX(lid_ext)
print, 'minimum extinction ' ,min_ext
print, 'maximum extinction ', max_ext

title = flt_no + ' Aerosol extinction coefficient (Mm!u-1!n)'
variable = lid_ext[*,*,0]
format = '(I)'
datarange = [0, 1000]
yrange = [0, 10000]
tmin = floor(min(lid_time))
tmax = ceil(max(lid_time))
trange = [tmin, tmax]
extrange = [0,1000] ;[0, 400]
altrange = [0, 8]
;trange = [7, 13]

col27

circle_sym = dindgen(19) * 2.0D * !dpi / 18.0D
usersym, cos(circle_sym), sin(circle_sym), /fill


;device,/portrait, decomposed=0, color=1, filename=flt_no + 'aerosol_extinction.eps'
ps_plot, fln = dir+flt_no+'_extinc.eps'
set_palette, 4, bottom=bottom, top=top, maxlevs=maxlevs
nlevs = min([maxlevs, 32])

nrow = 2
!p.multi = [0, 0, 2]
;v_pos_top = 0.92 - 0.90 * findgen(nrow) / nrow
;v_pos_bot = v_pos_top + 0.04 - 0.8 / nrow

cols = bottom + bytscl(indgen(nlevs), top=top-bottom)
levs = extrange[0] + (extrange[1]-extrange[0]) * dindgen(nlevs) / nlevs

contour, variable, lid_time/3600.0, lid_height, levels=levs, c_colors=cols, $
	/cell_fill, /xstyle, /ystyle, $
	yrange=altrange, title=title, $
	xtitle='Time (h)', ytitle='Altitude (km)',font=1, $
	position=[0.1, 0.6, 0.88, 0.95]
oplot, lid_time/3600.0, lid_altitude
oplot, cloud_time/3600.0, cloud_top_h[*,0], psym=8, color=20, symsize=0.5
oplot, cloud_time/3600.0, cloud_top_h[*,1], psym=8, color=20, symsize=0.5
oplot, cloud_time/3600.0, cloud_top_h[*,2], psym=8, color=20, symsize=0.5

contour, variable, lid_time/3600.0, lid_height, levels=levs, c_colors=cols, $
	/cell_fill, /xstyle, /ystyle, $
	yrange=altrange, title=title, $
	xtitle='Time (h)', ytitle='Altitude (km)', font=1, $
	position=[0.1, 0.1, 0.88, 0.45]
oplot, lid_time/3600.0, lid_altitude
oplot, cloud_time/3600.0, cloud_top_h[*,0], psym=8, color=20, symsize=0.5
oplot, cloud_time/3600.0, cloud_top_h[*,1], psym=8, color=20, symsize=0.5
oplot, cloud_time/3600.0, cloud_top_h[*,2], psym=8, color=20, symsize=0.5

colorbar, range=extrange, bottom=bottom, ncolors=top-bottom+1, $
	min_value=0, divisions=4, minor=5, format='(i0)', charsize=1.5, $
	position = [0.97, 0.2, 0.99, 0.8], /vertical, font=1

ps_plot, /close, display=display
end


