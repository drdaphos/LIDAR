PRO create_geoid_input_aimms,fname,fname_core

;Create input data from AIMMS file for input to
;intpt.f and save data for create_geoid_output.pro
;S. J. Abel
;30th April 2012
 
;fname = FAAM core file name 
 
 cd ,current=dir_c
 out_file = dir_c+'/tmp/intpt_input.txt'  ;do not change as hard-wired into intpt.f
 sav_file = dir_c+'/tmp/tmp_data.sav'     ;do not change as hard-wired into create_geoid_output.pro

data = read_netcdf(fname)
core = read_netcdf(fname_core)

IF n_elements(data.time.data) NE n_elements(core.time.data) THEN STOP
IF data.time.data[0] NE core.time.data[0] THEN STOP

 time = data.time
 z = data.alt
 z_flag = REPLICATE(0,n_elements(z.data));no flag in AIMMS file so set to 0
 ii = WHERE(z.data EQ z._fillvalue)
 IF ii[0] NE -1 THEN z_flag[ii]=1
 z_radar = core.hgt_radr
 z_radar_flag = core.hgt_radr_flag
 lat = data.lat.data
 lon = data.lon.data  

 bad_data = WHERE(~FINITE(lat))
 IF bad_data(0) NE -1 THEN lat(bad_data)=!VALUES.F_NAN
 bad_data = WHERE(~FINITE(lon))
 IF bad_data(0) NE -1 THEN lon(bad_data)=!VALUES.F_NAN

 OPENW, unit, out_file, /Get_lun
 
  FOR i = 0, N_ELEMENTS(lat)-1 DO BEGIN
    PRINTF ,unit, lat(i), lon(i)
  ENDFOR
  
 FREE_LUN, unit

 SAVE,time,z,z_flag,z_radar,z_radar_flag,fname,fname_core,filename=sav_file

END