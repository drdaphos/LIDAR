; copied from /home/fp0100/tardis/tardis/mrf_idl/faamvariable__define.pro
;
; Object definition of a faam style variable in a netcdf file with
; a data part and a flag part.
;
function faamvariable::init,nc,varname=varname,varid=varid, $
              new=new,frequency=frequency,long_name=long_name, $
	      units=units,number=number,flag=flag,noflag=noflag, $
	      type=type,fillvalue=fillvalue,standard_name=standard_name, $
	      short_name=short_name

self.time=0
if(keyword_set(new)) then begin
  if(n_elements(long_name) eq 0)then long_name=varname	
  nc->get,dimensions=ds
  if(n_elements(frequency) eq 0)then begin
    if(size(ds,/TNAME) ne 'STRUCT') then begin
      nc->adddimension,'data_point',0
    endif
    dims=['data_point']
  endif else begin
    d1='sps'+strtrim(string(frequency,format='(I2.2)'),2)      
    if(size(ds,/TNAME) eq 'STRUCT') then begin
      tn=tag_names(ds)
      id=where(strlowcase(tn) eq d1)
      if(id(0) eq -1) then nc->adddimension,d1,frequency  
    endif else begin
      nc->adddimension,'data_point',0
      nc->adddimension,d1,frequency
    endelse
    dims=[d1,'data_point']
  endelse
  if(n_elements(units) eq 0) then units='*'
  if(n_elements(type) eq 0) then type='FLOAT'
  if(n_elements(fillvalue) eq 0) then begin
    case type OF 
    'FLOAT':fillvalue=-9999.0
    'LONG':fillvalue=-1l
    'BYTE':fillvalue=-1b
    'SHORT':fillvalue=-1
    else:fillvalue=-1
    endcase
  endif
 IF(self->ncvariable::init(nc,varname=varname, $
      new=new,dims=dims,type=type) EQ 0) then return,0
; Minimum attributes
  self->AddAttribute,'long_name',long_name
  self->AddAttribute,'units',units
  self->AddAttribute,'_FillValue',FillValue
; Optional attributes
 if(n_elements(frequency) GT 0) then $
    self->AddAttribute,'Frequency',frequency
 IF(n_elements(number) GT 0)then  $
    self->AddAttribute,'Number',number
 IF(n_elements(short_name) GT 0)then $
    self->AddAttribute,'short_name',short_name
 IF(n_elements(standard_name) GT 0)then $
    self->AddAttribute,'standard_name',standard_name
  self.datatype="FAAM"
  if(not(keyword_set(noflag))) then begin
    flagatts=create_struct('long_name','Flag for '+long_name,'units',1, $
                          '_FillValue',-1b)
    flagattnames=['long_name','units','_FillValue']
    if(n_elements(frequency) GT 0) then $
      self->addattstruct,flagatts,flagattnames,'Frequency',frequency
    self.flag=OBJ_NEW('ncvariable',nc,varname=varname+'_FLAG', $
      new=new,dims=dims,attributes=flagatts,attnames=flagattnames,type='BYTE')
  endif 
endif else begin
  IF(self->ncvariable::init(nc,varname=varname,varid=varid) EQ 0) then return,0
  self.datatype="FAAM"
  if(n_elements(flag) eq 0) then begin
  
    f1=nc->getvar(self.name+"_FLAG")
    
    if(size(f1,/tname) ne 'OBJREF') then $
      f1=nc->getvar(self.name+"FLAG")
    if(size(f1,/tname) eq 'OBJREF') then self.flag=f1
    
  endif else begin
    self.flag=flag
  endelse
endelse
  if(strlowcase(self.name) eq 'time') then self.time=1  

return,1

end





function faamvariable::getdata,flags=flags,_EXTRA=extra, $
                     start=start,stop=stop
  if(n_elements(start) GT 0) or (n_elements(stop) GT 0) then begin
    self->get,freq=freq
    self.nc->calc_count_offset,start=start,stop=stop, $
          count=count,offset=offset,freq=freq
    val=float(self->ncvariable::getdata(count=count,offset=offset))
    if(OBJ_VALID(self.flag)) then begin
      flg=self.flag->ncvariable::getdata(count=count,offset=offset) 
    endif else begin
      if((size(val,/dim))[0] eq 0) then flg=0b else flg=bytarr(size(val,/dim))
    endelse   
  endif else begin
    val=float(self->ncvariable::getdata(_extra=extra))
    
    if(OBJ_VALID(self.flag)) then begin
      flg=self.flag->ncvariable::getdata(_extra=extra) 
    endif else begin
      if((size(val,/dim))[0] eq 0) then flg=0b else flg=bytarr(size(val,/dim))
    endelse   
  endelse  
  flags=flg
 return,val 
