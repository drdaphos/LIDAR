; copied from /home/h01/frhf/procs/col27.pro
; courtesy of Simon Osborne

pro col27

; color 0 black (0,0,0)
; color 1 white (255,255,255)
; color 2 red (255,0,0)
; color 3 green (0,255,0)
; color 4 darkish blue (0,0,255)
; color 5 yellow (255,255,0)
; color 6 cyan (0,255,255)
; color 7 magenta (255,0,255)
; color 8 orange (255,127,0)
; color 9 reddy-purple (255,0,127)
; color 10 salmon pink (255,127,127)
; color 11 lime green (127,255,0)
; color 12 metallic green (0,255,127)
; color 13 another green, slightly warmer (127,255,127)
; color 14 dark purple (127,0,255)
; color 15 nice royal blue (0,127,255)
; color 16 a bit more lilacky (127,127,255)
; color 17 nice darkish purple - looks good on paper (127,0,127)
; color 18 dark bluey-purple (0,0,127)
; color 19 grey (127,127,127)
; color 20 darkish green (0,127,0)
; color 21 bluey-grey (0,127,127)
; color 22 olive green (127,127,0)
; color 23 dark brick (127,0,0)
; color 24 bright light blue (127,255,255)
; color 25 pinker than magenta (255,127,255)
; color 26 straw (255,255,127)

red=[0,255,255,0,0,255,0,255,255,255,255,127,0,127,127,0,127,127,0,127,0,0,$
 127,127,127,255,255]
green=[0,255,0,255,0,255,255,0,127,0,127,255,255,255,0,127,127,0,0,127,127,$
 127,127,0,255,127,255]
blue=[0,255,0,0,255,0,255,255,0,127,127,0,127,127,255,255,255,127,127,127,0,$
 127,0,0,255,255,127]
tvlct,red,green,blue

return
end

