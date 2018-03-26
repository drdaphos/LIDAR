pro read_run_prof, filename, name=name, start=start, stop=stop, $
	run_idx=run_idx, prof_idx=prof_idx, oth_idx=oth_idx


compile_opt strictarr, strictarrsubs


start = 0.0
stop  = 0.0
name   = ''
openr, inp, filename, /get_lun
k = 0
while (~eof(inp)) do begin
	line = ''
	readf, inp, line
	line = strcompress(strtrim(line, 2))
	if (line EQ '') then continue
	words = strsplit(line, /extract)
	start = [start, secs(long(words[0]))]
	stop  = [stop,  secs(long(words[1]))]
	name  = [name, words[2]]
	++k
endwhile
free_lun, inp
start = start[1:*]
stop  = stop[1:*]
name  = name[1:*]

initial = strupcase(strmid(name,0,1))
idx = where(initial EQ 'R', cnt)
if (cnt GT 0) then run_idx = idx
idx = where(initial EQ 'P', cnt)
if (cnt GT 0) then prof_idx = idx
idx = where(initial NE 'R' AND initial NE 'P', cnt)
if (cnt GT 0) then oth_idx = idx

end
