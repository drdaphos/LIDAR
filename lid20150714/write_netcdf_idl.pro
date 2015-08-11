; copied from /home/h02/frns/netcdf/write_netcdf_idl.pro
; modified Franco Marenco, 10/2/2015: protect case for BADC-reserved words
; courtesy of Stuart Newman

; WRITE_NETCDF_IDL procedure to write variables to netCDF file - designed to be as general as possible
; Based on PV-Wave procedure write_netcdf.pro
; Coded by Stu Newman
; version 1.0   19 Apr 2005
; version 1.1   12 Jul 2005  (includes necessary HDF_TO_NC call to create true netCDF files *obsolete 29/10/07*)
; version 1.2   20 Jul 2005  (no longer an interactive procedure, takes variables from next program level down)
; version 1.3   10 Aug 2005  (minor bug fix to match attribute names)
; version 1.4   07 Feb 2006  (bug fix for situations where no attributes are written)
; version 1.5   29 Aug 2006  (check for unique dimension sizes)
; version 1.6   10 Apr 2007  (bug fix for cases where variables are named but undefined - these are ignored)
; version 2.0   29 Oct 2007  (now uses IDL wrapper scripts and NCDF_ routines)
; version 2.1   03 Jan 2007  (fix writing of string arrays to file)
;__________________________________________________________________________________________________________
; version 3.0   13 Feb 2009  (enable execution under pure IDL)
; version 3.1   15 Apr 2009  (minor bugfix for error message)

pro write_netcdf_idl, newfile

; EXPLANATORY NOTES:
;  newfile  =  string variable, name of netCDF file to be written
;
;  CRUCIALLY: At (Program Level-1) all dimensions (time, frequency) must be named DIM_*, e.g. DIM_WAVENUMBER
;           : all associated variables must be named VAR_*, e.g. VAR_RADIANCE, VAR_SCANANGLE
;           : all global attributes (like date, instrument) must be named GATT_*, e.g. GATT_DATE
;           : all variable attributes must be named VATT_{NAME}_*, e.g. VATT_RADIANCE_UNITS for VAR_RADIANCE
;           : all dimension attributes must be named DATT_{NAME}_* in the same way
;  This procedure will assume all variables with the same number of elements as a dimension are
;  referenced to that dimension (or dimensions in the case of a 2-d or 3-d array)

max_string_length = 255L    ; large enough value for any string variables

; Identify dimensions, variables and global/variable attributes
d = scope_level()   ; store program depth (in IDL $MAIN = 1, then 2, 3 etc.)
print,' ... Current IDL scope level is ' + strtrim(string(d),2) + ' ...'
print,' ... Checking for variables named DIM_*, VAR_*, GATT_*, DATT_* and VATT_* at Level ' $
        + strtrim(string(d-1),2) + ' ...'
	
; Find all variables at level of calling procedure
allarr = scope_varname(Level = -1)

; Only keep named variables that are not 'UNDEFINED'
nallarr = n_elements(allarr)
index_defined = lonarr(nallarr)
for i=0L, nallarr-1L do begin
   index_defined(i) = (size(scope_varfetch(allarr(i),Level = -1)))(0) + $
                      (size(scope_varfetch(allarr(i),Level = -1)))(1)
endfor
allarr = allarr(where(index_defined))


; Find matching variables for each data class
dim_match = where(strmatch(allarr, 'DIM_*', /fold_case), ndim)
if ndim gt 0 then dimarr = allarr(dim_match)

vari_match = where(strmatch(allarr, 'VAR_*', /fold_case), nvar)
if nvar gt 0 then vararr = allarr(vari_match)

gatt_match = where(strmatch(allarr, 'GATT_*', /fold_case), ngatt)
if ngatt gt 0 then gattarr = allarr(gatt_match)

vatt_match = where(strmatch(allarr, 'VATT_*', /fold_case), nvatt)
if nvatt gt 0 then vattarr = allarr(vatt_match)

datt_match = where(strmatch(allarr, 'DATT_*', /fold_case), ndatt)
if ndatt gt 0 then dattarr = allarr(datt_match)

if (ndim eq 0 or nvar eq 0) then begin
   print,' *** ERROR: check that dimensions and variables exist at Level ' + strtrim(d-1,2) + ' *** '
   stop
endif


; SCOPE_VARFETCH: can now remove leading name extensions dim_, var_, gatt_, vatt_ and datt_
; and transfer variables lower down (Level=d-1) to corresponding ones in this procedure (Level=d)

for i=0L, ndim-1L do begin
   status = execute(strmid(dimarr(i),4,100) + ' = scope_varfetch(dimarr(i), Level=-1)')
   dimarr(i) = strmid(dimarr(i),4,100)
