;pro iced_lidar, flno, run=run, display=display, showcloud=showcloud


compile_opt strictarr, strictarrsubs

flno ='B923'

altrange  = [0,8]
extrange  = [0,400]
;if (flno EQ 'B923' || flno EQ 'B924') then extrange = [0,1000]

run = ['R1']
n_runs = n_elements(run)

dir    = '/project/obr/Lidar_data/Faam_data/ICE-D/lidar/'
search = '*_' + flno + '_it060s_res045m_ext_dext.sav'
extfln = file_search(dir + search)
print, 'lidar extinction file ', extfln

sumdir = '/project/obr/Lidar_data/Faam_data/core/'
sumfln = strlowcase(flno) + '_summary.txt'
psfln  = strlowcase(flno) + '_ext.ps'
savfln = strlowcase(flno) + '_ext.sav'
ncfln  = strlowcase(flno) + '_ext.nc'

;cld_search = '*_' + flno + '_it060s_cloudtop.sav'
;cldsav = file_search(dir + cld_search)
;print, 'cloud top file is ', cldsav

;cldsav  = home + 'Faam/Data-post-flight/Ice-D/cloudtops/iced_cloud_it02.sav'
restore, '/project/obr/Lidar_data/Faam_data/lidar_processed/2015-08-12_B923/2015-08-12_B923_cloudtop.sav'
;restore, cldsav
cloud_time = CLOUD_TIME        ;FLOAT Array[6658]
cloud_top_height = CLOUD_TOP_HEIGHT ;DOUBLE Array [6658, 3]

cloud1 = cloud_top_height[*,0]
cloud2 = cloud_top_height[*,1]

col27

title     = flno + ' - Aerosol extinction coefficient (Mm!u-1!n)'
_nan_ = !values.f_nan
dt = 20	; tolerance on run start/stop time

;read_run_prof, sumdir+sumfln, name=sname, start=sstart, stop=sstop, $
;	run_idx=run_idx
;rstart = sstart[run_idx]
;rstop  = sstop[run_idx]
;rname  = sname[run_idx]

;run_start = fltarr(n_runs)
;run_stop =  fltarr(n_runs)
;for i=0, n_runs-1 do begin
;	idx = where(rname EQ run[i], cnt)
;	if (cnt NE 1) then message, 'Run not in summary, or duplicated.'
;	run_start[i] = rstart[idx] - dt
;	run_stop[i]  = rstop[idx]  + dt
;endfor

run_start = '32732' ;'090218'
run_stop =  '43748' ;'120930'
runs = run[0]
for i=1, n_runs-1 do runs += ' ' + run[i]
print, flno, runs, format='(%"%s: %s")'

restore, extfln

idx = where(lid_extinc LT -1E10, cnt)
if (cnt GT 0) then lid_extinc[idx] = _nan_
idx = where(lid_unc_ext LT -1E10, cnt)
if (cnt GT 0) then lid_unc_ext[idx] = _nan_
nh = n_elements(lid_height)

i3km = where(lid_height GE 3000.0 AND lid_height LT 3045.0, c3km)
if (c3km NE 1) then message, 'Hard to define height=3km.'
idx = where(finite(lid_extinc[*,i3km]))

lid_extinc   *= 1E6
lid_unc_ext  *= 1E6
lid_altitude /= 1000.0
lid_height   /= 1000.0
vres = mean(lid_height[1:*]-lid_height)*1E-3	; in Mm

lidar = {flight:flno, height:lid_height, run:run, $
	aod:fltarr(n_runs), ext:fltarr(n_runs, nh)}

latmin = floor(min(lid_latitude[idx]))
latmax = ceil(max(lid_latitude[idx]))
latrange = [latmin, latmax]

circle_sym = dindgen(19) * 2.0D * !dpi / 18.0D
usersym, cos(circle_sym), sin(circle_sym), /fill

ps_plot, fln = dir + psfln
set_palette, 4, bottom=bottom, top=top, maxlevs=maxlevs
nlevs = min([maxlevs, 32])

nrow = 2
!p.multi = [0, 0, nrow]
v_pos_top = 0.92 - 0.90 * findgen(nrow) / nrow
v_pos_bot = v_pos_top + 0.04 - 0.8 / nrow

cols = bottom + bytscl(indgen(nlevs), top=top-bottom)
levs = extrange[0] + (extrange[1]-extrange[0]) * dindgen(nlevs) / nlevs

;print, 'lid time ', lid_time
;print, 'run_start ', run_start
;print, 'run_stop ',   run_stop

;for i=0, n_runs-1 do begin
;idx = where(lid_time GE run_start AND lid_time LE run_stop, np)
xvar = lid_latitude
alt  = lid_altitude
var  = lid_extinc[*,*,0]
dummy = where(finite(var[*,i3km]), nvalid)

;lidar.ext = mean(var /nan)
;lidar.aod = total(lidar.ext,/nan) * vres
;print, run, nvalid, lidar.aod, $
;		format='(%"%s: %d profiles (%d valid), AOD=%0.2f")'

;np = nelements(alt)
;xvar2 = replicate(_nan_, 2*np)
;var2  = replicate(_nan_, 2*np, nh)
;delta = 0.2 * mean(xvar[1:*]-xvar)
;for k=0, np-1 do begin
;	xvar2[2*k]    = xvar[k] - delta
;	xvar2[2*k+1]  = xvar[k] + delta
;	var2[2*k,*]   = var[k,*]
;	var2[2*k+1,*] = var[k,*]
;endfor

contour, var, lid_time, lid_height, levels=levs, c_colors=cols, $
	/cell_fill, /xstyle, /ystyle, xrange=latrange, $
	xtitle = (i MOD nrow EQ nrow-1 ? 'Latitude': ''), $
	title = (i MOD nrow EQ 0 ? title : ''), $
	yrange=altrange, ytickformat='(i)', ytitle='Altitude (km)', $
	position=[0.08, v_pos_bot[i MOD nrow], 0.86, $
	v_pos_top[i MOD nrow]]
oplot, lid_time, alt
xyouts, 0.11, v_pos_top[i]-0.04, run, /normal, charsize=1.5

oplot, cloud_time, cloud1, psym=8, symsize=0.7, color=1
oplot, cloud_time, cloud2, psym=8, symsize=0.3, color=2

colorbar, range=extrange, bottom=bottom, ncolors=top-bottom+1,$
	min_value=0, divisions=4, minor=5, format='(i0)', charsize=1.5, $
	position = [0.97, 0.2, 0.99, 0.8], /vertical

ps_plot, /close, /gzip, display=display

;save, filename=dir+savfln

;dir+ncfln, /clobber, /noattcomplain

end
