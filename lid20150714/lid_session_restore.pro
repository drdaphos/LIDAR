pro lid_session_restore, filename

; assocsave is used just to check that there had been one
; when session was saved, but the assoc file will actually
; be restored from the same filename (just different extension)
; this permits renaming and moving the files around


@lid_settings.include


restore, filename


openw, lgf, logfln, /get_lun, /append
printf, lgf, '--> LID_SESSION_RESTORE'

info_str = 'Session restored from ' + filename
printf, lgf, info_str
message, info_str, /continue

if (n_elements(assocsave) EQ 1) then begin
	dotpos = strpos(filename, '.', /reverse_search)
	assocsave2 = strmid(filename, 0, dotpos) + '.assoc'
	file_copy, assocsave2, assocfln
	openu, assc, assocfln, /delete
	info_str = 'Assoc restored from ' + assocsave2
	printf, lgf, info_str
	message, info_str, /continue
endif


free_lun, lgf


end

