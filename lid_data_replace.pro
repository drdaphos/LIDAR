pro lid_data_replace, prof=prof, pinfo=pinfo0, append=append


@lid_settings.include



openw, lgf, logfln, /get_lun, /append
printf, lgf, '--> LID_DATA_REPLACE'

openw, info, infofln, /get_lun, /append
printf, info, ''

if (n_elements(flno) NE 1 || n_elements(hor) LE 0) then $
	message, 'lid_flight_select and lid_horace_read must be called first.'

append = keyword_set(append)
pinfo = pinfo0

nprofs = n_elements(prof)
ninfo  = n_elements(pinfo)

if (ninfo EQ 1) then begin
	pinfo = replicate(pinfo, nprofs)
endif else if (ninfo NE nprofs) then begin
	message, 'Pinfo and Profs must have the same number of elements'
endif


if (append) then begin
	info_str = 'Appending profiles at the end.'
	profinfo = [profinfo, pinfo]
	if (keyword_set(use_assoc)) then begin
		for k=0, nprofs-1 do profile[k + nprofiles] = prof[k]
	endif else begin
		profile = [profile, prof]
	endelse
	nprofiles += nprofs
	apptext = 'app'
endif else begin
	lid_cleanup
	if (keyword_set(use_assoc)) then begin
		openw, assc, assocfln, /get_lun
		profile = assoc(assc, prof[0])
		for k=0, nprofs-1 do profile[k] = prof[k]
		info_str = string(format='(%"Using assoc file %s")', assocfln)
	endif else begin
		profile = prof
		info_str = 'Keeping profile array in memory'
	endelse
	profinfo = pinfo
	nprofiles = nprofs
	apptext = 'repl'
endelse

printf, lgf, info_str

maxaltitudes = n_elements(prof[0].range)
flno_sub += apptext
shortfln += apptext
outfln   += apptext
globaltitle = string(format='(%"%s %d-%d-%d %s-%s %dpr")', $
	flno_sub, dd, mth, yy, hhmmss(min(pinfo.start)), $
	hhmmss(max(pinfo.stop)), nprofiles)
printf, lgf, globaltitle
printf, info, 'lid_data_replace: ', globaltitle
if (keyword_set(verbose)) then print, globaltitle


dsize = size_double
prof_size = (7 + 3 * nchannels) * maxaltitudes * dsize

if (keyword_set(use_assoc) && ~append) then begin
	free_lun, assc
	assc_size = double(prof_size) * nprofiles
	info_str = string(assc_size, assc_size / (1024L*1024L), $
		format='(%"Calculated Assoc file size: %d bytes - %6.1f MB")')
	printf, lgf, info_str
	if (!version.os_family EQ 'unix') then begin
		cmd = du_ux + ' ' + assocfln
	endif else begin
		cmd = du_win + ' ' + assocfln
	endelse
	spawn, cmd, info_str
	printf, lgf, '> ', info_str
	openu, assc, assocfln, /get_lun, /delete
	info_str = string(format='(%"Assoc file unit: %d (%s)")',assc,assocfln)
	printf, lgf, info_str 
endif


free_lun, info
free_lun, lgf


end
