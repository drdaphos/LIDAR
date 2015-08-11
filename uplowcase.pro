function uplowcase, string

compile_opt strictarr, strictarrsubs

if (strlen(string) LE 1) then return, strupcase(string)

return, strupcase(strmid(string,0,1)) + strlowcase(strmid(string,1))

end
