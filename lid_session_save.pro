pro lid_session_save

; only want to save the __lid common block, so do not create
; any variables before the save command, do not use parameters
; or keywords, and do not call lid_settings.include


common __lid


; sessionsave and assocsave kept in SAV file for use by lid_session_restore
sessionsave = outfln + '_session.sav'
if (use_assoc && n_elements(assc) EQ 1 && assc GE 0) then $
	assocsave = outfln + '_session.assoc'


save, /variables, filename = sessionsave


@lid_settings.include


openw, lgf, logfln, /get_lun, /append
printf, lgf, '--> LID_SESSION_SAVE'

info_str = 'Session saved to ' + sessionsave
printf, lgf, info_str
message, info_str, /continue

if (n_elements(assocsave) EQ 1) then begin
	file_copy, assocfln, assocsave
	info_str = 'Assoc saved to ' + assocsave
	printf, lgf, info_str
	message, info_str, /continue
endif

free_lun, lgf


end

