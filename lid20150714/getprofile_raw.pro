pro getprofile_raw, inp, nsign, ad_gain, ad_offs, pct_gain, $
	signal, time=time, cnt=cnt, filename=filename
;
; time        = time of profile in seconds after midnight
; cnt         = number of range bins
; signal[i,j] = signal for channel i [0,3] and range bin j [0,cnt-1]
;               channel 0: a/d non-depolarised
;               channel 1: a/d depolarised
;               channel 2: photon count non-depolarised
;               channel 3: photon count depolarised
;

compile_opt strictarr, strictarrsubs

if (n_elements(filename) NE 1) then filename = '' else filename += ': '

t = string(read_binary(inp, data_type=1, data_dims=8))
nn = fix(strsplit(t, '-', count=nt, /extract))
if (nt NE 3) then message2, '*** ' + filename + 'Invalid time ?!? ***'
hh  = nn[0]
min = nn[1]
ss  = nn[2]
time = hh*3600UL + min*60UL + ss

dims = read_binary(inp, data_type=13, data_dims=2, endian='big')
if (dims[0] NE 4UL) then $
	message2, '*** ' + filename + 'Invalid number of channels ?!? ***
cnt  = dims[1]
raw  = read_binary(inp, data_type=3, data_dims=[dims[1],dims[0]], endian='big')

signal = dblarr(4, cnt)
for i=0,1 do begin
	signal[i,*] = raw[*,i] * ad_gain[1,i] / nsign[1] + ad_offs[1,i]
endfor

for i=2,3 do begin
        signal[i,*] = raw[*,i] * pct_gain[i-2]
endfor

end
