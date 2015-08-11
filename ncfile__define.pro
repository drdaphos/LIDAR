; copied from /home/fp0100/tardis/tardis/mrf_idl/ncfile__define.pro
;+
; NAME:
;   NCfile
;
; PURPOSE:
;   An object wrapper for NetCDF.
;
; CATEGORY:
;   Scientific Data
;
; SUPERCLASSES:
;       This class has no superclasses.
;
; SUBCLASSES:
;       This class has subclasses.
;       FAAMfile
;
; CREATION:
;       See NCfile::Init
;
; METHODS:
;       Intrinsic Methods
;       This class has the following methods:
;
;         NCFILE::INIT
;         NCFILE::GET
;         NCFILE::SET
;         NCFILE::FROMPOINTER
;         NCFILE::ATTASTEXT
;         NCFILE::GETATTTEXT
;         NCFILE::ADDDIMENSION
;         NCFILE::ADDATTRIBUTE
;         NCFILE::ADDVARIABLE
;         NCFILE::GETVAR
;         NCFILE::GETATT
;         NCFILE::CLEANUP
;         NCFILE::CLOSE
;         NCFILE__DEFINE
;
; MODIFICATION HISTORY:
;   Written by: D Tiddeman 2008
;-
;

;+
; =============================================================
;
; NAME:
;       NCfile::Init
;
; PURPOSE:
;       The NCfile::Init function method initializes the file object.
;
;       NOTE: Init methods are special lifecycle methods, and as such
;       cannot be called outside the context of object creation.  This
;       means that in most cases, you cannot call the Init method
;       directly.  There is one exception to this rule: If you write
;       your own subclass of this class, you can call the Init method
;       from within the Init method of the subclass.
;
; CALLING SEQUENCE:
;       ncfile = OBJ_NEW('NCfile',file)
;
; INPUTS:
;      file: Path of file to open
;
;
; OPTIONAL INPUTS:
;
; KEYWORD PARAMETERS:
;     write: Open the file as writable
;       new: Opens a new file 
;   clobber: If creating a new file ( with /new ) and file already exists don't complain.
;
; OUTPUTS:
;       1: successful, 0: unsuccessful.
;
; EXAMPLE:
;       ncfile = OBJ_NEW('NCfile','myfile.nc')
;
; MODIFICATION HISTORY:
;   Written by: D Tiddeman 2008
;-


function ncfile::init,file,write=write,new=new,clobber=clobber
   
   CATCH, theError
   IF theError NE 0 THEN BEGIN
      CATCH, /CANCEL
      void = Error_Message()
      RETURN, 0
   ENDIF
   self.writable=0b
   self.defmode=0b
   self.recdim=-1l
   basename = File_BaseName(file)
   directory = File_DirName(file)
   self.filename=basename
   self.directory=directory
   if(keyword_set(new)) then begin
     self.ncid=ncdf_create(file,clobber=clobber)
     self.writable=1b
     self.defmode=1b
   endif else begin
     IF File_Test(file, /READ) EQ 0 THEN Message, 'Specified file does not exist or is not readable.'
     self.ncid=ncdf_open(file,write=write)
     if (keyword_set(write)) then self.writable=1b     
     inq=ncdf_inquire(self.ncid)
     self.recdim=inq.recdim
     for i=0,inq.ndims-1 do begin
        ncdf_diminq,self.ncid,i,dimname,dimsize
	if(i eq 0) then begin
          thedims=create_struct(dimname,dimsize)
	endif else begin
          thedims=create_struct(thedims,dimname,dimsize)
	endelse
     endfor
     self.thedimensions=ptr_new(thedims)
     for i=0,inq.ngatts-1 do begin
      attn=ncdf_attname(self.ncid,i,/global)
      ncdf_attget,self.ncid,attn,attv,/global
      atti=ncdf_attinq(self.ncid,attn,/global)
      IF (Size(attv, /TNAME) EQ 'BYTE') AND (atti.datatype EQ 'CHAR') $
            THEN attv = String(attv)    
	if(i eq 0) then begin
          atts=create_struct(attn,attv)
	endif else begin
          atts=create_struct(atts,attn,attv)
	endelse
     endfor
     self.theattributes=ptr_new(atts)
     for i=0,inq.nvars-1 do begin
       v=obj_new('ncvariable',self,varid=i)
       v->get,name=nm
       nm=idl_validname(nm,/convert_all)
	if(i eq 0) then begin
         vars=create_struct(nm,v)
	endif else begin
         vars=create_struct(vars,nm,v)
	endelse
     endfor
     self.thevariables=ptr_new(vars)
   endelse
   return,1
