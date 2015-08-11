function get_input, text, default, time=time, $
	box=box, bcol=boxcolor, range=range, format=format


compile_opt strictarr, strictarrsubs


if (n_elements(text) NE 1)     then text = 'Value'
if (n_elements(default) LE 0)  then default = 0.0D
if (n_elements(box) NE 4)      then box = [0.40, 0.62, 0.65, 0.70]
if (n_elements(boxcolor) NE 1) then boxcolor = 2

istime = (n_elements(time) GT 0)

if (n_elements(format) NE 1)   then begin
	if (istime) then format = '%d' else format = '%10.2f'
endif

fmt = string(format='(%"(%%\"Enter ' + text $
	+ (istime ? ' [currently: %s] or enter T followed by time [HHMMSS]' $
	: '  [currently: %s]') + '\")")', format)
if (keyword_set(range)) then $
	fmt = '(%"Enter ' + text + ' range  [currently: %12.5f %12.5f]")'

variable = default
print, format=fmt, default
textbox, box, 'Keyboard input expected', charsize=2, color=boxcolor

if (istime) then begin
	str = ''
	read, str
	str = strlowcase(strcompress(strtrim(str)))
	if (strmid(str, 0, 1) EQ 't') then begin
		t   = secs(long(strmid(str, 1)))
		idx = where(time GE t, cnt)
		variable = (cnt GT 0 ? idx[0] : default)
	endif else begin
		variable = long(str)
	endelse
	variable = max([variable, 0])
	variable = min([variable, n_elements(time)-1])
	print, format = '(%"Accepted: %d (%s)")', $
		variable, hhmmss(time[variable])
endif else begin
	read, variable
	if (keyword_set(range)) then begin
		print, format = '(%"Accepted: %12.5f %12.5f")', variable
	endif else begin
		print, format = '(%"Accepted: ' + format + '")', variable
	endelse
endelse

return, variable

end