end
 


pro faamvariable::setdata,value,start=start,stop=stop, $
      count=count,offset=offset,flags=flags,_EXTRA=_extra
  self->get,frequency=freq,twod=twod
  if(n_elements(start) GT 0) then begin
    self.nc->calc_count_offset,start=start, $
          stop=stop,count=count,offset=offset,freq=freq
  endif	else begin
    if((twod) and (n_elements(count) NE 2)) then begin
      n_el=n_elements(value)
      points=n_el/freq
      offset=[0,0]
      value=reform(value,freq,points,/overwrite)
      count=[freq,points]
    endif else begin
      value=reform(value,/overwrite)
    endelse
  endelse
  self->ncvariable::setdata,value,count=count,offset=offset,_EXTRA=_extra
  if(n_elements(flags) gt 0) then begin
    self->setflags,flags,count=count,offset=offset
  endif
end
  

function faamvariable::getflagobject
  return,self.flag
end



function faamvariable::getflags,start=start,stop=stop, $
      count=count,offset=offset,_EXTRA=_extra
  if(n_elements(start) GT 0) then begin
    self->get,freq=freq
    self.nc->calc_count_offset,start=start, $
          stop=stop,count=count,offset=offset,freq=freq
  endif	
    if(OBJ_VALID(self.flag)) then begin
      flg=self.flag->ncvariable::getdata(count=count,offset=offset,_EXTRA=_extra)
    endif else begin
      val=self->ncvariable::getdata(count=count,offset=offset,_EXTRA=_extra)
      flg=bytarr(size(val,/dim))
    endelse   
  return,flg
end

pro faamvariable::setflags,flags,start=start,stop=stop, $
      count=count,offset=offset,_EXTRA=_extra
  if(OBJ_VALID(self.flag)) then begin
  if(n_elements(start) GT 0) then begin
    self->get,freq=freq
    self.nc->calc_count_offset,start=start, $
          stop=stop,count=count,offset=offset,freq=freq
  endif	
  if(n_elements(flags) eq 1) then begin
    f=byte(self.flag->ncvariable::getdata(count=count,offset=offset,_EXTRA=_extra))
    f(*)=flags
    flags=f
  endif
  self.flag->ncvariable::setdata,flags,count=count,offset=offset,_EXTRA=_extra
  endif
  return
end

function faamvariable::getpara,start=start,stop=stop
  self.nc->calc_count_offset,start=start,stop=stop  
  if(self.time)then begin
    return,obj_new('faamtimepara',self,start,stop)
  endif else begin
    d=self->getdata(start=start,stop=stop,flags=f)
    return,obj_new('faampara',self,start,stop,d,flags=f)
  endelse
end


pro faamvariable::get,units=units,number=number,$
       long_name=long_name,frequency=frequency, $
       short_name=short_name,standard_name=standard_name, $
       okname=okname,fullname=fullname,fltno=fltno,twod=twod,_ref_extra=extra
		
  atts=self.nc->frompointer(self.attributes)
  long_name=self.name
  frequency=1
  twod=0
  units=''
  number=0
  if(size(atts,/TNAME) eq 'STRUCT') then begin
    tn=strlowcase(tag_names(atts))
    if(where(tn eq 'long_name') NE -1)then long_name=atts.long_name
    if(where(tn eq 'short_name') NE -1)then short_name=atts.short_name
    if(where(tn eq 'standard_name') NE -1)then standard_name=atts.standard_name
    if(where(tn eq 'frequency') NE -1)then begin
      frequency=atts.frequency
      twod=1
    endif
    if(where(tn eq 'units') NE -1)then units=atts.units
    if(where(tn eq 'number') NE -1)then number=atts.number
  endif
  self.nc->get,fltno=fltno
  if(n_elements(short_name) EQ 0) then begin
    if(number NE 0) then okname=self.name+'.'+strtrim(string(number),2) else okname=self.name
  endif else begin
    okname=strtrim(strtrim(short_name,2)+'_'+self.name,2)
  endelse
  fullname='['+okname+'] '+strtrim(long_name,2)+ $
     ' ('+strtrim(units,2)+') '+string(frequency,format='(I2)')+'Hz'			    
  self->ncvariable::get,_extra=extra
return
end


pro faamvariable::cleanup
  obj_destroy,self.flag
  self->ncvariable::cleanup
return
end

pro faamvariable__define

struct={faamvariable, INHERITS ncvariable, $
        flag:OBJ_NEW()        $
	,time:0               $
}

return
end
