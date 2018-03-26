PRO create_geoid_input,fname

;Create input data from FAAM CORE file for input to
;intpt.f and save data for create_geoid_output.pro
;S. J. Abel
;30th April 2012
 
;fname = FAAM core file name 
 
 cd ,current=dir_c
 out_file = dir_c+'/tmp/intpt_input.txt'  ;do not change as hard-wired into intpt.f
 sav_file = dir_c+'/tmp/tmp_data.sav'     ;do not change as hard-wired into create_geoid_output.pro

data = read_netcdf(fname)
 
 time = data.time
 z = data.alt_gin
 z_flag = data.alt_gin_flag
 z_radar = data.hgt_radr
 z_radar_flag = data.hgt_radr_flag
 lat = data.lat_gin.data
 lon = data.lon_gin.data  

 bad_data = WHERE(~FINITE(lat))
 IF bad_data(0) NE -1 THEN lat(bad_data)=data.lat_gin._fillvalue
 bad_data = WHERE(~FINITE(lon))
 IF bad_data(0) NE -1 THEN lon(bad_data)=data.lon_gin._fillvalue
 
 OPENW, unit, out_file, /Get_lun
 
  FOR i = 0, N_ELEMENTS(lat)-1 DO BEGIN
    PRINTF ,unit, lat(i), lon(i)
  ENDFOR
  
 FREE_LUN, unit

 SAVE,time,z,z_flag,z_radar,z_radar_flag,fname,filename=sav_file

END