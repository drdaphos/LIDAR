function dblcomp, a, b

compile_opt strictarr, strictarrsubs

return, abs(a/b - 1.0D) LE 0.00005D

end
