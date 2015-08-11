function jday, d, m, y

compile_opt strictarr, strictarrsubs

wrong_date = -1
not_leap   = -2

if (y LT 0 || m LT 1 || m GT 12 || d LT 1 || d GT 31 || $
   ((m EQ 4 || m EQ 6 || m EQ 9 || m EQ 11) && d GT 30) || $
   (m EQ 2 && d GT 29)) $
	then return, wrong_date

leap = ((y MOD 4 EQ 0 && y MOD 100 NE 0) || (y MOD 400 EQ 0))
if (m EQ 2 && d EQ 29 && ~leap) then return, not_leap

return, fix(julday(m,d,y) - julday(1,1,y) + 1)

end