END

PRO NCFILE::GET,structure=structure,variables=variables,dimensions=dimensions, $
    attributes=attributes,iswritable=iswritable,ncid=ncid,defmode=defmode, $
    filename=filename,text=text


  variables=self->frompointer(self.thevariables)
  attributes=self->frompointer(self.theattributes)
  dimensions=self->frompointer(self.thedimensions)
  structure=create_struct('file',self.filename,'variables',variables, $
                      'attributes',attributes, $
		      'dimensions',dimensions)
   if(keyword_set(text)) then begin
     attributes=self->attastext(attributes)
     if(size(dimensions,/TNAME) eq 'STRUCT') then begin
       d=''
      tn=tag_names(dimensions)
      for i=0,n_elements(tn)-1 do begin
        d=d+tn(i)+' -> '
        if i eq self.recdim then d=d+'UNLIMITED currently '
        d=d+strtrim(string(dimensions.(i)),2)+string(10b) 
      endfor
      dimensions=d
    endif   
    if(size(variables,/TNAME) eq 'STRUCT') then begin
      v=''
      tn=tag_names(variables)
      for i=0,n_elements(tn)-1 do begin
        v=v+(variables.(i))->gettext()+string(10b)+string(10b)
      endfor
      variables=v
    endif   
  endif
  ncid=self.ncid
  filename=self.filename
  defmode=self.defmode
  iswritable=self.writable
END


PRO NCFILE::SET,defmode=defmode
  if(n_elements(defmode) GT 0) then begin
    if(self.defmode ne defmode) then begin
      self.defmode=defmode;
      if(defmode)then ncdf_control,self.ncid,/redef $
       else ncdf_control,self.ncid,/endef
    endif  
  endif	      
END

;+
; =============================================================
;
; NAME:
;       NCfile::FromPointer
;
; PURPOSE:
;       The NCfile::frompointer function method returns a variable pointed to by pointer.
;
; CALLING SEQUENCE:
;       var=ncfile->FromPointer(inp)
;
; INPUTS:
;       inp:  A pointer to a variable
;
; OPTIONAL INPUTS:
;
; KEYWORD PARAMETERS:
;   default:  If not a valid pointer returns default rather than string 'None' if set.
;
; OUTPUTS:
;       The value of what the pointer points to or 'None' if not valid.
;
; EXAMPLE:
;       var=ncfile->FromPointer(inp,default='Undefined')
;
; MODIFICATION HISTORY:
;   Written by: D Tiddeman 2008
;-

function ncfile::frompointer,inp,default=default
  ans='None'
  if(n_elements(default) GT 0) then ans=default
  if(ptr_valid(inp))then $
    if n_elements(*inp) GT 0 then ans=*inp
  return,ans
end
;+
; =============================================================
;
; NAME:
;       NCfile::AttasText
;
; PURPOSE:
;       The NCfile::AttasText function method returns the given attributes as text.
;
; CALLING SEQUENCE:
;       text=ncfile->AttasText(atts)
;
; INPUTS:
;      atts:  Attributes as a structure to convert
;
; OPTIONAL INPUTS:
;
; KEYWORD PARAMETERS:
;
; OUTPUTS:
;       A textual description of the attributes
;
; EXAMPLE:
;       print,ncfile->AttasText(attributes)
;
; MODIFICATION HISTORY:
;   Written by: D Tiddeman 2008
;-

function ncfile::attastext,atts
 if(size(atts,/TNAME) eq 'STRUCT') then begin
   ans=''
   tn=tag_names(atts)
   for i=0,n_elements(tn)-1 do begin
      ans=ans+tn(i)+string(10b)
      ans=ans+strtrim(string(atts.(i),/print),2)+ $
        string(10b)+' '+string(10b)
    endfor
 endif else begin
    ans=atts
 endelse
return,ans
end

