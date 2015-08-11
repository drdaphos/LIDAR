; copied from /home/fp0100/fpbj/wave_procs/secs.pro
function secs,igmt

; converts a time in GMT to seconds after midnight

isec=0.0

ih=long(igmt/10000.0)
im=long((igmt-ih*10000.0)/100.0)
is=long((igmt-ih*10000.0-im*100.0))

isec=ih*3600.0+im*60.0+is

return,isec
end