endfor

for i=0L, nvar-1L do begin
   status = execute(strmid(vararr(i),4,100) + ' = scope_varfetch(vararr(i), Level=-1)')
   vararr(i) = strmid(vararr(i),4,100)
endfor

for i=0L, ngatt-1L do begin
   status = execute(strmid(gattarr(i),5,100) + ' = scope_varfetch(gattarr(i), Level=-1)')
   gattarr(i) = strmid(gattarr(i),5,100)
endfor

for i=0L, nvatt-1L do begin
   status = execute(strmid(vattarr(i),5,100) + ' = scope_varfetch(vattarr(i), Level=-1)')
   vattarr(i) = strmid(vattarr(i),5,100)
endfor

for i=0L, ndatt-1L do begin
   status = execute(strmid(dattarr(i),5,100) + ' = scope_varfetch(dattarr(i), Level=-1)')
   dattarr(i) = strmid(dattarr(i),5,100)
endfor

; dimensions should also be output as variables in netCDF file, similarly for dimension attributes
vararr  = [dimarr, vararr]    &  nvar  = n_elements(vararr)
if ndatt gt 0 then begin
   vattarr = [dattarr, vattarr]
   nvatt = n_elements(vattarr)
endif
ndim = n_elements(dimarr)  ; recompute
ndatt = n_elements(dattarr)
ngatt = n_elements(gattarr)

;------- CREATE netCDF FILE -------

ncid = ncdf_create(newfile, /CLOBBER)           ; create, overwrite
ncdf_close, ncid                                ; close netCDF file

ncid = ncdf_open(newfile, /WRITE)               ; ncid is file ID, open for writing
ncdf_control, ncid, /REDEF                      ; enter define mode (for dimensions, variables, attributes)

;------- DEFINE DIMENSIONS -------

dimsize = lonarr(ndim)    ; dimension array size
for i=0L, ndim-1L do status = execute('dimsize(i) = n_elements(' + dimarr(i) + ')')
dimid = lonarr(ndim)      ; netCDF dimension ID
for i=0L, ndim-1L do dimid(i) = ncdf_dimdef(ncid, dimarr(i), dimsize(i))

;------- DEFINE VARIABLES -------

; Organise variables by their dimensions
; SIZE command returns no. dimensions; sizes of each (if any); data type; total no. elements
vardims = lonarr(nvar)      ; number of dimensions per variable
for i=0L, nvar-1L do status = execute('vardims(i) = (size(' + vararr(i) + '))(0)')

; For each variable dimension define array size
vardimsizes = lonarr(nvar, max(vardims)+1)
; (make vardimsizes large enough to store maximum number of dimensions, +1 is for possible string dimension)
for i=0L, nvar-1L do begin
   for j=0L, vardims(i)-1L do begin
      status = execute('vardimsizes(i,j) = (size(' + vararr(i) + '))(j+1)')
   endfor
endfor

; Match up array sizes with dimension names
; IMPORTANT - it is assumed that sizes are unique, i.e. all dimensions have different sizes
; In the case of an array size not matching a defined dimension this becomes the record dimension
; (having unlimited size) BUT only one dimension can be defined in this way
matchid    = lonarr(nvar, max(vardims)+1)     ; match each variable dimension with dimension ID
matchid(*) = -99                              ; initialise with tagged value (i.e. not 0)
for i=0L, nvar-1L do begin
   for j=0L, vardims(i)-1L do begin
      matchid_ij = where(dimsize eq vardimsizes(i,j), Cmatch)
      if Cmatch eq 0 then begin
         print,' *** ERROR: unmatched dimension size ***'
	 stop
      endif else if Cmatch gt 1 then begin
         print,' *** CAUTION: two dimensions have identical sizes ***'
	 stop
         matchid(i,j) = matchid_ij(0)	 
      endif else begin
         matchid(i,j) = matchid_ij
      endelse
   endfor
endfor

