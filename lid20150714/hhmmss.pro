function hhmmss, seconds

compile_opt strictarr, strictarrsubs

nseconds = n_elements(seconds)
s = strarr(nseconds)

for i=0, nseconds-1 do begin
	sec = seconds[i]
	sign = sec GE 0 ? 1 : -1
	sec0 = sign * sec

	hh = floor(sec0 / 3600.0)
	mm = floor((sec0 MOD 3600) / 60.0)
	ss = floor(sec0 MOD 60)

	hh *= sign

	fmt = (hh GE 0 && hh LE 99 ? '(%"%02d:%02d:%02d")' $
		: '(%"%d:%02d:%02d")')
	s[i] = string(format=fmt, hh, mm, ss)
endfor

return, s


end
