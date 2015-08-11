pro stdatm, height, temp=temp, press=press, dens=dens

compile_opt strictarr, strictarrsubs

common __stdatm, n_layers, layers, lapse, h0, t0, p0, d0, yp, yd, scale_h


; on the first call to stdatm, compute and store layers

if (n_elements(n_layers) EQ 0) then begin
	t_sea = 288.15D
	p_sea = 1013.0D
	scale_h_sea = 8.46D
	boltzmann = 1.38065D-23
	layers = [11.0D, 20.0D, 32.0D, 47.0D, 51.0D, 71.0D, 85.0D]
	lapse  = [6.49D,  0.0D, -1.0D, -2.8D,  0.0D,  2.8D,  2.0D]

	n_layers = n_elements(layers)

	h0 = dblarr(n_layers)
	t0 = dblarr(n_layers)
	p0 = dblarr(n_layers)
	d0 = dblarr(n_layers)
	yp = dblarr(n_layers)
	yd = dblarr(n_layers)
	scale_h = dblarr(n_layers)

	h0[0] = 0.0D
	h0[1:(n_layers-1)] = layers[0:(n_layers-2)]
	t0[0] = t_sea
	p0[0] = p_sea
	d0[0] = 100.0D * p0[0] / (boltzmann * t0[0])

	for l=1, n_layers-1 do begin
		t0[l] = t0[l-1] + lapse[l-1] * (h0[l-1]-h0[l])
	endfor

	scale_h = scale_h_sea * t0 / t_sea
	idx = where(lapse NE 0.0D)
	yp[idx] = t0[idx] / (lapse[idx] * scale_h[idx])
	yd[idx] = yp[idx] - 1.0

	for l=1, n_layers-1 do begin
		if (lapse[l-1] EQ 0.0) then begin
			p0[l] = p0[l-1] * exp( (h0[l-1]-h0[l]) / scale_h[l-1] )
			d0[l] = d0[l-1] * exp( (h0[l-1]-h0[l]) / scale_h[l-1] )
		endif else begin
			p0[l] = p0[l-1] * ((t0[l] / t0[l-1]) ^ yp[l-1])
			d0[l] = d0[l-1] * ((t0[l] / t0[l-1]) ^ yd[l-1])
		endelse
	endfor
endif


; compute atmospheric parameters corresponding to requested layers

km = height / 1000.0D
n_km = n_elements(km)

temp  = dblarr(n_km)
press = dblarr(n_km)
dens  = dblarr(n_km)
	
for l=0, n_layers-1 do begin
	if (l EQ 0) then idx = where(km LE layers[l], cnt) $
		else idx = where(km GT layers[l-1] AND km LE layers[l], cnt)
	if (cnt LE 0) then continue
	temp[idx] = t0[l] + lapse[l] * (h0[l] - km[idx])
	if (lapse[l] EQ 0.0D) then begin
		press[idx] = p0[l] * exp( (h0[l]-km[idx]) / scale_h[l] )
		dens[idx]  = d0[l] * exp( (h0[l]-km[idx]) / scale_h[l] )
	endif else begin
		press[idx] = p0[l] * ((temp[idx] / t0[l]) ^ yp[l])
		dens[idx]  = d0[l] * ((temp[idx] / t0[l]) ^ yd[l])
	endelse
endfor

;for i=0UL, n_km-1UL do begin
;	idx = where(km[i] GE h0 AND km[i] LE layers)
;	l = idx[0]
;	if (l LT 0 && km[i] LT layers[0]) then l = 0 $
;		else if (l LT 0) then break
;	temp[i] = t0[l] + lapse[l] * (h0[l]-km[i])
;	if (lapse[l] EQ 0.0D) then begin
;		press[i] = p0[l] * exp( (h0[l]-km[i]) / scale_h[l] )
;		dens[i]  = d0[l] * exp( (h0[l]-km[i]) / scale_h[l] )
;	endif else begin
;		press[i] = p0[l] * ((temp[i] / t0[l]) ^ yp[l])
;		dens[i]  = d0[l] * ((temp[i] / t0[l]) ^ yd[l])
;	endelse
;endfor

end

