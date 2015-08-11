pro readheader, flp, name, value, delimiter=delimiter, maxargs=maxargs

compile_opt strictarr, strictarrsubs

if (n_elements(delimiter) NE 1) then delimiter = '='
if (n_elements(maxargs) NE 1)   then maxargs = 1

line = ''
readf, flp, line
args = strsplit(line, delimiter, count=nargs, /extract)
name = strlowcase(args[0])
if (nargs EQ 2) then value = args[1] $
	else if (nargs GT 2) then value = args[1:*] $
	else value = '0'
if (maxargs GT 0 && nargs GT maxargs + 1) then $
	message2, '*** Extra values ?!? ***'


end
