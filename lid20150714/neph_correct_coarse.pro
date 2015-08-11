; copied from /home/fp0100/fpbj/wave_procs/neph_correct_coarse.pro
; plus subsequent modifications by Ben Johnson
;

PRO neph_correct_coarse,green,red,blue,green_adj,red_adj,blue_adj,angstrom,quiet=quiet

minv = 1.e-6
maxv = 1.e-2
good =  where(    blue  gt minv $
              and green gt minv $
              and red   gt minv $
              and blue  lt maxv $
              and green lt maxv $
              and red   lt maxv $
              ,ngood) 

angstrom  = replicate(0., n_elements(green))
angstromb = replicate(0., n_elements(green))
angstromr = replicate(0., n_elements(green))

if ngood gt 0 then begin
    angstrom(good)  = -(alog10(blue(good)/red(good))/alog10(450.0/700.0))
    angstromb(good)  = -(alog10(blue(good)/green(good))/alog10(450.0/550.0))
    angstromr(good)  = -(alog10(green(good)/red(good))/alog10(550.0/700.0))
endif

; CORRECTIONS FROM ANDERSON AND OGREN (1998), SEE TECH NOTE 31.

Cts_550    = (-0.138 * angstrom)  + 1.337 ; for super-micron particles
Cts_550b   = (-0.156 * angstrom)  + 1.365 ; with no cut
Cts_550r   = (-0.113 * angstrom)  + 1.297   

green_adj = green * Cts_550
blue_adj  = blue  * Cts_550b
red_adj   = red   * Cts_550r

if (ngood lt n_elements(green) and keyword_set(quiet) eq 0) then print, 'Neph_correct_coarse: Some neph values outside good range'

end
