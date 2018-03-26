pro plot_overlap

inpdir = '~/lidar/lid_info/'
search = 'overlap_*.dat'
psfln  = '~/lidar/Rayleigh/plot_overlap.ps'

file = file_search(inpdir + search, count=nfiles)
title = strarr(nfiles)
npoints = lonarr(nfiles)

for i=0, nfiles-1 do begin
	nn = strsplit(file_basename(file[i]), '_.', /extract)
	title[i] = uplowcase(nn[1])
endfor

for i=0, nfiles-1 do begin
	data = read_ascii(file[i], count=np)
	npoints[i] = np
endfor
maxpoints = max(npoints)

range   = fltarr(maxpoints, nfiles)
overlap = replicate(-1000.0, maxpoints, nfiles)

for i=0, nfiles-1 do begin
	np = npoints[i]
	data = read_ascii(file[i])
	range[0:(np-1),i]   = data.field1[0,*]
	overlap[0:(np-1),i] = data.field1[1,*]
endfor

ps_plot, fln=psfln
col27
cols = [2,3,4,5,6,7,8,9,12,15,20,10,23,19]

plot, range, overlap, /nodata, min_value = -10, $
	xtitle = 'Range (m)', ytitle = 'Overlap factor'
oplot, !x.crange, [1,1]
for i=0, nfiles-1 do $
	oplot, range[*,i], overlap[*,i], min_value = -10, color=cols[i]
legend, title, color=cols, linestyle=0, box=0, /bottom, /right

ps_plot, /close, /gzip, /display


end
