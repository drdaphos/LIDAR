pro ps_plot, fln=fln, portrait=portrait, landscape=landscape, $
	a_paper=a_paper, close=close, display=display, gzip=gzip, wait=wait, $
	linethick=linethick, charthick=charthick, charsize=charsize, $
	axischarsize=axischarsize


on_error, 1
compile_opt strictarr, strictarrsubs

common __ps_plot, init, fln0, landscape0, p0, x0, y0, colortable

no_gzip_win = 1

ux =  (!version.os_family EQ 'unix')
gzip_cmd = (ux ? 'gzip -f' : '')
ps_cmd_l = (ux ? 'gv -orientation=seascape -media bbox'           : 'gsview32')
ps_cmd_p = (ux ? 'gv -orientation=portrait -media bbox -scale -1' : 'gsview32')

if (n_elements(a_paper) NE 1) then a_paper = 4
a_factor = 2.0D ^ ((4 - a_paper) / 2.0D)
c_factor = (a_paper GT 4 ? a_factor : 1.0D)

xoffset0 = 0.5
yoffset0 = 1.0
xsize0 = 20
ysize0 = 27.5

default_thick        = 5
default_charsize     = 1.5  * c_factor
default_axischarsize = 1.25
if (n_elements(linethick) NE 1)    then linethick = default_thick
if (n_elements(charthick) NE 1)    then charthick = default_thick
if (n_elements(charsize) NE 1)     then charsize = default_charsize
if (n_elements(axischarsize) NE 1) then axischarsize = default_axischarsize

display0 = 0
gzip0 = 0
wait0 = 0

if (~keyword_set(close)) then begin

	if (keyword_set(init)) then begin
		ps_plot, /close
		message, 'Plot was already initiated.', level = -1
	endif

	if (n_elements(fln) NE 1) then fln0 = '/tmp/idl.ps' else fln0 = fln

	if (n_elements(landscape) NE 1 AND n_elements(portrait) NE 1) then begin
		landscape0 = 1
	endif else if (n_elements(landscape) NE 1) then begin
		landscape0 = ~portrait
	endif else begin
		landscape0 = landscape
	endelse

	if (landscape0) then begin
		xoffset = xoffset0
		yoffset = yoffset0 + ysize0
		xsize = ysize0
		ysize = xsize0
	endif else begin
		xoffset = xoffset0
		yoffset = yoffset0
		xsize = xsize0
		ysize = ysize0
	endelse

	xoffset  *= a_factor
        yoffset  *= a_factor
        xsize    *= a_factor
        ysize    *= a_factor

	p0 = !p
	x0 = !x
	y0 = !y
	tvlct, colortable, /get

	set_plot, 'ps'
	device, /color, landscape=landscape0, bits_per_pixel=8, filename=fln0, $
		xoffset=xoffset, yoffset=yoffset, xsize=xsize, ysize=ysize

	!p.thick     = linethick
	!p.charsize  = charsize
	!p.charthick = charthick
	!x.thick     = linethick
	!x.charsize  = axischarsize
	!y.thick     = linethick
	!y.charsize  = axischarsize

	init = 1

endif else begin

	if (~keyword_set(init)) then begin
		message, 'No plot was initiated.', level = -1
	endif

	ps_cmd = (landscape0 ? ps_cmd_l : ps_cmd_p)
	display0 = (keyword_set(display) AND keyword_set(ps_cmd))
	gzip0 = (keyword_set(gzip) AND keyword_set(gzip_cmd))
	wait0 = keyword_set(wait)

	device, /close_file
	if (ux) then set_plot, 'x' else set_plot, 'win'
	tvlct, colortable
        !p = p0
        !x = x0
        !y = y0

	if (gzip0) then begin
		spawn, gzip_cmd + ' ' + fln0, noshell=~ux
		fln0 += '.gz'
	endif

	if (display0) then begin
		cmd = ps_cmd + ' ' + fln0
		if (ux) then begin
			spawn, cmd + (wait0 ? '' : ' &')
		endif else begin
			spawn, cmd, /noshell, nowait=~wait0
		endelse
	endif

	init = 0

endelse

fln       = fln0
landscape = landscape0
portrait  = ~landscape0
display   = display0
gzip      = gzip0
wait      = wait0

end
