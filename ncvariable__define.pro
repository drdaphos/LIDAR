; copied from /home/fp0100/tardis/tardis/mrf_idl/ncvariable__define.pro
;+
; NAME:
;   NCvariable
;
; PURPOSE:
;   An object wrapper for NetCDF variables.
;
; CATEGORY:
;   Scientific Data
;
; SUPERCLASSES:
;       This class has no superclasses.
;
; SUBCLASSES:
;       This class has subclasses.
;       FAAMvariable
;
; CREATION:
;       See NCvariable::Init
;
; METHODS:
;       Intrinsic Methods
;       This class has the following methods:
;
;           NCVARIABLE::ADDATTRIBUTE.
;           NCVARIABLE::GETATTRIBUTES.
;           NCVARIABLE::CLEANUP.
;           NCVARIABLE::GETDATA.
;           NCVARIABLE::ADDATTSTRUCT.
;           NCVARIABLE::SETDATA.
;           NCVARIABLE::GETSTRUCT.
;           NCVARIABLE::GETATTRIBUTE.
;           NCVARIABLE::GETFILE.
;           NCVARIABLE::GETATTTEXT.
;           NCVARIABLE::GETDIMTEXT.
;           NCVARIABLE::GETSIZETEXT.
;           NCVARIABLE::GETSIZE.
;           NCVARIABLE::GETTEXT.
;           NCVARIABLE::GETNAME.
;           NCVARIABLE::GETTYPE.
;           NCVARIABLE::GETVARID.
;           NCVARIABLE::INIT.
;           NCVARIABLE__DEFINE.
;
; MODIFICATION HISTORY:
;   Written by: D Tiddeman 2008
;-
;

;+
; =============================================================
;
; NAME:
;       NCvariable::AddAttribute
;
; PURPOSE:
;       The NCvariable::AddAttribute procedure method adds a new attribute to
;                                the variable.(For files opened
;                                with /new or /write)
;
; CALLING SEQUENCE:
;       ncvar->AddAttribute,name,value
;
; INPUTS:
;       name: String name of attribute
;       value: Value of new attribute
;
; OPTIONAL INPUTS:
;
; KEYWORD PARAMETERS:
;
; OUTPUTS:
;
; EXAMPLE:
;       ncvariable->AddAttribute,'Institution','FAAM'
;
; MODIFICATION HISTORY:
;   Written by: D Tiddeman 2008
;-

pro ncvariable::addattribute,name,value
  self.nc->get,iswritable=iswritable
  if(iswritable) then begin
    self.nc->set,defmode=1b
    ncdf_attput,self.ncid,self.varid,name,value
    if(ptr_valid(self.attributes)) then begin
      tn=tag_names(*self.attributes)
      itn=where(strlowcase(tn) eq strlowcase(name))
      if(itn eq -1) then $
       *self.attributes=create_struct(*self.attributes,name,value) else $
           (*self.attributes).(itn)=value
    endif else begin
      self.attributes=ptr_new(create_struct(name,value))
    endelse
  endif else begin
    message,'Cant write to this file'
  endelse

end
;+
; =============================================================
;
; NAME:
;       NCvariable::Get
;
; PURPOSE:
;       The NCvariable:: method
;
; CALLING SEQUENCE:
;       ncvar->
;
; INPUTS:
;
; OPTIONAL INPUTS:
;
; KEYWORD PARAMETERS:
;
; OUTPUTS:
;
; EXAMPLE:
;       ncvar->
;
; MODIFICATION HISTORY:
;   Written by: D Tiddeman 2008
;-


pro ncvariable::get,name=name,type=type,size=size,dimensions=dimensions, $
    attributes=attributes,varid=varid,ncid=ncid,file=file, $
    text=text
  attributes=self.nc->frompointer(self.attributes)
  dimensions=self.nc->frompointer(self.dimensions)
  size=self.nc->frompointer(self.datasize,default='Undefined')
  type=self.datatype
  ncid=self.ncid
  varid=self.varid
  file=self.nc
  name=self.name
  if(keyword_set(text)) then begin
     attributes=self.nc->attastext(attributes)
     dimensions=strjoin(dimensions,',')
     ds=string(size)
     size=strjoin(ds,',')
  endif
  return
end
;+
; =============================================================
;
; NAME:
;       NCvariable::Cleanup
;
; PURPOSE:
;       The NCvariable:: method
;
; CALLING SEQUENCE:
;       ncvar->
;
; INPUTS:
;
; OPTIONAL INPUTS:
;
; KEYWORD PARAMETERS:
;
; OUTPUTS:
;
; EXAMPLE:
;       ncvar->
;
; MODIFICATION HISTORY:
;   Written by: D Tiddeman 2008
;-

pro ncvariable::cleanup
   Ptr_Free, self.datasize
   ptr_free, self.dimensions
   ptr_free, self.attributes
   heap_free,self
