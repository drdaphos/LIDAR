pro lid_ratio_save, force=force, verbose=verbose


@lid_settings.include

openw, lgf, logfln, /get_lun, /append
printf, lgf, '--> LID_RATIO_SAVE'


digi = where(profinfo.aerok AND profinfo.aerosol $
	AND profinfo.inv_type EQ _digi_, n_digi)

if (n_digi LE 0) then message, 'No Digi data. ' $
	+ 'lid_data_process, /digirolamo must be called first.'
if (n_digi LE 1 && ~keyword_set(force)) then begin
	info_str = 'Few Digi data. Skipping.'
	printf, lgf, info_str
	free_lun, lgf
	message, info_str, /continue
	return
endif

avglr = mean(profinfo[digi].d_lidratio)
stdlr = stddev(profinfo[digi].d_lidratio)
medlr = median([profinfo[digi].d_lidratio])

digiresult = {flno:flno_sub, date:string(dd, mth, yy, format='(%"%d-%d-%d")'), $
	target_it:target_it, avglr:avglr, stdlr:stdlr, medlr:medlr, $
	n_samples:n_digi, profnum:digi, time:profinfo[digi].time, $
	aod:profinfo[digi].d_aod, lr:profinfo[digi].d_lidratio}

sav_fln = string(format='(%"%s_it%03ds_lr.sav")', outfln, target_it)
save, description=globaltitle, filename=sav_fln, digiresult, $
	verbose=(keyword_set(verbose) && verbose GE 2)


info_str = 'Digi Lidar Ratios saved in ' + file_basename(sav_fln)
printf, lgf, info_str
if (keyword_set(verbose)) then print, info_str

free_lun, lgf

end