;+
; =============================================================
;
; NAME:
;       NCfile::AddDimension
;
; PURPOSE:
;       The NCfile::AddDimension procedure method adds a new dimension to the file.(For files opened
;                                with /new or /write)
;
; CALLING SEQUENCE:
;       ncfile->AddDimension,name,size
;
; INPUTS:
;       name: String name of dimensions
;       size: The size of the dimension 0 for unlimited.
;
; OPTIONAL INPUTS:
;
; KEYWORD PARAMETERS:
;
; OUTPUTS:
;
; EXAMPLE:
;       ncfile->AddDimension,'data_point',0
;
; MODIFICATION HISTORY:
;   Written by: D Tiddeman 2008
;-

pro ncfile::adddimension,name,size
  if(self.writable) then begin
    self->set,defmode=1b
    if((size eq 0) and (self.recdim eq -1)) then begin
      self.recdim=ncdf_dimdef(self.ncid,name,/unlimited)
      if(ptr_valid(self.thedimensions)) then $
        *self.thedimensions=create_struct(*self.thedimensions,name,size) else $
        self.thedimensions=ptr_new(create_struct(name,size)) 
    endif else begin
      if(size GT 0)then begin
      dimid=ncdf_dimdef(self.ncid,name,size)
      if(ptr_valid(self.thedimensions)) then $
         *self.thedimensions=create_struct(*self.thedimensions,name,size) else $
         self.thedimensions=ptr_new(create_struct(name,size))
      endif    
    endelse    
  endif else begin
    message,'Cant write to this file'
  endelse
end
;+
; =============================================================
;
; NAME:
;       NCfile::AddAttribute
;
; PURPOSE:
;       The NCfile::AddAttribute procedure method adds a new global attribute to the file.(For files opened
;                                with /new or /write)
;
; CALLING SEQUENCE:
;       ncfile->AddAttribute,name,value
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
;       ncfile->AddAttribute,'Institution','FAAM'
;
; MODIFICATION HISTORY:
;   Written by: D Tiddeman 2008
;-

pro ncfile::addattribute,name,value
  if(self.writable) then begin
    self->set,defmode=1b
    ncdf_attput,self.ncid,name,value,/global
    if(ptr_valid(self.theattributes)) then begin
      tn=tag_names(*self.theattributes)
      itn=where(strlowcase(tn) eq strlowcase(name))
      if(itn eq -1) then $
        *self.theattributes=create_struct(*self.theattributes,name,value) $
        else (*self.theattributes).(itn)=value
    endif else begin
      self.theattributes=ptr_new(create_struct(name,value))
    endelse
  endif else begin
    message,'Cant write to this file'
  endelse

end
;+
; =============================================================
;
; NAME:
;       NCfile::AddVariable
;
; PURPOSE:
;       The NCfile::AddVariable procedure method adds a new variable to the file.(For files opened
;                                with /new or /write)
;
; CALLING SEQUENCE:
;       ncfile->AddVariable,name,type
;
; INPUTS:
;       name: String name of variable
;       type: The type of data stored.
;
; OPTIONAL INPUTS:
;
; KEYWORD PARAMETERS:
;       dims: A string array naming the dimensions of the variable
; attributes: A structure defining the attributes of the variable
;   attnames: A string array to rename the attributes defined with
;             attributes ( a messy way of creating case sensitive
;             attribute names with case insensitive structure keys)
;        var: Returns the variable object created.
;
; OUTPUTS:
;
; EXAMPLE:
;       ncfile->AddVariable,'bob','FLOAT',dims=['data_point','sps02'], $
;        attributes={units:'m s-2',frequency:2},attnames=['Units','Frequency'], $
;        var=bob
;
; MODIFICATION HISTORY:
;   Written by: D Tiddeman 2008
;-

pro ncfile::addvariable,name,type,dims=dims,attributes=attributes, $
           attnames=attnames,var=v
  if(self.writable) then begin
    self->set,defmode=1b
    v=obj_new('ncvariable',self,varname=name,dims=dims, $
             attributes=attributes,attnames=attnames,/new,type=type)
    if(ptr_valid(self.thevariables)) then $   
      *self.thevariables=create_struct(*self.thevariables,name,v) else $
      self.thevariables=ptr_new(create_struct(name,v))
  endif else begin
    message,'Cant write to this file'
  endelse