end
;+
; =============================================================
;
; NAME:
;       NCvariable::GetData
;
; PURPOSE:
;       The NCvariable:: method
;
; CALLING SEQUENCE:
;       ncvar->
;
; INPUTS:
;
; OPTIONAL INPUTS:
;
; KEYWORD PARAMETERS:
;
; OUTPUTS:
;
; EXAMPLE:
;       ncvar->
;
; MODIFICATION HISTORY:
;   Written by: D Tiddeman 2008
;-

function ncvariable::getdata,count=count,offset=offset,stride=stride
  self.nc->set,defmode=0b
  CATCH,error_status
   IF Error_status NE 0 THEN BEGIN 
      PRINT, 'Error index: ', Error_status 
      PRINT, 'Error message: ', !ERROR_STATE.MSG 
      CATCH, /CANCEL 
      return,!Values.F_NaN
   ENDIF 
  ncdf_varget,self.ncid,self.varid,value,count=count,offset=offset,stride=stride
  fv=self->getatt('_FillValue')
  if(size(fv,/TNAME) EQ 'FLOAT') then begin 
    ibad=where(value EQ fv)
    if(ibad[0] NE -1) then value(ibad)=!VALUES.F_NaN
  endif
  if(size(fv,/TNAME) EQ 'DOUBLE') then begin 
    ibad=where(value EQ fv)
    if(ibad[0] NE -1) then value(ibad)=!VALUES.D_NaN
  endif
  return,value 
end
;+
; =============================================================
;
; NAME:
;       NCvariable::AddAttStruct
;
; PURPOSE:
;       The NCvariable:: method
;
; CALLING SEQUENCE:
;       ncvar->
;
; INPUTS:
;
; OPTIONAL INPUTS:
;
; KEYWORD PARAMETERS:
;
; OUTPUTS:
;
; EXAMPLE:
;       ncvar->
;
; MODIFICATION HISTORY:
;   Written by: D Tiddeman 2008
;-

pro ncvariable::addattstruct,struct,arr,name,value
  struct=create_struct(struct,name,value)
  arr=[arr,name]
return
end
;+
; =============================================================
;
; NAME:
;       NCvariable::SetData
;
; PURPOSE:
;       The NCvariable:: method
;
; CALLING SEQUENCE:
;       ncvar->
;
; INPUTS:
;
; OPTIONAL INPUTS:
;
; KEYWORD PARAMETERS:
;
; OUTPUTS:
;
; EXAMPLE:
;       ncvar->
;
; MODIFICATION HISTORY:
;   Written by: D Tiddeman 2008
;-

pro ncvariable::setdata,value,count=count,offset=offset,stride=stride
  self.nc->set,defmode=0b
  ncdf_varput,self.ncid,self.varid,value,count=count,offset=offset,stride=stride
  ncdf_control,self.ncid,/SYNC
  inq=ncdf_varinq(self.ncid,self.varid)
  self.name=inq.name
  ds=inq.dim
  for i=0,n_elements(inq.dim)-1 do begin
    ncdf_diminq,self.ncid,inq.dim(i),dimname,dimsize
    ds(i)=dimsize
  endfor
  *self.datasize=ds
end

;+
; =============================================================
;
; NAME:
;       NCvariable::GetAtt
;
; PURPOSE:
;       The NCvariable:: method
;
; CALLING SEQUENCE:
;       ncvar->
;
; INPUTS:
;
; OPTIONAL INPUTS:
;
; KEYWORD PARAMETERS:
;
; OUTPUTS:
;
; EXAMPLE:
;       ncvar->
;
; MODIFICATION HISTORY:
;   Written by: D Tiddeman 2008
;-

function ncvariable::getatt,name
  att=(self.nc->frompointer(self.attributes))
  ans=''
  if(size(att,/tname) eq 'STRUCT') then begin
    tn=tag_names(att)
    it=where(tn eq strupcase(name))
    if(it(0) ne -1) then ans=att.(it)
  endif
  return,ans
end
;+
; =============================================================
;
; NAME:
;       NCvariable::GetText
;
; PURPOSE:
;       The NCvariable:: method
;
; CALLING SEQUENCE:
;       ncvar->
;
; INPUTS:
;
; OPTIONAL INPUTS:
;
; KEYWORD PARAMETERS:
;
; OUTPUTS:
;
; EXAMPLE:
;       ncvar->
;
; MODIFICATION HISTORY:
;   Written by: D Tiddeman 2008
;-

function ncvariable::gettext
  ans=self.name+string(10b)+' '+string(10b)
  ans=ans+'Type='+self.datatype+string(10b)+' '+string(10b)
  self->get,size=sizetext,dimensions=dimtext,attributes=atttext,/text
  ans=ans+'Dimensions=('+dimtext+')'+string(10b)
  ans=ans+'['+sizetext+']'+string(10b)+' '+string(10b)
  ans=ans+atttext
return,ans
end

