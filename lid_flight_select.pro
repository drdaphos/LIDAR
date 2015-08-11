pro lid_flight_select, flight, verbose=verbose

@lid_settings.include

flight2 = strupcase(flight)
line = ''
flno = ''
flno_core = ''
found = 0

fln = info_path + fltable
openr, inp, fln, /get_lun

while (~eof(inp) && ~found) do begin
	readf, inp, line
	string = strsplit(line, count=cnt, /extract)
	flno = string[0]
	found = (flight2 EQ strupcase(flno))
endwhile

free_lun, inp

if (~found)   then message, 'Flight not found'
if (cnt LT 6) then message, 'Incomplete information'

dd      = fix(string[1])
mth     = fix(string[2])
yy      = fix(string[3])
takeoff = double(secs(long(string[4])))
landing = double(secs(long(string[5])))

flno_sub  = flno
instrument = '146'
platform   = 'Faam'
orogfln    = ''
gnd_lat       = default_gnd_lat
gnd_lon       = default_gnd_lon
gnd_alt       = default_gnd_alt
gnd_offzenith = default_gnd_offzenith
gnd_based  = 0
swap_chan  = 0
view       = _undef_


; note: flno (set for 'really') indicates path to lidar RAW files
;       flno_core (set for 'core') indicates flight number in core filename
;       flno_sub (as set in procedure call) is used to make output filename
for i=6, cnt-1 do begin
	word = strsplit(string[i], ':', count=nwords, /extract)
	keyword = strlowcase(word[0])
	case keyword of
		'lidar':	if (nwords EQ 2) then begin
					instrument = word[1]
				endif else goto, err_words

		'platform':	if (nwords EQ 2) then begin
					platform = word[1]
				endif else goto, err_words

		'orog':		if (nwords EQ 2) then begin
					orogfln = word[1] + '.sav'
				endif else goto, err_words

		'view':		if (nwords EQ 2 && $
				   strlowcase(word[1]) EQ 'nadir') then begin
					view = _nadir_
				endif else if (nwords EQ 2 && $
				   strlowcase(word[1]) EQ 'zenith') then begin
					view = _zenith_
				endif else goto, err_words

		'swap':		if (nwords EQ 1) then begin
					swap_chan = 1
				endif else goto, err_words

		'really':	if (nwords EQ 2) then begin
					flno = strupcase(word[1])
				endif else goto, err_words

		'core':		if (nwords EQ 2) then begin
					flno_core = strupcase(word[1])
				endif else goto, err_words

		'pos':		if (nwords EQ 4) then begin
					gnd_lat = double(word[1])
					gnd_lon = double(word[2])
					gnd_alt = double(word[3])
				endif else goto, err_words

		'offzenith':	if (nwords EQ 2) then begin
					gnd_offzenith = double(word[1])
				endif else goto, err_words
	endcase
endfor

instrument = uplowcase(instrument)
platform   = uplowcase(platform)
horc_path = horc_path0 + platform + '/'
if (platform EQ 'Gnd' || platform EQ 'Ground-based') then begin
	gnd_based = 1
	platform = 'Ground-based'
endif
if (view EQ _undef_ && gnd_based) then view = _zenith_ $
	else if (view EQ _undef_) then view = default_view

if (flno_core EQ '') then flno_core = flno

shortfln   = string(format='(%"%d-%02d-%02d_%s")', yy, mth, dd, flno_sub)
lidar_path = string(format='(%"%s/%d-%02d-%02d_%s/")', $
	raw_path, yy, mth, dd, flno)
outfln     = string(format='(%"%s/%s/%s")', out_path, shortfln, shortfln)
file_mkdir,  string(format='(%"%s/%s")', out_path, shortfln)


info_str = string(format='(%"Flight:  %s   %02d-%02d-%04d   %s - %s' $
	+ '   %s view")', flno_sub, dd, mth, yy, hhmmss(takeoff), $
	hhmmss(landing), view EQ _nadir_ ? 'Nadir' : 'Zenith')

logfln    = outfln + '.log'
openw, lgf, logfln, /get_lun
printf, lgf, '--> LID_FLIGHT_SELECT'
printf, lgf, info_str
free_lun, lgf

infofln   = outfln + '.info'
openw, info, infofln, /get_lun
printf, info, info_str
free_lun, info

assocfln = tmpdir + shortfln + '.assoc'

if (keyword_set(verbose)) then print, info_str

; the following are needed to track the correct routine call sequence

nfiles      = 0
maxprofiles = 0L
nprofiles   = 0L
lid_cleanup

return


err_words:
	message, 'Incorrect number of words or invalid option ' $
		+ 'for keyword ''' + keyword + '''.'


end

