function get_range, y, x, text, color=color, one=one, $
	chan=chan, box=box, bcol=boxcolor, altbox=altbox, altran=altran


compile_opt strictarr, strictarrsubs

ny = n_elements(y)
nx = n_elements(x)
ninp = keyword_set(one) ? 1 : 2

if (ny LE 0 || nx NE ny)       then message, 'X/Y array error'
if (n_elements(color) NE 1)    then color=2
if (n_elements(text) NE 1)     then text=''
if (n_elements(chan) NE 1)     then chan = 0
if (n_elements(box) NE 4)      then box = [0.40, 0.62, 0.65, 0.70]
if (n_elements(boxcolor) NE 1) then boxcolor = 2

altboxwrong = 0
altboxdim = size(altbox, /dimensions)
altrandim = size(altran, /dimensions)

if (n_elements(altboxdim) EQ 1 && altboxdim EQ 0) then begin
	naltbox = 0
endif else if (n_elements(altboxdim) EQ 1 && altboxdim EQ 4) then begin
	naltbox = 1
endif else if (n_elements(altboxdim) EQ 2 && altboxdim[0] EQ 4) then begin
	naltbox = altboxdim[1]
endif else begin
	altboxwrong = 1
endelse

if (n_elements(altrandim) EQ 1 && altrandim EQ 0) then begin
	naltran = 0
endif else if (n_elements(altrandim) EQ 1 && altrandim EQ 2) then begin
	naltran = 1
endif else if (n_elements(altrandim) EQ 2 && altrandim[0] EQ 2) then begin
	naltran = altrandim[1]
endif else begin
	altboxwrong = 1
endelse

if (altboxwrong || (naltran NE naltbox)) then $
	message, 'Invalid altbox/altran.'

device, /cursor_crosshair
selection = lonarr(ninp)
xrange = !x.crange
yrange = !y.crange


print, format='(%"Use mouse near Channel %d curve to select ' + $
	'the %s%s (%d mouse clicks)")', chan, text, $
	(keyword_set(one) ? '' : ' range'), ninp

textbox, box, 'Mouse input expected', charsize=2, color=boxcolor


for i=0, ninp-1 do begin
	repeat begin
		cursor, xclick, yclick, /data, wait=3, /change
		normal = convert_coord(xclick, yclick, /data, /to_normal)
		for j=0, naltbox-1 do begin
			if (in_box(normal[0], normal[1], altbox[*,j]) && $
			   ~(altran[0,j] EQ 0 AND altran[1,j] EQ 0)) then begin
				selection = reform(altran[*,j])
				goto, done
			endif
		endfor
		inwindow = (xclick GE xrange[0] && xclick LE xrange[1] $
			&& yclick GE yrange[0] && yclick LE yrange[1])
		dummy = min(abs(y-yclick), idx)
		nearcurve = (nx LE 0 || abs(x[idx]-xclick) $
			LE abs(xrange[1]-xrange[0])/2.0)
	endrep until (inwindow && nearcurve)
	oplot, [x[idx]], [y[idx]], color=color, psym=1, thick=2, symsize=2
	selection[i] = idx
endfor

done:

selection = ascending(selection)

fmt = keyword_set(one) ? '(%"Accepted: %d m")' : $
	'(%"Accepted: %d-%d m")'
print, format=fmt, ascending(y[selection])
wait, 0.2


return, selection


end
