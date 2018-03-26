pro lidar_extinction_plotting_code

flt_no = 'B928'
date = '2015-08-16_'

dir    = '/project/obr/LIDAR/lidar_processed/'
restore, dir + date + flt_no + '/' + date + flt_no + '_it060s_res045m_ext_dext.sav'

lid_time = LID_TIME                ;FLOAT Array[175]
lid_height = LID_HEIGHT / 1000     ;FLOAT Array[157]
lid_altitude = LID_ALTITUDE / 1000 ;FLOAT Array[165]
lid_extinc = LID_EXTINC            ;FLOAT Array[175, 165]
lid_ext = lid_extinc*1E6

restore, dir + date + flt_no + '/' + date + flt_no + '_cloudtop.sav'
cloud_time = CLOUD_TIME               ;FLOAT  Array[5239]
cloud_top_h = CLOUD_TOP_HEIGHT / 1000 ;DOUBLE Array[5239, 3]

restore, dir + date + flt_no + '/' + date + flt_no + '_it060s_lr.sav'
lr_time = DIGIRESULT.TIME ;LONG   Array[113]
aod = DIGIRESULT.AOD      ;DOUBLE Array[113]
lr = DIGIRESULT.LR        ;DOUBLE Array[113]

extrange = [0,300] ;400, 1000 for B923 and B924
altrange = [0, 8]
title = flt_no + ' Aerosol extinction coefficient (Mm!u-1!n)'
variable = lid_ext[*,*,0]
format = '(I)'
datarange = [0, 1000]
yrange = [0, 10000]
tmin = floor(min(lid_time))
tmax = ceil(max(lid_time))
trange = [tmin, tmax]

;trange = [7, 13]

col27

circle_sym = dindgen(19) * 2.0D * !dpi / 18.0D
usersym, cos(circle_sym), sin(circle_sym), /fill

;device,/portrait, decomposed=0, color=1, filename=flt_no + 'aerosol_extinction.eps'
ps_plot, fln = dir + date + flt_no +'/' + date + flt_no +'_extinc_lr.eps'
set_palette, 4, bottom=bottom, top=top, maxlevs=maxlevs
nlevs = min([maxlevs, 32])

cols = bottom + bytscl(indgen(nlevs), top=top-bottom)
levs = extrange[0] + (extrange[1]-extrange[0]) * dindgen(nlevs) / nlevs

contour, variable, lid_time/3600.0, lid_height, levels=levs, c_colors=cols, $
	/cell_fill, /xstyle, /ystyle, $
	yrange=altrange, title=title, $
	xtitle='Time (h)', ytitle='Altitude AMSL (km)',font=1, $
	position=[0.1, 0.55, 0.9, 0.94]
oplot, lid_time/3600.0, lid_altitude
oplot, cloud_time/3600.0, cloud_top_h[*,0], psym=8, color=23, symsize=0.5
oplot, cloud_time/3600.0, cloud_top_h[*,1], psym=8, color=20, symsize=0.5
oplot, cloud_time/3600.0, cloud_top_h[*,2], psym=8, color=18, symsize=0.5
oplot, lr_time/3600.0, lr/10, psym=4, symsize=0.7

colorbar, range=extrange, bottom=bottom, ncolors=top-bottom+1, $
	min_value=0, divisions=4, minor=5, format='(i0)', charsize=1.5, $
	position = [0.97, 0.55, 0.99, 0.94], /vertical, font=1

ps_plot, /close, display=display
end


