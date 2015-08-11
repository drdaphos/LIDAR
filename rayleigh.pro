pro rayleigh, height, wavel=wavel, cos_offnadir=cos_offnadir, $
	beta=beta, alpha=alpha, tau=tau, pr2=pr2, $
	use_existing_beta=use_existing_beta

compile_opt strictarr, strictarrsubs

if n_elements(wavel) NE 1 then wavel = 354.7
if n_elements(cos_offnadir) NE 1 then cos_offnadir = 1.0
n_height = n_elements(height)

l = wavel / 550.0D

sigma_back = 5.45D-32 * (l^(-4.0D))
sigma_ext  = sigma_back / 0.119366D

if (keyword_set(use_existing_beta)) then begin
	alpha = beta / 0.119366D
endif else begin
	stdatm, height, dens=dens
	beta  = dens * sigma_back
	alpha = dens * sigma_ext
endelse


dtau      = dblarr(n_height)
if (n_height GT 1) then dtau[1:*] = height[1:*] - height[0:(n_height-2)]
dtau      = abs(dtau)
dtau     *= alpha / cos_offnadir

tau = total(dtau, /cumulative)

pr2 = beta * exp(-2.0D * tau)

end
