pro lid_voldepol, pinfo, prof, p_cal=p_cal, p_idx=p_idx, $
	voldep=voldep, pr2tot=pr2tot, p_norm=p_norm

@lid_settings.include

; Freudenthaler et al, Tellus 61B, 165 (2009)


if (n_elements(p_cal) LE 0) then p_cal = pinfo.p_cal
if (n_elements(p_idx) LE 0) then p_idx = pinfo.p_idx

; this code does not account for cross-talk:
;
; rel_dr = reform(prof.pr2[*,1] / prof.pr2[*,0])
; p_norm = mean(rel_dr[p_idx[0]:p_idx[1]]) / p_cal
; voldep = rel_dr / p_norm
; pr2tot = reform(prof.pr2[*,0] + prof.pr2[*,1] / p_norm)

; this code accounts for cross-talk:
;
fact = (crosstalk_tp + crosstalk_ts * p_cal) $
	/ (crosstalk_rp + crosstalk_rs * p_cal)

!except = 0
rel_dr = reform(prof.pr2[*,1] / prof.pr2[*,0])
dummy = check_math()
!except = default_except

p_norm = mean(rel_dr[p_idx[0]:p_idx[1]]) * fact
coeff1 = crosstalk_tp / p_norm
coeff2 = crosstalk_ts / p_norm
denom  = crosstalk_tp*crosstalk_rs - crosstalk_rp*crosstalk_ts
coeff3 = (crosstalk_rs - crosstalk_rp) / denom
coeff4 = (crosstalk_tp - crosstalk_ts) / (p_norm * denom)
voldep = (coeff1 * rel_dr - crosstalk_rp) / (crosstalk_rs - coeff2 * rel_dr)
pr2tot = reform(coeff3 * prof.pr2[*,0] + coeff4 * prof.pr2[*,1])


end
