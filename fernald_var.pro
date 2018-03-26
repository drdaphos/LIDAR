pro fernald_var, height, lidpr2, betamol, ref_idx, ref_br, ratio, $
	cos_offnadir=cos_offnadir, beta=beta, alpha=alpha, klid_ref=klid_ref
;
; version with variable lidar ratio
;
; Fernald, AO 23, 652 (1984)
; Klett, AO 24, 1638 (1985)
;

compile_opt strictarr, strictarrsubs


cnt = n_elements(height)
nref = long(mean(ref_idx))

if (n_elements(lidpr2) NE cnt || n_elements(ratio) NE cnt) then $
	message2, '*** Inconsistent input array dimensions ?!?'

if (n_elements(cos_offnadir) NE 1) then cos_offnadir = 1.0


beta  = dblarr(cnt)
molratio = 1.0D / 0.119366D
deltaratio = ratio - molratio
klid_ref = normalize(lidpr2, betamol, ref_idx, ref_br)
beta[nref]  = (1.0D + ref_br) * betamol[nref]


; vectorized code is hard to read but is much much faster!!
; however 10 temporary arrays are created and use up memory.
; reverse arrays are needed for inward integration.
; for non-vectorized code, see fernald_nv.pro

hh = reverse(height[0:nref])
bm = reverse(betamol[0:nref])
pr = reverse(lidpr2[0:nref])
rt = 0.5D * reverse(ratio[0:(nref-1)] + ratio[1:nref])
dr = 0.5D * reverse(deltaratio[0:(nref-1)] + deltaratio[1:nref])
nr = nref-1

; inward  integration: nstep = -1
; outward integration: nstep = +1

for nstep = -1, 1, 2 do begin

	dz = abs(hh[1:*] - hh[0:nr]) * (nstep / cos_offnadir)
	da = dr * (bm[1:*] + bm[0:nr]) * dz
	a  = total(da, /cumulative)
	ea = exp(-a)
	db = rt * (pr[1:*] + pr[0:nr]) * ea * dz
	b  = total(db, /cumulative)
	ba = pr[1:*] * ea / (klid_ref - b)

	if (nstep EQ -1) then begin
		beta[0:(nref-1)] = reverse(ba)
		hh = height[nref:*]
		bm = betamol[nref:*]
		pr = lidpr2[nref:*]
		rt = 0.5D * (ratio[nref:*] + ratio[(nref+1):*])
		dr = 0.5D * (deltaratio[nref:*] + deltaratio[(nref+1):*])
		nr = cnt - nref - 2
	endif else begin
		beta[(nref+1):*] = ba
	endelse

endfor


beta -= betamol
alpha = ratio * beta


end

