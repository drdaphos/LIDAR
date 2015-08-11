function cspot_calc, spot_diam

;The manufacturer’s calibration of PSAP assumes a spot area A(PSAP) of 17.83mm2, 
;equivalent to a circular spot diameter of 4.765mm. This is the diameter of the hole in the filter holder, 
;which is smaller than the exposed filter area owing to the use of O-rings in the filter holder to provide 
;an airtight seal. A(PSAP) is used internally by the instrument in its derivation of absorption. 
;B1999 observed some variation in spot size among instruments and recommend that the actual spot 
;area A(TRUE) for each instrument should be measured and used to correct the spot area of the manufacturer’s 
;reference instrument A(REF). Cspot = Atrue/Aref
;However, Ogren (2010) notes that the spot size correction should in fact compare the actual spot area A(TRUE) 
;for the instrument with the spot area assumed by PSAP in its internal calculations, A(PSAP), rather than 
;comparing it to the reference instrument. Thus, the spot size correction factor should really 
; be Cspot=Atrue/Apsap


; Typical spot diameters are around about 5.3mm for the FAAM instrument. 

if ((spot_diam gt 6.0) or (spot_diam lt 4.5)) then $
  print, 'Spot_diam of ', strtrim(spot_diam), 'is significantly different to usual for this instrument.'

Atrue=!dpi*(spot_diam/2.0)^2.0

Apsap = 17.83 ;mm^2

Cspot = Atrue/Apsap

return, Cspot

end