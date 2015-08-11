function ordered, height

compile_opt strictarr, strictarrsubs

margin = 0.1

h = ascending(height)
return, [h[0]-margin, h[1]+margin]


end
