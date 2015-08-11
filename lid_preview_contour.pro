pro lid_preview_contour, time, knorm=knorm, xran=xran, yran=yran


@lid_settings.include


if (n_elements(nprofiles) NE 1 || nprofiles LE 0L) then $
	message, 'No data. lid_data_read must be called first.'


xsiz = 640
ysiz = 480
nlevs = 30
palette = 0
wnum = 1

if (n_elements(knorm) NE 1) then knorm = 1.0D
if (n_elements(xran) NE 2) then xran = [0.0D, 3000.0D]
if (n_elements(yran) NE 2) then yran = [ymin, ymax]

view_window2 = max([view_window / 60.0D, target_it * view_min / 3600.0D])
time2 = time / 3600.0D
tstart = time2 - view_window2 / 2.0D
tstop  = time2 + view_window2 / 2.0D

xmin = [xran[0], 0.5]
xmax = [xran[1], 2.5]

device, window_state=window_open
idx = where(profinfo.time GE tstart*3600.0D $
	AND profinfo.time LE tstop*3600.0D, cnt)
if (cnt LE 1) then begin
	if (window_open[wnum]) then wdelete, wnum
	return
endif
if (~window_open[wnum]) then window, wnum, xsize=xsiz, ysize=ysiz

blank = where(profinfo[idx[1:*]].time - profinfo[idx].time $
	GE 0.8 * (profinfo[idx[1:*]].it + profinfo[idx].it), nblank)

nalt = long(ceil(double(maxaltitudes) / smooth))
tdata = replicate(_dundef_, cnt + 2*nblank)
ydata = replicate(_dundef_, cnt + 2*nblank, nalt)
pdata = replicate(_dundef_, cnt + 2*nblank, nalt, 2)

margin = (smooth + 1) * range_res
kmin = replicate(long(nalt-1), cnt)
kmax = lonarr(cnt)

j = 0
for i=0, cnt-1 do begin
	p = idx[i]
	pinfo = profinfo[p]
	prof  = profile[p]
	tdata[j]   = pinfo.time / 3600.0D
	ydata[j,*] = prof.height[0:*:smooth]
	pdata[j,*,0] = prof.pr2[0:*:smooth,0]

	idx2 = where(ydata[j,*] GE  yran[0]-margin $
		AND ydata[j,*] LE yran[1]+margin, cnt2)
	if (cnt2 GT 0) then begin
		kmin[i] = idx2[0]
		kmax[i] = idx2[cnt2-1]
	endif

	!except = 0
	pdata[j,*,1] = knorm * prof.pr2[0:*:smooth,1] / prof.pr2[0:*:smooth,0]
	dummy = check_math()
	!except = default_except

	j++
	dummy = where(i EQ blank, nfound)
	if (nfound GT 0) then begin
		tdata[j++] = (profinfo[p].time+0.5D*profinfo[p].it)/3600.0D
		tdata[j++] = (profinfo[p+1].time-0.5D*profinfo[p+1].it)/3600.0D
	endif
endfor

k1 = min(kmin)
k2 = max(kmax)
if (k2 LE k1) then begin
	k1 = 0
	k2 = nalt - 1
endif

wset, wnum
wshow, wnum
set_palette, palette, bottom=bottom, top=top, maxlevs=maxlevs
nlevs = min([nlevs, maxlevs])
!p.multi = [0, 0, 2]

for i=0, 1 do begin
	levs = xmin[i] + (xmax[i]-xmin[i]) * dindgen(nlevs) / nlevs
	cols = bottom + bytscl(indgen(nlevs), top=top-bottom)
	contour, pdata[*,k1:k2,i], tdata, ydata[*,k1:k2], $
		xrange=[tstart, tstop], yrange=yran, /xstyle, /ystyle, $
		levels=levs, c_colors = cols, /cell_fill, $
		min_value = xmin[i], ytickformat='(i)'
	oplot, [time2, time2], yran
endfor


end

