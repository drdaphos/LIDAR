;INTERPOLATE2D
;interpolate gridded 2-dimensional data onto an array of positions
;e.g. modeled data on a grid interpolated on a set of aircraft positions
;each point is interpolated using the four nearest grid points
;if out of the domain boundaries, it will be flagged
;uses IDL (not TIDL)
;
;by Franco Marenco
;please report any bugs and/or your modifications to me :-)
;
;input:   xpos, ypos: the positions at which you want the interpolated data
;input:   xarr, yarr: the existing data grid (1-dimensional arrays)
;input:   valarr: the data values (2-dimensional array)
;input:   outbound: out of boundary positions are set to this (default -9.99D99)

;return value: the interpolated values (scalar or 1-dimensional array)


function interpolate2d, xpos, ypos, xarr, yarr, valarr, outbound=outbound

compile_opt strictarr, strictarrsubs

if (n_elements(outbound) NE 1) then outbound = -9.99D99

nx = n_elements(xarr)
ny = n_elements(yarr)
np = n_elements(xpos)
nv = size(valarr,/dimensions)
if (size(xarr,/n_dimensions) NE 1 || size(yarr,/n_dimensions) NE 1 $
   || size(valarr,/n_dimensions) NE 2) then $
	message, '*** Wrong array dimensions ?!?'
if (nv[0] NE nx || nv[1] NE ny || n_elements(ypos) NE np) then $
	message, '*** Inconsistent array sizes ?!?'

fp = dblarr(np)

for i = 0L, np-1 do begin
	xp = xpos[i]
	yp = ypos[i]
	indx = where(xp GE xarr[0:(nx-2)] AND xp LT xarr[1:(nx-1)])
	indy = where(yp GE yarr[0:(ny-2)] AND yp LT yarr[1:(ny-1)])
	if (indx LT 0  AND  xp EQ xarr[(nx-1)]) then indx = nx-2
	if (indy LT 0  AND  yp EQ yarr[(ny-1)]) then indy = ny-2
	if (indx GE 0  AND  indy GE 0) then begin
		x = xarr[indx:(indx+1)]
		y = yarr[indy:(indy+1)]
		f = valarr[indx:(indx+1),indy:(indy+1)]
		den = (x[1] - x[0]) * (y[1] - y[0])
		for ix = 0,1 do begin
			for iy = 0,1 do begin
				sx = 1 - 2 * ix
				sy = 1 - 2 * iy
				fp[i] += f[ix,iy] * sx * sy $
				   * (x[1-ix]-xp) * (y[1-iy]-yp) / den
			endfor
		endfor
	endif else begin
		fp[i] = outbound
	endelse
endfor

if (np EQ 1) $
	then return, fp[0] $
	else return, fp

end