;+
; =============================================================
;
; NAME:
;       NCvariable::Init
;
; PURPOSE:
;       The NCvariable:: method
;
; CALLING SEQUENCE:
;       ncvar->
;
; INPUTS:
;
; OPTIONAL INPUTS:
;
; KEYWORD PARAMETERS:
;
; OUTPUTS:
;
; EXAMPLE:
;       ncvar->
;
; MODIFICATION HISTORY:
;   Written by: D Tiddeman 2008
;-

function ncvariable::init,nc,varname=varname,varid=varid, $
              new=new,dims=dims,attributes=attributes,attnames=attnames, $
	      type=type

   CATCH, theError
   IF theError NE 0 THEN BEGIN
      CATCH, /CANCEL
      void = Error_Message()
      RETURN, 0
   ENDIF
  self.nc=nc
  nc->get,ncid=ncid,iswritable=iswritable
  self.ncid=ncid
  if(keyword_set(new) and iswritable) then begin
    self.nc->set,defmode=1b
    if(n_elements(dims) GT 0) then begin
      ds=lonarr(n_elements(dims))
      dids=lonarr(n_elements(dims))
      for i=0,n_elements(ds)-1 do begin
        dids(i)=ncdf_DIMID(self.ncid,dims(i))
        if(dids(i) GE 0) then begin
	  ncdf_diminq,self.ncid,dids(i),dimname,dimsize
	  ds(i)=dimsize
	endif else begin
	  message,'Dimension not found '+dims(i)
	endelse
      endfor
      self.dimensions=ptr_new(dims)
      self.datasize=ptr_new(ds)
    endif
    self.datatype='FLOAT'
    if(n_elements(type) GT 0) then self.datatype=type 
    self.name=varname
    CASE strupcase(self.datatype) OF
      'BYTE':varid=ncdf_vardef(self.ncid,varname,dids,/byte)
      'CHAR':varid=ncdf_vardef(self.ncid,varname,dids,/char)
      'DOUBLE':varid=ncdf_vardef(self.ncid,varname,dids,/double)
      'FLOAT':varid=ncdf_vardef(self.ncid,varname,dids,/float)
      'LONG':varid=ncdf_vardef(self.ncid,varname,dids,/long)
      'SHORT':varid=ncdf_vardef(self.ncid,varname,dids,/short)
      ELSE:varid=ncdf_vardef(self.ncid,varname,dids)
    ENDCASE
    self.varid=varid
    if(n_elements(attributes)) GT 0 then begin
       natts=tag_names(attributes)
       if(n_elements(attnames) eq n_elements(natts))then natts=attnames
       for i=0,n_elements(natts)-1 do begin
         ncdf_attput,self.ncid,self.varid,natts(i),attributes.(i)
;	 if(n_elements(attnames) eq n_elements(natts))then $
;	     ncdf_attrename,self.ncid,self.varid,natts(i),attnames(i)          
       endfor
       self.attributes=ptr_new(attributes)
    endif
  endif else begin
  if(n_elements(varid) EQ 0) then begin
     if(n_elements(varname) GT 0) then begin
       varid=ncdf_varid(self.ncid,varname)
     endif else begin
       message,'need a variable id or a variable name'
     endelse
  endif 
  self.varid=varid
  inq=ncdf_varinq(self.ncid,self.varid)
  self.name=inq.name
  self.datatype=inq.datatype
  ds=inq.dim
  dms=strarr(n_elements(ds))
  for i=0,n_elements(inq.dim)-1 do begin
    ncdf_diminq,self.ncid,inq.dim(i),dimname,dimsize
    ds(i)=dimsize
    dms(i)=dimname
  endfor
  self.datasize=ptr_new(ds)
  self.dimensions=ptr_new(dms)
  for i=0,inq.natts-1 do begin
    attn=ncdf_attname(self.ncid,self.varid,i)
    ncdf_attget,self.ncid,self.varid,attn,attv
    atti=ncdf_attinq(self.ncid,self.varid,attn)
    IF (Size(attv, /TNAME) EQ 'BYTE') AND (atti.datatype EQ 'CHAR') $
            THEN attv = String(attv)    
    if(i eq 0) then begin 
      atts=create_struct(attn,attv)
    endif else begin
      atts=create_struct(atts,attn,attv)
    endelse
  endfor
  self.attributes=ptr_new(atts)
  endelse
  return,1
end

;+
; =============================================================
;
; NAME:
;       NCvariable__define
;
; PURPOSE:
;       The NCvariable__define method
;
; CALLING SEQUENCE:
;       ncvar->
;
; INPUTS:
;
; OPTIONAL INPUTS:
;
; KEYWORD PARAMETERS:
;
; OUTPUTS:
;
; EXAMPLE:
;       ncvar->
;
; MODIFICATION HISTORY:
;   Written by: D Tiddeman 2008
;-

pro ncvariable__define

   struct = { ncvariable, $
              nc: OBJ_NEW(), $
              ncid: 0l, $
	      varid:0l, $
              datasize: Ptr_New(), $
              dimensions: Ptr_New(), $
              datatype: "", $
              name: "", $
              attributes: Ptr_New()}

END  
