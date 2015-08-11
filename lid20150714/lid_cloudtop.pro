pro lid_cloudtop, index=index, cloud_top_height=cloud_top_height, $
	trange=trange, yrange=yrange, xrange=xrange, display=display


@lid_settings.include

openw, lgf, logfln, /get_lun, /append
printf, lgf, '--> LID_CLOUDTOP'


if (n_elements(nprofiles) NE 1 || nprofiles LE 0L) then $
	message, 'No data. lid_data_read must be called first.'

if (n_elements(index) LE 0) then index = indgen(nclouds)
n_index = n_elements(index)

if (n_elements(trange) EQ 2) then begin
	tran_idx = where(profinfo.time GE trange[0]*3600.0D $
		AND profinfo.time LE trange[1]*3600.0D, ntran)
	tstyle = 1
endif else begin
	tran_idx = indgen(nprofiles)
	ntran = nprofiles
	tstyle = 0
endelse

if (n_elements(xrange) NE 2) then xrange = [0,3000]

if (n_elements(yrange) NE 2) then begin
	if (view EQ _nadir_) then begin
		yrange = [ymin, max(profinfo.alt)]
	endif else begin
		yran = [min(profinfo.alt), ymax]
	endelse
endif


dummy = where(index LT 0 OR index GE nclouds, n_invalid)
if (n_index GT nclouds || n_invalid GT 0) then message, 'Invalid index.'

topbase = (view EQ _nadir_ ? 'top' : 'base')
append = '_cloud' + topbase + '.ps'
psfln = outfln   + append

set_plot, 'ps'
device, /color, /landscape, bits_per_pixel=8, filename=psfln
set_palette, 4, bottom=bottom, top=top, maxlevs=maxlevs
nlevs=min([maxlevs,32])

xtit   = 'Time after midnight (h)'
tim    = profinfo.time/3600.0D

charthick = 4
linethick = 4
charsize  = 1.15
axischarsize = 1.5
colors = [2, 3, 4, 7, 8, 23]


; Cloud tops
ct_hgt = replicate(_dundef_, nprofiles, nclouds)
dummy = where(profinfo.ct_idx GT 0, n_cld)

if (n_cld GT 0) then begin
	for p=0, nprofiles-1 do begin
		prof  = profile[p]
		pinfo = profinfo[p]
		idx = where(pinfo.ct_idx GT 0, n_idx)
		if (n_idx GT 0) then $
			ct_hgt[p,idx] = prof.height[pinfo.ct_idx[idx]]
	endfor
endif

idx = where(ct_hgt GE ymin, n_idx)
yymin = ymin
yymax = 10000
if (n_idx GT 0) then yymax = max(ct_hgt[idx], min=yymin)

cloud_top_height = ct_hgt[*, index]

plot, tim, cloud_top_height[*,0], /nodata, yrange=[yymin,yymax], $
	ytitle='Cloud ' + topbase + ' height (m)', $
	xrange=trange, xstyle=tstyle, title=globaltitle, xtitle=xtit, $
	charsize=charsize, xcharsize=axischarsize, $
	ycharsize=axischarsize, charthick=charthick, $
	thick=linethick, xthick=linethick, ythick=linethick
for i=0, n_index-1 do oplot, tim, cloud_top_height[*,i], psym=1, $
	color=colors[i], min_value=ymin, thick=linethick

;;;

levs = xrange[0] + (xrange[1]-xrange[0]) * dindgen(nlevs) / nlevs
cols = bottom + bytscl(indgen(nlevs), top=top-bottom)

contour, lid_pr2[*,*,0], tim, lid_height, min_value=0, $
	levels=levs, c_colors=cols, /cell_fill, xrange=!x.crange, $
	yrange=!y.crange, title=globaltitle, xtitle=xtit, $
	ytitle='Altitude (m)', $
	charsize=charsize, xcharsize=axischarsize, $
	ycharsize=axischarsize, charthick=charthick, $
	thick=linethick, xthick=linethick, ythick=linethick
for i=0, n_index-1 do oplot, tim, cloud_top_height[*,i], psym=1, $
	min_value=ymin, thick=linethick

;;;

for k=0, ntran-1 do begin
	p = tran_idx[k]
	prof  = profile[p]
	pinfo = profinfo[p]
	plot, prof.pr2[*,0], prof.height, min_value=ymin, $
		xrange=xrange, yrange=yrange, /xstyle, /ystyle, $
		title=string(pinfo.title, p, format='(%"%s (%d)")'), $
		xtitle=typetit[_pr2_], ytitle='Altitude AMSL (m)', $
		charsize=charsize, xcharsize=axischarsize, $
                ycharsize=axischarsize, charthick=charthick, $
                thick=linethick, xthick=linethick, ythick=linethick, $
                ytickformat='(i)'
	for i=0, n_index-1 do oplot, xrange, $
		[cloud_top_height[p,i], cloud_top_height[p,i]], $
		color=colors[i], min_value=ymin, thick=linethick
endfor


@lid_plot_cleanup.include


end
