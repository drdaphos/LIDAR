pro htmlstrip, input=input, output=output
; does not correct line splitting

compile_opt strictarr, strictarrsubs

output = ''
if (n_elements(input) LE 0) then return

body_start = where(strpos(strlowcase(input), '<body') GE 0, cnt)
if (cnt LE 0) then body_start = 0 else body_start = body_start[0]

body_stop = where(strpos(strlowcase(input), '</body') GE 0, cnt)
if (cnt LE 0) then body_stop = n_elements(input)-1 $
	else body_stop = body_stop[cnt-1]

input1 = input[body_start:body_stop]

nlines = body_stop - body_start + 1
output = strarr(nlines)
k = 0

for i=0, nlines-1 do begin
	line = input1[i]
	j1 = strpos(line, '<')
	while (j1 GE 0) do begin
		j2 = j1 + strpos(strmid(line, j1), '>')
		if (j1 EQ 0) then line2 = '' else line2 = strmid(line, 0, j1)
		if (j2 GE j1 && j2 LT strlen(line) - 1) $
			then line2 += strmid(line, j2+1)
		line = line2
		j1 = strpos(line, '<')
	endwhile
	j1 = strpos(line, '&')
	while (j1 GE 0) do begin
		j2 = j1 + strpos(strmid(line, j1), ';')
		if (j1 EQ 0) then line2 = '' else line2 = strmid(line, 0, j1)
		line2 += '#'
		if (j2 GE j1 && j2 LT strlen(line) - 1) $
			then line2 += strmid(line, j2+1)
		line = line2
		j1 = strpos(line, '&')
	endwhile
	line = strtrim(strcompress(line), 2)
	if (line NE '') then output[k++] = line
endfor

output = output[0:(k-1)]

end
