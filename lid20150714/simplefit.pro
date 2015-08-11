;SIMPLEFIT
;linear fit of type y = a + bx
;similar syntax to linfit (idl built-in); they should be equivalent
;uses IDL (not TIDL)
;
;by Franco Marenco
;please report any bugs and/or your modifications to me :-)
;
;input:   x,y is your experimental data
;input:   measure_errors: weigh your data with experimental error
;
;return value: [a, b], the fit parameters
;output:  sigma=[s_a, s_b], the uncertainties on a and b
;output:  r: correlation coefficient


function simplefit, x, y, measure_errors=err, sigma=sigma, r=r

compile_opt strictarr, strictarrsubs

ndata   = n_elements(x)
knowsig = (n_elements(err) GT 0)
if (n_elements(y) NE ndata)  then message, '*** x and y different dims ?!?'
if (knowsig && n_elements(err) NE ndata) then $
	message, '*** err dims different than x and y ?!?'
if (ndata LE 2) then message, '*** Insufficient data points ?!?'

if (knowsig) then p = 1.0D / (err*err) $
	else p = replicate(1.0D, ndata)

s   = total(p)
sx  = total(p*x)
sxx = total(p*x*x)
sy  = total(p*y)
sxy = total(p*x*y)
syy = total(p*y*y)

delta = s * sxx - sx * sx

a = (sxx * sy - sx * sxy) / delta
b = (s * sxy  - sx * sy)  / delta

dy = y - (a + b*x)

if (knowsig) then sig = 1.0D $
	else sig = total(dy*dy) / (ndata-2)

s_a = sqrt(sig * sxx / delta)
s_b = sqrt(sig * s / delta)

r = (sxy - sx*sy/ndata) / sqrt((sxx - sx*sx/ndata)*(syy - sy*sy/ndata))
model = [a, b]
sigma = [s_a, s_b]

return, model

end

