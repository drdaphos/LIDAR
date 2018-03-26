pro overlap_fit, campaign

col27

if (n_elements(campaign) NE 1) then campaign = ''
campaign = strlowcase(campaign)

pr2range = [0,1300]
ovlrange = [0, 1.4]
norm_range = [1750.0, 2750.0]	; best
;norm_range = [1300.0, 1600.0]	; for feb2013

case campaign of
	'mevali':     begin
			dir = '~/lidar/Rayleigh/mevali/'
			ovlrange = [0, 1.2]
		      end

	'fennec2012': begin
			dir = '~/lidar/Rayleigh/fennec2012/'
			ovlrange = [0, 1.4]
		      end

	'sambba':     begin
			dir = '~/lidar/Rayleigh/sambba/'
			ovlrange = [0, 1.2]
			pr2range = [0,2000]
                      end

	'feb2013':    begin
			dir = '~/lidar/Rayleigh/feb2013/'
			ovlrange = [0, 1.2]
                        norm_range = [1300.0, 1600.0]
                      end
		      
	'iced':      begin
			dir = '~/lidar/Rayleigh/iced/'
			ovlrange = [0, 1.2]
			norm_range = [1300.0, 2500.0]
                     end

	'monsoon':      begin
			dir = '~/lidar/Rayleigh/monsoon/'
			ovlrange = [0, 1.2]
			norm_range = [900.0, 1500.0]
                     end

	'clarify':      begin
			dir = '~/lidar/Rayleigh/clarify/'
			ovlrange = [0, 1.2]
			norm_range = [800.0, 2000.0]
	                pr2range = [0,2500]
		     end

endcase


outfln = 'overlap_' + campaign
fln = file_search(dir + '*.sav', count=nfiles)
max_ofn = 5.0
range_res = 1.5

_dundef_ = -9.99D37
_nan_    = !values.f_nan
cols0 = [2,3,4,5,6,7,8,9,12,15,20,10,23,19]

nprofs = 0
nhgts  = 0
for i=0, nfiles-1 do begin
	restore, fln[i]
	idx = where(lid_offnadir LE max_ofn, cnt)
	nprofs += cnt
	if (n_elements(lid_height) GT nhgts) then begin
		height = lid_height
		nhgts = n_elements(lid_height)
	endif
print, fln[i], [lid_time[0], lid_time[n_elements(lid_time)-1]] / 3600.
endfor

cols = cols0
for i=1, nprofs/n_elements(cols0) do cols=[cols, cols0]

deltaz = mean(height[1:*]-height)
range = deltaz * findgen(nhgts)

prof0 = {flno:'', date:'', timestr:'', time:0.0, alt:0.0, ofn:0.0, $
	pr2:replicate(_nan_, nhgts), rd:replicate(_nan_, nhgts), $
	mol:replicate(_nan_, nhgts), ran:replicate(_nan_, nhgts), $
	ovl:replicate(_nan_, nhgts)}
prof = replicate(prof0, nprofs)

k=0
for i=0, nfiles-1 do begin
	restore, fln[i]
	info   = strsplit(lidar_info.title, /extract)
	for j=0, n_elements(lid_time)-1 do begin
		if (lid_offnadir[j] GT max_ofn) then continue
		prof[k].flno = info[0]
		prof[k].date = info[1]
		prof[k].time = lid_time[j] / 3600.0
		prof[k].timestr = hhmmss(lid_time[j])
		prof[k].alt  = lid_altitude[j]
		prof[k].ofn  = lid_offnadir[j]
		con = cos(lid_offnadir[j] * !pi / 180.0)
		nh = n_elements(lid_height)
		idx = where(lid_pr2 LT _dundef_ / 1E6, cnt)	;setting errors to nan
		if (cnt GT 0) then lid_pr2[idx] = !values.f_nan ;setting errors to nan
		idx = where(lid_reldep LT _dundef_ / 1E6, cnt)
		if (cnt GT 0) then lid_reldep[idx] = !values.f_nan
		prof[k].pr2[0:(nh-1)] = lid_pr2[j,*,0]
		prof[k].rd[0:(nh-1)]  = lid_reldep[j,*]
		prof[k].ran = (prof[k].alt - height) / con
		rayleigh, reverse(lid_height), pr2=mol, cos_offnadir = con
		prof[k].mol[0:(nh-1)] = reverse(mol)
		idx = where(prof[k].ran GE norm_range[0] $
			AND prof[k].ran LE norm_range[1], cnt)
		kmol = normalize(prof[k].pr2, prof[k].mol, idx[[0,cnt-1]], 0.0) 
		prof[k].mol *= kmol
		ovl0 = prof[k].pr2 / prof[k].mol
		prof[k].ovl = interpol(ovl0, prof[k].ran, range)
		++k
	endfor
