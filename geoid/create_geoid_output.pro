PRO create_geoid_output,fname_out
 
;Read in geoid corrected data created from intpt.f 
;and outpu corrected GPS altitude data to a NetCDF file
;S. J. Abel
;30th April 2012
 
;fname_out = Output NetCDF file containing corrected GPS altitude data 
 
 cd ,current=dir_c
 intpt_file = dir_c+'/tmp/intpt_output.txt'   ;do not change as hard-wired into intpt.f
 sav_file = dir_c+'/tmp/tmp_data.sav'         ;do not change as hard-wired into create_geoid_input.pro

 data = READ_ASCII(intpt_file)
 z_corr = data.field1
 
 restore,sav_file
 
 z_ = z.data-z_corr
 ind = WHERE(z.data EQ z._fillvalue)
 IF ind(0) NE -1 THEN z_(ind) = z._fillvalue

 ind = WHERE(z_ LT 0.)
 IF ind(0) NE -1 THEN z_(ind) = 0.

 id = NCDF_CREATE(fname_out, /CLOBBER) 
 
 ; Fill the file with default values:
 NCDF_CONTROL, id, /FILL 
 
 NCDF_ATTPUT, id, /GLOBAL, 'Title', 'GPS altitude data corrected for geoid'
 NCDF_ATTPUT, id, /GLOBAL, 'Data_contact', 'Steven Abel (steven.abel@metoffice.gov.uk)'
 NCDF_ATTPUT, id, /GLOBAL, 'Institution', 'Met Office, UK'
 NCDF_ATTPUT, id, /GLOBAL, 'FAAM_core_file', fname 
 NCDF_ATTPUT, id, /GLOBAL, 'History', 'V01'
 NCDF_ATTPUT, id, /GLOBAL, 'GEOID', 'WW15MGH.GRD'
 NCDF_ATTPUT, id, /GLOBAL, 'Comment', 'Calculated using faam_gps_geoid_correction.scr'
 
 nt = NCDF_DIMDEF(id, 'nt', n_elements(z_))
 
 tid = NCDF_VARDEF(id, 'TIME', [nt], /float)
 NCDF_ATTPUT, id, tid, 'long_name', time.long_name
 NCDF_ATTPUT, id, tid, 'units', time.units 
 NCDF_ATTPUT, id, tid, '_fillvalue', time._fillvalue 
 NCDF_ATTPUT, id, tid, 'standard_name', time.standard_name

 zid = NCDF_VARDEF(id, 'ALT_GIN', [nt], /float)
 NCDF_ATTPUT, id, zid, 'long_name', z.long_name
 NCDF_ATTPUT, id, zid, 'units', z.units 
 NCDF_ATTPUT, id, zid, '_fillvalue', z._fillvalue 
 NCDF_ATTPUT, id, zid, 'frequency', z.frequency
 NCDF_ATTPUT, id, zid, 'number', z.number 
 NCDF_ATTPUT, id, zid, 'standard_name', z.standard_name ,/CHAR

 zfid = NCDF_VARDEF(id, 'ALT_GIN_FLAG', [nt], /byte)
 NCDF_ATTPUT, id, zfid, 'long_name', z_flag.long_name
 IF tag_exist(z_flag,'units') THEN BEGIN
   NCDF_ATTPUT, id, zfid, 'units', z_flag.units
 ENDIF ELSE BEGIN
   NCDF_ATTPUT, id, zfid, 'units', ' '
 ENDELSE
 NCDF_ATTPUT, id, zfid, '_fillvalue', z_flag._fillvalue 
 NCDF_ATTPUT, id, zfid, 'frequency', z_flag.frequency

 zrid = NCDF_VARDEF(id, 'HGT_RADR', [nt], /float)
 NCDF_ATTPUT, id, zrid, 'long_name', z_radar.long_name
 NCDF_ATTPUT, id, zrid, 'units', z_radar.units 
 NCDF_ATTPUT, id, zrid, '_fillvalue', z_radar._fillvalue 
 NCDF_ATTPUT, id, zrid, 'frequency', z_radar.frequency
 NCDF_ATTPUT, id, zrid, 'number', z_radar.number 
 NCDF_ATTPUT, id, zrid, 'standard_name', z_radar.standard_name ,/CHAR
 
 zrfid = NCDF_VARDEF(id, 'HGT_RADR_FLAG', [nt], /byte)
 NCDF_ATTPUT, id, zrfid, 'long_name', z_radar_flag.long_name
 IF tag_exist(z_radar_flag,'units') THEN BEGIN
   NCDF_ATTPUT, id, zrfid, 'units', z_radar_flag.units
 ENDIF ELSE BEGIN
   NCDF_ATTPUT, id, zrfid, 'units', ' '
 ENDELSE
 NCDF_ATTPUT, id, zrfid, '_fillvalue', z_radar_flag._fillvalue 
 NCDF_ATTPUT, id, zrfid, 'frequency', z_radar_flag.frequency 
 
 zcid = NCDF_VARDEF(id, 'ALT_GINC', [nt], /float)
 NCDF_ATTPUT, id, zcid, 'long_name', STRCOMPRESS(z.long_name+' with geoid correction applied')
 NCDF_ATTPUT, id, zcid, 'units', z.units 
 NCDF_ATTPUT, id, zcid, '_fillvalue', z._fillvalue 
 NCDF_ATTPUT, id, zcid, 'frequency', z.frequency 
 NCDF_ATTPUT, id, zcid, 'standard_name', z.standard_name ,/CHAR
 
 zcfid = NCDF_VARDEF(id, 'ALT_GINC_FLAG', [nt], /byte)
 NCDF_ATTPUT, id, zcfid, 'long_name', STRCOMPRESS(z_flag.long_name+' with geoid correction applied')
 IF tag_exist(z_flag,'units') THEN BEGIN
   NCDF_ATTPUT, id, zcfid, 'units', z_flag.units
 ENDIF ELSE BEGIN
   NCDF_ATTPUT, id, zcfid, 'units', ' '
 ENDELSE
 NCDF_ATTPUT, id, zcfid, '_fillvalue', z_flag._fillvalue 
 NCDF_ATTPUT, id, zcfid, 'frequency', z_flag.frequency
 
 ; Put file in data mode:
 NCDF_CONTROL, id, /ENDEF
 
 NCDF_VARPUT, id, tid, time.data
 NCDF_VARPUT, id, zid, z.data
 NCDF_VARPUT, id, zfid, z_flag.data
 NCDF_VARPUT, id, zrid, z_radar.data
 NCDF_VARPUT, id, zrfid, z_radar_flag.data
 NCDF_VARPUT, id, zcid, z_
 NCDF_VARPUT, id, zcfid, z_flag.data

 NCDF_CLOSE, id ; Close the NetCDF file.

END