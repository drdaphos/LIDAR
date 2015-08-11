pro getheader_raw, inp, nprof=nprof, nshots=nshots, it=it, res=res, $
	nsign=nsign, ad_gain=ad_gain, ad_offs=ad_offs, pct_gain=pct_gain, $
	cnt=cnt, blind=blind, start=start, stop=stop, $
	get_time=get_time, quick=quick, filename=filename
;
; nprof    = number of profiles in input file (integer) 
; nshots   = number of laser shots per profile (integer)
; it       = integration time in seconds (double)
; res      = range resolution (double)
; nsign    = number of profiles in section (double array, 2 elements)
;            nsign[section] with section = 0,1
; ad_gain  = a/d gain in section and channel (double array, 2x2 elements)
; ad_offs  = a/d offset in section and channel (double array, 2x2 elements)
;            ad_gain[section,channel], ad_offs[section,channel]
; pct_gain = photon count gain (double array, 2 elements)
;            pct_gain[channel]
; cnt      = dimension of blind reference profile
; blind    = blind reference profile (double array, 2 x cnt elements)
;            blind[channel,profilepoint]
; start    = start time of first profile, only if /get_time (unsigned long)
; stop     = estimated finish of last profile, only if /get_time (unsigned long)
; get_time = if set (and not quick), get the start_time of first profile
; quick    = if set, skip reading the blind reference profile
;
; where:
;            section 0 is BlindRef and section 1 is Raw signal
;            channel 0 is non-depolarised and channel 1 is depolarised
;            profilepoint runs from 0 to cnt-1
;
; note:
;            if quick or get_time are set, further use of getprofile_raw
;            will fail, so they must be used only for informational purpose!
;

compile_opt strictarr, strictarrsubs

if (n_elements(filename) NE 1) then filename = '' else filename += ': '

res = 0.0D
nshots = 0
nprof = 0
prf = 0.0D
nsign    = intarr(2)
pct_gain = dblarr(2)
ad_gain  = dblarr(2,2)
ad_offs  = dblarr(2,2)
wrpos = 0UL

l = 0
done = 0
repeat begin
	readheader, inp, name, val
	if (name EQ 'version') then begin
		ver=val
	endif else if (name EQ 'headersize') then begin
		hsiz = fix(val)
		done = 1
	endif
	++l
endrep until (done)

vv = strsplit(ver, '.', count=vi, /extract)
if (vi NE 3) then message2, '*** ' + filename $
	+ 'Unknown RAW data version: ' + ver + ' ?!? ***'
dataver = fix(vv[1])

section = -1
while (l LT hsiz) do begin
	readheader, inp, name, val
	case name of
		'numberofshot' :           nshots = fix(val)
		'nbofprofilesperfile' :    nprof = fix(val)
		'prf (hz)' :               prf = double(val)
		'rawresolution (m)' :      res = double(val)
		'writingposition (byte)' : wrpos = ulong(val)
		'[infoblindref]' :         section = 0
		'[inforaw]' :              section = 1
		'gain0' :                  ad_gain[section,0] = double(val)
		'gain1' :                  ad_gain[section,1] = double(val)
		'offset0' :                ad_offs[section,0] = double(val)
		'offset1' :                ad_offs[section,1] = double(val)
		'numberofsignal' :         nsign[section] = fix(val)
		'gainpct' :                begin
		                             pct_gain[0] = double(val)
		                             pct_gain[1] = pct_gain[0]
		                           end
		else :
	endcase
	++l
endwhile

if (nprof LE 0)   then message2, '*** ' + filename + 'Empty lidar file ?!?'
if (nshots LE 0)  then $
	message2, '*** ' + filename + 'Unexpected NumberOfShot ?!? ***'
if (res NE 1.5D)  then $
	message2, '*** ' + filename + 'Unexpected RawResolution ?!? ***'
if (prf NE 20.0D) then message2, '*** ' + filename + 'Unexpected PRF ?!? ***'
if (dataver GE 12) then begin
	if (wrpos EQ 0UL) then $
		message2, '*** ' + filename + 'No Writing Position ?!? ***'
	point_lun, inp, wrpos
endif

it = nshots / prf

dims  = read_binary(inp, data_type=13, data_dims=2, endian='big')
if (dims[0] NE 2UL) then $
	message2, '*** ' + filename + 'Invalid array dimension ?!? ***'
cnt  = dims[1]

if keyword_set(quick) then return

blraw = read_binary(inp, data_type=3, data_dims=[dims[1],dims[0]], endian='big')

blind = dblarr(2, cnt)
for i=0,1 do begin
	blind[i,*] = blraw[*,i] * ad_gain[0,i] / nsign[0] + ad_offs[0,i]
endfor

if keyword_set(get_time) then begin
	t = string(read_binary(inp, data_type=1, data_dims=8))
	nn = fix(strsplit(t, '-', count=nt, /extract))
	if (nt NE 3) then message2, '*** ' + filename + 'Invalid time ?!? ***'
	hh  = nn[0]
	min = nn[1]
	ss  = nn[2]
	start = hh*3600UL + min*60UL + ss
	stop  = start + ulong(ceil(it * nprof)) - 1UL
endif

end