endfor

ovl_factor = replicate(_nan_, nhgts)
for j=0, nhgts-1 do ovl_factor[j] = mean(prof.ovl[j], /nan)

;calcualting the second overlap correction where everything is set to 1 at the point where the slope crosses from +1 to -1
ovl_factor2 = ovl_factor
idx = where(ovl_factor GE 1 AND ovl_factor[1:*] LT 1)
idx_one = idx[0]+1
ovl_factor2[idx_one:*] = 1.0
range_max = range[idx_one]

nrange3 = long(range_max / range_res) + 1
range3 = range_res * findgen(nrange3)
ovl_factor3 = interpol(ovl_factor2, range, range3, /spline)
idx = where(ovl_factor3 LT 0.0, cnt)
if (cnt GT 0) then ovl_factor3[idx] = 0.0

ps_plot, fln = dir + outfln + '.ps'
!p.multi = [0,0,2]
tit = string(strupcase(campaign), nprofs, $
	format='(%"All profiles - %s - %d profiles")')

plot, range, ovl_factor, xrange=[0,3000], yrange=ovlrange, /xstyle, /ystyle, $
        /nodata, ytitle='Overlap', title=tit
oplot, !x.crange, [0,0]
oplot, !x.crange, [1,1]
for k=0, nprofs-1 do oplot, range, prof[k].ovl, color=cols[k]

plot, range, ovl_factor, xrange=!x.crange, yrange=!y.crange, /xstyle, /ystyle, $
	/nodata, xtitle='Range (m)', ytitle='Overlap', title='Mean of profiles'
oplot, !x.crange, [0,0]
oplot, !x.crange, [1,1]
oplot, range, ovl_factor, color=4
oplot, range3, ovl_factor3, color=2

for k=0, nprofs-1 do begin
	plot, prof[k].ran, prof[k].pr2, xrange=[0,5000], yrange=pr2range, $
		ytitle = 'PR2', /xstyle, /ystyle, $
		title=string(prof[k].flno, prof[k].date, $
		prof[k].timestr, prof[k].alt, prof[k].ofn, $
		format='(%"%s %s %s ALT=%6.1fm OFF-NADIR=%3.1fdeg")')
	oplot, prof[k].ran, prof[k].mol, color=6
	legend, ['Range corrected signal','Rayleigh scattering'], color=[0,6], $
		linestyle=0, box=0, /bottom, /right, charsize=1

	plot, range, prof[k].ovl, xrange=!x.crange, yrange=ovlrange, $
		/xstyle, /ystyle, /nodata, xtitle='Range (m)', ytitle='Overlap'
	oplot, !x.crange, [1,1]
	oplot, range, prof[k].ovl, color=2
	legend, 'PR2 / Rayleigh', color=2, $
		linestyle=0, box=0, /bottom, /right, charsize=1
endfor

ps_plot, /close, /display, /gzip

;writes the overlap corrcetion to a .dat file
openw, out, dir + outfln + '.dat', /get_lun
for i=0, nrange3-1 do printf, out, range3[i], ovl_factor3[i], $
	format='(%"%8.2f %12.8f")'
free_lun, out

print, 'Remember that you must manually copy the output file to LID_INFO'
print, dir + outfln + '.dat' 


end

