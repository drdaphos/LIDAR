pro slope_method, range, lidpr2, taumol, betamol, $
	smooth=smooth, sample=sample, alpha=alpha, keep_negatives=keep_negatives

;
; Collis, QJRMS 92, 220 (1966)
; Kunz and de Leeuw, AO 32, 3249 (1993)
; approximate solution for deep extinction-dominated layers
;
; Using betamol implies layer with constant backscatter ratio
; i.e. same layering as the molecular atmosphere
;
; In constant alpha layer, error estimated to be less than
; 50 Mm-1. Skipping betamol may be better for very large
; extinction (near ground: ~ 7x the lidar ratio)
; threshold seems too big - do not skip!

compile_opt strictarr, strictarrsubs

if (n_elements(smooth) NE 1) then smooth = 300

if (n_elements(sample) NE 1) then sample = fix(smooth / 2)

if (n_elements(range) NE n_elements(lidpr2)) then $
	message2, '*** Inconsistent input array dimensions ?!?'

if (n_elements(taumol) NE n_elements(lidpr2)) then $
	taumol = 0.0D

if (n_elements(lidpr2) LT 2 * sample) then begin
	alpha = dblarr(n_elements(lidpr2))
	return
endif

save_except = !except
!except = 0

if (n_elements(betamol) EQ n_elements(lidpr2)) then begin
	lnbm = alog(betamol)
endif else begin
        lnbm = dblarr(n_elements(lidpr2))
endelse

lnpr2 = smooth(alog(lidpr2) + 2.0D * taumol, smooth, /nan, /edge_truncate)
range_2 = range[0:*:sample]
lnpr2_2 = lnpr2[0:*:sample]
lnbm_2  = lnbm[0:*:sample]
alpha_3 = ((lnbm_2 - lnbm_2[1:*]) - (lnpr2_2 - lnpr2_2[1:*])) $
	/ (2.0D * (range_2 - range_2[1:*]))
range_3 = (range_2 + range_2[1:*]) / 2.0D 
idx = where(alpha_3 LT 0, cnt)
if (cnt GT 0 && ~keyword_set(keep_negatives)) then alpha_3[idx] = 0.0D
alpha = interpol(alpha_3, range_3, range)

dummy = check_math()
!except = save_except


end