; If matchid includes -1 (i.e. non-matched dimension) then define the record dimension
; As default this record is simply an index (0, 1, 2, 3, ...)
recdimname = 'RECORD'
min1 = where(matchid eq -1, count)
if count gt 0 then begin
   vmin1 = vardimsizes(min1)
   recdimsize = vmin1(uniq(vmin1, sort(vmin1)))  ; equiv. to PV-Wave UNIQUE function
   if n_elements(recdimsize) gt 1 then begin
      print,' *** ERROR: more than one undefined dimension ***'
      stop
   endif
   dimarr = [dimarr, recdimname]
   ndim = n_elements(dimarr)
   vararr = [vararr, recdimname]
   nvar = n_elements(vararr)
   vardims = lonarr(nvar)
   dimsize = [dimsize, recdimsize(0)]
   recdimid = ncdf_dimdef(ncid, recdimname, recdimsize(0))
   dimid = [dimid, recdimid]
   matchid(min1) = recdimid
   status = execute(recdimname + '= indgen(recdimsize(0))')    ; index counting from zero
   for i=0L, nvar-1L do status = execute('vardims(i) = (size(' + vararr(i) + '))(0)')  ; recalculate
   vardimsizes = lonarr(nvar, max(vardims)+1)
   for i=0L, nvar-1L do for j=0L, vardims(i)-1L do status = execute('vardimsizes(i,j) = (size(' + vararr(i) + '))(j+1)')
   matchid = lonarr(nvar, max(vardims)+1)
   for i=0L, nvar-1L do for j=0L, vardims(i)-1L do matchid(i,j) = where(dimsize eq vardimsizes(i,j))  ; recalculate
endif

; Organise variables by their data types
; (0 = undefined, 1 = byte, 2 = integer, 3 = long, 4 = float, 5 = double, 6 = complex, 7 = string, ...)
;vartype = ['*UNDEFINED*', 'NC_BYTE', 'NC_SHORT', 'NC_LONG', 'NC_FLOAT', 'NC_DOUBLE', '*COMPLEX*', 'NC_CHAR']
vartype = ['*UNDEFINED*', '/BYTE', '/SHORT', '/LONG', '/FLOAT', '/DOUBLE', '*COMPLEX*', '/CHAR']
vtnum = lonarr(nvar)      ; variable type number as returned by size command
for i=0L, nvar-1L do status = execute('vtnum(i) = (size(' + vararr(i) + '))(vardims(i)+1)')

; If string variables are present then a character-position dimension must be specified as the 
; fastest changing dimension, since strings can only be represented as an array of characters 
strindex = where(vtnum eq 7)                                              ; string variables, if any
if strindex(0) ne -1 then nsvar = n_elements(strindex) else nsvar = 0     ; number of string variables
strdimname = 'CHARPOS'
if nsvar ge 1 then begin
   strdimid = ncdf_dimdef(ncid, strdimname, max_string_length)
   vardims(strindex) = vardims(strindex) + 1
endif

for i=0, nsvar-1 do begin
   ; change first dimension so it is the character position
   matchid(strindex(i),1:vardims(strindex(i))-1) = matchid(strindex(i),0:vardims(strindex(i))-2)
   matchid(strindex(i),0) = strdimid
   ; likewise for sizes array
   vardimsizes(strindex(i),1:vardims(strindex(i))-1) = vardimsizes(strindex(i),0:vardims(strindex(i))-2)
   vardimsizes(strindex(i),0) = max_string_length
endfor

; Define netCDF variable IDs
varid = lonarr(nvar)        

for i=0L, nvar-1L do begin
   if (vtnum(i) eq 0 or vtnum(i) gt 7) then begin
      print,' *** ERROR: ', vararr(i), ' is undefined or of unknown type ***'
      stop
   endif else if vtnum(i) eq 6 then begin
      print,' *** ERROR: ', vararr(i), ' is COMPLEX, cannot define in netCDF ***'
      stop
   endif else begin
      status = execute('varid(i) = ncdf_vardef(ncid, vararr(i), reform(matchid(i,0:vardims(i)-1)), ' $
                       + vartype(vtnum(i)) + ')')
    endelse
endfor

;------- DEFINE GLOBAL ATTRIBUTES -------

; Note that this is essentially repeated in variable attributes section that follows

if ngatt gt 0 then begin
   gattdims = lonarr(ngatt)       ; number of dimensions per global attribute
   gatnum = lonarr(ngatt)         ; attribute type number as returned by size command
endif

; Write global attributes to file
print,' ... Writing global attributes to netCDF file ...'
for i=0L, ngatt-1L do begin
   status = execute('gattdims(i) = (size(' + gattarr(i) + '))(0)')
   status = execute('gatnum(i) = (size(' + gattarr(i) + '))(gattdims(i)+1)')
   if (gatnum(i) eq 0 or gatnum(i) gt 7) then begin
      print,' *** ERROR: ', gattarr(i), ' is undefined or of unknown type ***'
      stop
   endif else if gatnum(i) eq 6 then begin
      print,' *** ERROR: ', gattarr(i), ' is COMPLEX, cannot define in netCDF ***'
      stop
   endif else if gatnum(i) eq 7 then begin   ; (string)
      status = execute('ncdf_attput, ncid, gattarr(i), ' $
      + gattarr(i) + ' + " ", ' + vartype(gatnum(i)) + ', /GLOBAL')
   endif else begin
      status = execute('ncdf_attput, ncid, gattarr(i), ' $
      + gattarr(i) + ', ' + vartype(gatnum(i)) + ', /GLOBAL')
   endelse
