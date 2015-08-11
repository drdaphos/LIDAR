pro lid_aerdepol, pinfo, prof, aerdep=aerdep

@lid_settings.include

; Freudenthaler et al, Tellus 61B, 165 (2009)


if (~pinfo.totdep || ~pinfo.aerosol) then $
	message, 'Depolarization and/or aerosol backscattering undefined'

dm1 = 1.0D + mol_dr
amr = prof.beta / prof.mol_beta
num = dm1 * amr * prof.totdepol + prof.totdepol - mol_dr
den = dm1 * amr - prof.totdepol + mol_dr
aerdep = num / den
min_amr = min_aerdep_br - 1.0D
idx = where(amr LT min_amr, cnt)
if (cnt GT 0) then aerdep[idx] = _dundef_

end
