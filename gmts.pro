; copied from /home/fp0100/tardis/tardis/mrf_idl/gmts.pro
function gmts,isec,sec_format=sec_format

; converts a time in seconds after midnight to gmt
igmt=0.0

ih=long(isec/3600.0)
im=long((isec-ih*3600.0)/60.0)
is=((isec-ih*3600.0-im*60.0))
if n_elements(sec_format) eq 0 then sec_format='(I2.2)'


sgmt=string(ih,format='(I2.2)')+':'+string(im,format='(I2.2)')+':' $
  +string(is,format=sec_format)
i=strpos(sgmt,' ')
if i(0) NE -1 then strput,sgmt,'0',i

return,sgmt
end
