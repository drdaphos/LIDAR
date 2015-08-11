pro exclude_data, exclude=idx, n_exclude=cnt

; will set to undefined the gridded data in exclusion zones
; and will also set aerok to 0 to prevent processing
;
; this routine should we played twice: in lid_init, just after gridding data
; and in lid_process, before any processing is done


@lid_settings.include


lat = profinfo.lat
lon = profinfo.lon
cnt = 0
idx = -1

; exclude Western Sahara data in Fennec

if ((yy EQ 2011 || yy EQ 2012) && mth EQ 6) then begin
	mask1 = intarr(nprofiles)
	idx1 = where(lat LE 27.7 AND lat GE 21.35 $
		AND lon GE (0.5984 * lat - 29.976) $
		AND lon LE -8., cnt1)
	if (cnt1 GT 0) then begin
		mask1[idx1] = 1
		idx = where(mask1 AND ((lat LE 22.8 AND lon LE -13.) $
			OR (lat GE 22.8 AND lat LE 23.45 $
			AND lon LE 1.5385 * lat - 48.077) $
			OR (lat GE 23.45 AND lat LE 26 AND lon LE -12.) $
			OR (lat GE 26. AND lon LE -8.65)), cnt)
	endif
endif


; undefine data in selected profiles, and prevent its processing

if (cnt GT 0) then begin
	lid_pr2[idx, *, *] = _dundef_
	lid_reldep[idx, *] = _dundef_
	profinfo[idx].aerok = 0

	info_str = string(format='(%"%d profiles excluded from dataset.")',cnt)
	message, info_str, /continue
	openw, lgf, logfln, /get_lun, /append
	printf, lgf, '--> EXCLUDE_DATA'
	printf, lgf, info_str
	free_lun, lgf
endif


end
