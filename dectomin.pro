function dectomin, angle, north, south, ndec=ndec, decimal=decimal

compile_opt strictarr, strictarrsubs

nangles = n_elements(angle)
s = strarr(nangles)

if n_elements(north) NE 1 then north = 'N'
if n_elements(south) NE 1 then south = 'S'
if (n_elements(ndec) NE 1 || ndec < 0) then ndec=1
if (n_elements(decimal) NE 1) then decimal=0
thresh = 60.0D - 5.0D * (10.0D ^ (-1.0D - ndec))

for i=0, nangles-1 do begin
	ang = angle[i]
	if (~finite(ang)) then begin
		s[i] = '***'
		continue
	endif

	neg = 0

	if (ang LT 0.0D) then begin
		ang = -ang
		neg = 1
	endif

	if (decimal) then begin
		if (ndec EQ 0) then begin
			s[i] = string(format='(%"%d%s")', round(ang), $
				neg ? south : north)
		endif else begin
			fmt = string(format='(%"%%0.%df")', ndec)
			s[i] = string(format='(%"' + fmt + '%s")', ang, $
				neg ? south : north)
		endelse
	endif else begin
		deg = floor(ang)
		min = (ang - deg) * 60.0D
		if (min GT thresh) then begin
			min = 0.0D
			++deg
		end

		if (ndec EQ 0) then begin
			s[i] = string(format='(%"%d°%02d''%s")', $
				fix(abs(deg)), fix(round(min)), $
				neg ? south : north)
		endif else begin
			fmt = string(format='(%"%%0%d.%df")', 3+ndec, ndec)
			s[i] = string(format='(%"%d°' + fmt + '''%s")', $
				fix(abs(deg)), min, neg ? south : north)
		endelse
	endelse
endfor

return, s


end