endfor

;------- DEFINE VARIABLE ATTRIBUTES -------

nvatts = lonarr(nvar)       ; number of attributes per variable
; match up attributes with variables
dscope = scope_varname(Level = d)
;;;;;;;;;;;;;;;;
; added by FM
; protection of case, for reserved BADC words
dscope2 = dscope
nscope = n_elements(dscope2)
scopelen = intarr(nscope)
for i=0, nscope-1 do scopelen[i] = strlen(dscope2[i])
protected  = ['_FillValue', 'standard_name', 'long_name', $
	'units', 'scale_factor', 'add_offset'] 
nprotected = n_elements(protected)
protlen    = intarr(nprotected)
for j=0, nprotected-1 do protlen[j] = strlen(protected[j])

for i=0, nscope-1 do begin
	for j=0, nprotected-1 do begin
		nam = strmid(dscope2[i], protlen[j]-1, $
			protlen[j], /reverse_offset)
		if (strlowcase(nam) EQ strlowcase(protected[j])) then begin
			tmp = dscope2[i]
			strput, tmp, protected[j], scopelen[i]-protlen[j]
			dscope2[i] = tmp
		endif
	endfor
endfor
dscope = dscope2
;;;;;;;;;;;;;;;;

for i=0L, nvar-1L do begin
   nvatts_match = where(strmatch(dscope, vararr(i) + '_*', /fold_case), nvatts_temp)
   nvatts(i) = nvatts_temp
endfor
maxnvatts = max(nvatts)
vattnames = strarr(nvar, maxnvatts)    ; make big enough to cater for all cases
vattshort = strarr(nvar, maxnvatts)    ; shortened version of attribute name
for i=0L, nvar-1L do begin
   for j=0L, nvatts(i)-1L do begin
      vattnames(i,j) = (dscope(where(strmatch(dscope, vararr(i) + '_*', /fold_case))))(j)
      vattshort(i,j) = strmid(vattnames(i,j),strlen(vararr(i))+1,100)  ; remove leading {VAR}_ extension
   endfor
   if vattnames(i,0) eq '' then nvatts(i) = 0            ; account for NULL strings
endfor

vattdims = lonarr(nvar, maxnvatts)       ; number of dimensions per variable attribute
vatnum = lonarr(nvar, maxnvatts)         ; attribute type number as returned by size command

; Write variable attributes to file
print,' ... Writing variable attributes to netCDF file ...'
for i=0L, nvar-1L do begin
   for j=0L, nvatts(i)-1L do begin
      status = execute('vattdims(i,j) = (size(' + vattnames(i,j) + '))(0)')
      status = execute('vatnum(i,j) = (size(' + vattnames(i,j) + '))(vattdims(i,j)+1)')
      if (vatnum(i,j) eq 0 or vatnum(i,j) gt 7) then begin
         print,' *** ERROR: ', vattnames(i,j), ' is undefined or of unknown type ***'
         stop
      endif else if vatnum(i,j) eq 6 then begin
         print,' *** ERROR: ', vattnames(i,j), ' is COMPLEX, cannot define in netCDF ***'
         stop
      endif else if vatnum(i,j) eq 7 then begin   ; (string)
         status = execute('ncdf_attput, ncid, i, vattshort(i,j), ' $
         + vattnames(i,j) + ' 	+ " ", ' + vartype(vatnum(i,j)))
      endif else begin
         status = execute('ncdf_attput, ncid, i, vattshort(i,j), ' $
         + vattnames(i,j) + ', ' + vartype(vatnum(i,j)))
      endelse
   endfor
endfor


;------- WRITE VARIABLES -------

; leave define mode, return to data mode
ncdf_control, ncid, /ENDEF

print,' ... Writing variables to netCDF file ...'
for i=0L, nvar-1L do begin
   if (vtnum(i) ne 0 and vtnum(i) ne 6 and vtnum(i) le 7) then begin    ; filter for valid variable types
      if (vtnum(i) eq 7) then begin   ; (string)
         status = execute('ncdf_varput, ncid, varid(i), byte(' + vararr(i) +')')
      endif else begin
         status = execute('ncdf_varput, ncid, varid(i), ' + vararr(i) )
      endelse
   endif else begin
      print,' *** CAUTION: ', vararr(i), ' is undefined or of disallowed type ***'
   endelse
endfor

;status = ncsync(ncid)      ; synchronise file (disk copy made current)
ncdf_close, ncid           ; close netCDF file

print,''

end
