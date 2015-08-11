PRO psap_correct,psap,psap_adj,green_scatt,red_scatt,psap_adj_red,psap_adj_blue, $
  quiet=quiet, cflow=cflow, cspot=cspot

; Based on Bond et al Aerosol Sci. Tech. 30:582-600 (1999)
; Modifed 18/08/10 by KFT to correct TN31 errors and include Ogren AST 44, 2010 correction
; Note that Bond 99 correction includes an implicit adjustment from the operating wavelength 
; of the PSAP to 550nm via K1, K2
; PSAP data is output at STP while neph data is at ambient - CHECK THIS!

; INPUTS
;     psap = uncorrected psap data, at STP
;     green_scatt = AO98 uncorrected neph green scattering data (m^-1) AT STP
;     red_scatt = uncorrected neph red scattering data (m^-1) AT STP
; (red_scatt is no longer required but left in for backward compatability)

; OUTPUTS
;     psap_adj = corrected psap absorption at 550nm, at STP
;     psap_adj_red = corrected psap absorption at 700nm, at STP
;     psap_adj_blue = corrected psap absorption at 450nm, at STP

; KEYWORDS
;     quiet - set this to stop potentially useful messages being printed to screen
;     cflow - set this to the value established for the campaign (ask FAAM/Jamie Trembath)
;     cspot - set this to the value established for the campaign (ask FAAM/Jamie Trembath)

; MODIFIED
;	  16/04/2012 KFT to check that scattering and absorption not both zero
; 	02/01/2013 KFT to include QUIET keyword and keywords to supply Cflow and Cspot 
;=======================================================================================================

; Version of this code before mods on 02/01/13 has Cflow and Cspot hard-wired in as 0.9091 and 1.186.
; In order to make this the same if the new keywords aren't used (i.e. backwards compatible), these 
; values for Cflow and Cspot are set as the defaults.
if ~keyword_set(Cflow) then Cflow = 0.9091 
if ~keyword_set(Cspot) then Cspot = 1.186

if ~keyword_set(quiet) then begin
	print, 'Cflow used is ', strtrim(Cflow, 2)
	print, 'Cspot used is ', strtrim(Cspot, 2)
endif

; correct PSAP data for errors in flow rate, filter area and scattering effects 
k1 = 0.02
k2 = 1.22

Ogren = 0.873  ; Apsap/Aref is Ogren's correction


if n_elements(green_scatt) ge 10 then begin
    psap_adj=((Ogren * Cspot * Cflow * psap) - (k1*smooth(green_scatt, 10, /nan, /edge_truncate)))/k2
endif else begin
    psap_adj=((Ogren * Cspot * Cflow * psap) - (k1*green_scatt))/k2
endelse


; Flag negative values of absorption
; changed 28/01/10 KT to flag the issue rather than change the absorption values to 0.0
; changed again 02/01/13 KT to use NaNs instead.

n=n_elements(psap_adj)

psap_proc_flag=intarr(n)

ssa = fltarr(n)
idx1 = where(psap_adj+green_scatt NE 0.0, complement=nan_mask, cnt1) 

if (cnt1 GT 0) then ssa[idx1] = green_scatt[idx1]/abs(psap_adj[idx1]+green_scatt[idx1])
if ((n-cnt1) GT 0) then ssa[nan_mask]=!values.f_nan   ; set values to NaN where denominator would be 0.0

idx2 = where(psap_adj LT 0.0 AND ssa GT 1.1, cnt2) 
if (cnt2 GT 30 && ~keyword_set(quiet)) then print, 'The PSAP dataset contains at least 30 secs of negative values that will result in SSA>1.1'


; work out red and blue absorption by the 1/wavelength rule
; this approximation is based on Mie calculations for biomass burning aerosol
; but will not necessarily apply very well to other aerosol types
if ~keyword_set(quiet) then $
  print, '!!Note that BB aerosol assumption made in estimating psap_adj_red and psap_adj_blue!!'

wavelength_exponent = -1.
psap_adj_red  = (0.70/0.55)^(wavelength_exponent) * psap_adj
psap_adj_blue = (0.45/0.55)^(wavelength_exponent) * psap_adj

end
