pro lid_cleanup


@lid_settings.include


if (n_elements(assc) EQ 1 && assc NE _undef_) then begin
	free_lun, assc
	assc = _undef_
endif


end