end
;+
; =============================================================
;
; NAME:
;       NCfile::GetVar
;
; PURPOSE:
;       The NCfile::GetVar function method returns the variable object requested.
;
; CALLING SEQUENCE:
;       var=ncfile->GetVar(name)
;
; INPUTS:
;
; OPTIONAL INPUTS:
;       name: Name of variable this must be specified if keyword IND not used
;
; KEYWORD PARAMETERS:
;       ind: Index of variable in file, alternative to specifying the name.
;
; OUTPUTS:
;       The variable defined as an object (NCVARIABLE)
;
; EXAMPLE:
;       var=ncfile->GetVariable('bob')
;  or
;       var=ncfile->GetVariable(ind=0)
;
; MODIFICATION HISTORY:
;   Written by: D Tiddeman 2008
;-

function ncfile::getvar,name,fromindex=fromindex,index=index
  ans='Undefined'
  if(ptr_valid(self.thevariables)) then begin
    if(n_elements(name) GT 0) then begin
      n=where(tag_names(*self.thevariables) eq strupcase(name))
      if(n(0) EQ -1) then begin
        nvalid=strupcase(idl_validname(name,/convert_all))
        n=where(tag_names(*self.thevariables) eq nvalid)
      endif  
      fromindex=n(0)
    endif else begin
      if(n_elements(fromindex) eq 0) then fromindex=-1
    endelse
    if(keyword_set(index)) then begin
      ans=fromindex 
    endif else begin
      if(fromindex ne -1) then ans=(*self.thevariables).(fromindex) 
    endelse
  endif
  return,ans
end

function ncfile::getatt,name
  att=(self->frompointer(self.theattributes))
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
;       NCfile::Cleanup
;
; PURPOSE:
;       The NCfile::Cleanup procedure method preforms all cleanup
;       on the object.
;
;       NOTE: Cleanup methods are special lifecycle methods, and as such
;       cannot be called outside the context of object destruction.  This
;       means that in most cases, you cannot call the Cleanup method
;       directly.  There is one exception to this rule: If you write
;       your own subclass of this class, you can call the Cleanup method
;       from within the Cleanup method of the subclass.
;
; CALLING SEQUENCE:
;       OBJ_DESTROY,ncfile
;
; INPUTS:
;       There are no inputs for this method.
;
; OPTIONAL INPUTS:
;
; KEYWORD PARAMETERS:
;       There are no keywords for this method.
;
; OUTPUTS:
;
;
; MODIFICATION HISTORY:
;   Written by: D Tiddeman 2008
;-

pro ncfile::cleanup
   vars=self->frompointer(self.thevariables)
   if(size(vars,/TNAME) eq 'STRUCT') then begin
     for f=0,n_tags(vars)-1 do begin
       obj_destroy,vars.(f)
     endfor
   endif
   self->set,defmode=0b
   ncdf_close,self.ncid
   Ptr_Free, self.theAttributes
   Ptr_Free, self.theDimensions
   Ptr_Free, self.theVariables
   heap_free,self
end

;+
; =============================================================
;
; NAME:
;       NCfile::Close
;
; PURPOSE:
;       The NCfile::Close procedure method is another way to call cleanup
;                         Closes file and destroys the object
;
; CALLING SEQUENCE:
;       ncfile->Close()
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
;       ncfile->Close()
;
; MODIFICATION HISTORY:
;   Written by: D Tiddeman 2008
;-

pro ncfile::close
  OBJ_DESTROY,self
end
;+
; =============================================================
;
; NAME:
;      NCfile__Define
;
; Purpose:
;  Defines the object structure for a NCfile object.
;
; MODIFICATION HISTORY:
;   Written by: D Tiddeman 2008
;-


pro ncfile__define
  void={     ncfile, $
             filename: "",             $  ; The filename of the netCDF file.
             directory: "",            $  ; The directory the file is located in.
             ncid:0l,                  $  ; A flag to indicate the object is destroyed if brower is destroyed.
             writable: 0B,             $  ; A flag to indicate if the file canbe written to.
             defmode: 0B,              $  ; A flag to indicate if in define mode.
	     recdim:0L,                $  ; ID of unlimited dimension
             theAttributes: Ptr_New(), $  ; An array of global attribute structures.
             theDimensions: Ptr_New(), $  ; An array of dimension structures.
             theVariables: Ptr_New()   $  ; An array of variable structures.
           }

END ;---------------------------------------------------------------------------------------------
        
