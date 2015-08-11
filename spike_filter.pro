function spike_filter, var, width, thresh


compile_opt strictarr, strictarrsubs


if (n_elements(width) NE 1)  then width = 10
if (n_elements(thresh) NE 1) then thresh = 0.05

vsmoo = smooth(var, width, /edge_truncate, /nan)
h = abs((var - vsmoo) / vsmoo)

bad = where(h GE thresh, nbad, complement=good, ncomplement=ngood)
vfilt = var
x = indgen(n_elements(vfilt))
if (nbad GT 0) then vfilt[bad] = interpol(vfilt[good], x[good], x[bad])

return, smooth(vfilt, width, /edge_truncate, /nan)


end
