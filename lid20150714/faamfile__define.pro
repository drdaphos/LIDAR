; copied from /home/fp0100/tardis/tardis/mrf_idl/faamfile__define.pro
;+
; NAME:
;   FAAMfile
;
; PURPOSE:
;   A wrapper for a FAAM style NetCDF
;
; CATEGORY:
;   Scientific Data
;
; SUPERCLASSES:
;       This class inherits from NCfile
;
; SUBCLASSES:
;       MRFfile
;
; CREATION:
;       See FAAMfile::Init
;
; METHODS:
;       Intrinsic Methods
;       This class has the following methods:
;
;          FAAMFILE::INIT
;          FAAMFILE::GETFLTNODATE
;          FAAMFILE::ADDTIMEVARIABLE
;          FAAMFILE::SETTIMES
;          FAAMFILE::ADDVARIABLE
;          FAAMFILE::GET
;          FAAMFILE::GETTIME
;          FAAMFILE::MRFREAD
;          FAAMFILE::PLOT
;          FAAMFILE::GET_INDEXES
;          FAAMFILE::EXTRACT_TEXT
;          FAAMFILE::GETPARA
;          FAAMFILE::GETVAR
;          FAAMFILE::WHERETIME
;          FAAMFILE::CALC_COUNT_OFFSET
;          FAAMFILE::CLEANUP
;          FAAMFILE__DEFINE
;
; MODIFICATION HISTORY:
;   Written by: D. Tiddeman 2008
;-

;+
; =============================================================
;
; NAME:
;       FAAMfile::Init
;
; PURPOSE:
;       The FAAMfile::Init function method initializes the file object.
;
;       NOTE: Init methods are special lifecycle methods, and as such
;       cannot be called outside the context of object creation.  This
;       means that in most cases, you cannot call the Init method
;       directly.  There is one exception to this rule: If you write
;       your own subclass of this class, you can call the Init method
;       from within the Init method of the subclass.
;
; CALLING SEQUENCE:
;       faamfile = OBJ_NEW('FAAMfile',file)
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
;      date: Date of the file data ( for new files)
;     start: Start time of data( for new files)
;      stop: Stop time of data( for new files)
;     fltno: Flight number( for new files)
;
;
; OUTPUTS:
;       1: successful, 0: unsuccessful.
;
; EXAMPLE:
;       faamfile = OBJ_NEW('FAAMfile','myfaamfile.nc')
;
; MODIFICATION HISTORY:
;   Written by: D Tiddeman 2008
;-

function faamfile::init,file,_REF_EXTRA=_extra,new=new, $
  date=date,start=start,stop=stop,fltno=fltno

IF(self->ncfile::init(file,_EXTRA=_extra,new=new) EQ 0) then return,0

vars=self->frompointer(self.thevariables)

if size(vars,/TNAME) eq 'STRUCT' then begin
  tn=tag_names(vars)
  flags=lonarr(n_elements(tn))
  paras=lonarr(n_elements(tn))
  nflags=0
  nparas=0    
  newvars=objarr(n_elements(tn))
  nnewvars=0 
  for i=0,n_elements(tn)-1 do begin
    sl=strlen(tn(i))
    vars.(i)->get,type=type,varid=varid
    IF ((type ne 'BYTE') or (strmid(tn(i),sl-4) ne 'FLAG')) then begin
       newvars(nnewvars)=obj_new('faamvariable',self,varid=varid)
;       if ((type eq 'LONG') and (strupcase(tn(i)) eq 'TIME')) then begin
       if ((strupcase(tn(i)) eq 'TIME')) then begin
         self.timeobj=newvars(nnewvars)
         self->gettime,start=start1,stop=stop1
	 self.otimestart=start1	 
	 self.otimestop=stop1	 
       endif
       nnewvars=nnewvars+1
       OBJ_DESTROY,vars.(i)
    endif
  endfor
  nv=0       
  for i=0,nnewvars-1 do begin
      newvars(i)->get,name=name
      name=idl_validname(name,/convert_all)
      if(nv eq 0) then begin
        vs=create_struct(name,newvars(i))
      endif else begin
        vs=create_struct(vs,name,newvars(i))
      endelse
      nv=nv+1
  endfor    
  *self.thevariables=vs
  self->getfltnodate 
  if strlen(self.date) ne 8 or strlen(self.fltno) ne 4 then self->getfltnodate,/fromtitle
endif else begin
  if keyword_set(new) then begin
    self->ncfile::adddimension,'data_point',0
    self->ncfile::adddimension,'sps01',1
    self->ncfile::addattribute,'conventions','CF-1.0'
    self->getfltnodate
    if(n_elements(date) eq 1) then self.date=date
    if(n_elements(fltno) eq 1) then self.fltno=fltno
    b=bin_date()    
    self->ncfile::addattribute,'data_date',string(b([0,1,2]),format='(I4.4,I2.2,I2.2)')    
    if strlen(self.date) eq 8 and $
       n_elements(start) eq 1 and strlen(self.fltno) eq 4 then begin
      self->addtimevariable,self.fltno,self.date,start,stop=stop
    endif else begin
      print,'Need to specify a time variable'
      print,"this->addtimevariable,'bXXX','YYYYMMDD',start  (flight number, date of flight,start time in seconds past midnight)"
    endelse
  endif
endelse

return,1
end
;+
; =============================================================
;
; NAME:
;       FAAMfile::GetfFltnoDate,fromtitle=fromtitle
;
; PURPOSE:
;       The FAAMfile::GetFltnoDate_fromfilename procedure method 
;                     gets the flight number and date from file
;                     name if available in standard BADC naming.
;       The FAAMfile::GetFltnoDate_fromtitle procedure method 
;                     gets the flight number and date from the
;                     title attribute if available.
;
; CALLING SEQUENCE:
;       faamfile->GetFltnoDate
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
;       faamfile->GetFltnoDate,/fromtitle
;
; MODIFICATION HISTORY:
;   Written by: D Tiddeman 2008
;-

pro faamfile::getfltnodate,fromtitle=fromtitle
if(keyword_set(fromtitle)) then begin 
  tit=self->getatt('title')
  ans='bXXX'
  stit=(strsplit(strlowcase(tit),' ',/extract))
  i=where(strmatch(stit,'[a-z][0-9][0-9][0-9]') eq 1)
  if(i[0] ne -1)then self.fltno=stit[i[0]]
  i=where(strmatch(stit,'*-*-*') eq 1)
  if(i[0] eq -1)then i=where(strmatch(stit,'*/*/*') eq 1)
  if(i[0] eq -1)then i=where(strmatch(stit,'[12][09][0-9][0-9][0-9][0-9][0-9][0-9]') eq 1)
  if(i[0] ne -1)then self.date=parsedate(stit[i[0]])
endif else begin
  fsplit=strsplit(self.filename,'_',/extract)
  if(n_elements(fsplit) GT 2) then begin
    if(strlen(fsplit(2)) eq 8) then self.date=fsplit(2)
  endif
  if(n_elements(fsplit) GT 4) then begin
    fno=''
    i=1
    while((i LT n_elements(fsplit)) and (strlen(fno(0)) NE 4)) do begin
      fno=fsplit(n_elements(fsplit)-i)
      if(i eq 1) then fno=strsplit(fno,'.',/extract)
      i=i+1
    endwhile
    self.fltno=fno(0)
  endif
endelse
return
end 
;+
; =============================================================
;
; NAME:
;       FAAMfile::AddTimeVariable
;
; PURPOSE:
;       The FAAMfile::AddTimeVariable procedure method adds a new time
;                            variable to the file.(For files opened
;                            with /new or /write)
;
; CALLING SEQUENCE:
;       faamfile->AddTimeVariable,fltno,date,start
;
; INPUTS:
;      fltno: Flight Number
;       date: Flight date.
;      start: start time in seconds past midnight
;
; OPTIONAL INPUTS:
;
; KEYWORD PARAMETERS:
;       stop: Optional stop time in seconds past midnight
;
; OUTPUTS:
;
; EXAMPLE:
;       faamfile->AddTimeVariable,fltno,date,start,stop=stop
;
; MODIFICATION HISTORY:
;   Written by: D Tiddeman 2008
;-


pro faamfile::addtimevariable,fltno,date,start,stop=stop
    self.fltno=fltno
    self.date=date
    self->addvariable,'Time',type='LONG', $
      long_name='time of measurement', $
      standard_name='time',FillValue=-1l, $
	   units='seconds since '+ $
	   strmid(date,0,4)+'-'+strmid(date,4,2)+'-'+strmid(date,6,2)+ $
	   ' 00:00:00 +0000',/noflag,var=timeobj
      self.timeobj=timeobj
    self->ncfile::addattribute,'title','Data from '+fltno+' on '+date      
    t=start
    if(n_elements(stop) GT 0) then t=findgen(stop-start+1)+start
    self.otimestart=start
    self.otimestop=start
    if(n_elements(stop) GT 0) then self.otimestop=stop
    self->ncfile::addattribute,'TimeInterval',gmts(start)+'-'+gmts(max(t))     
    self.timeobj->setdata,t
return
end
;+
; =============================================================
;
; NAME:
;       FAAMfile::SetTimes
;
; PURPOSE:
;       The FAAMfile::SetTimes sets start and end time and files
;                              time variable .(For files opened
;                            with /new or /write)
;
; CALLING SEQUENCE:
;       faamfile->SetTimes
;
; INPUTS:
;
; OPTIONAL INPUTS:
;
; KEYWORD PARAMETERS:
;      start: Optional start time in seconds past midnight
;       stop: Optional stop time in seconds past midnight
;
; OUTPUTS:
;
; EXAMPLE:
;       faamfile->SetTimes,start=start,stop=stop
;
; MODIFICATION HISTORY:
;   Written by: D Tiddeman 2008
;-

pro faamfile::settimes,start=start,stop=stop
    self->gettime,start=start1,stop=stop1,timelength=timelength
    if(n_elements(start) EQ 0) then start=start1
    t=start
    if(n_elements(stop) EQ 0) then stop=start+timelength-1
    if(start NE self.otimestart or stop NE self.otimestop) then begin
      t=findgen(stop-start+1)+start
      self.timeobj->setdata,t
      self->ncfile::addattribute,'TimeInterval',gmts(start)+'-'+gmts(max(t)) 
    endif
    
return
end    


pro faamfile::addvariable,name,var=v,_extra=extra

  if(self.writable) then begin
    self->set,defmode=1b
    v=obj_new('faamvariable',self,varname=name,_extra=extra,/new)
    if(ptr_valid(self.thevariables)) then $   
      *self.thevariables=create_struct(*self.thevariables,name,v) else $
      self.thevariables=ptr_new(create_struct(name,v))
  endif else begin
    message,'Cant write to this file'
  endelse

end

pro faamfile::get,fltno=fltno,date=date,_ref_extra=extra
  fltno=self.fltno
  date=self.date
  self->ncfile::get,_extra=extra
end

pro faamfile::gettime,times=times,start=start,stop=stop,timelength=timelength
  start=self.timeobj->getdata(count=1,offset=0)
  self.timeobj->get,size=timelength
  stop=start+timelength-1
  if(arg_present(times)) then times=findgen(timelength)+start
end

pro faamfile::mrfread,IPARA, $
                 RDATA,flags=flags, $
                 start=start,stop=stop, $
                 pnames=pnames,faamparas=faamparas, $
		 fltno=fltno,date=date,_extra=extra
faamparas=objarr(n_elements(ipara))
faamind=self->get_indexes(ipara)
self->get,fltno=fltno,date=date
first=1
for f=0,n_elements(ipara)-1 do begin
  if((faamind(f))[0] ne -1) then begin
    faamparas(f)=self->getpara(ind=faamind[f],start=start,stop=stop)
    if(arg_present(rdata))then begin
      d=(faamparas(f))->getdata(flags=fl,_extra=extra)
      if(first) then begin
        first=0
        rdata=fltarr(n_elements(ipara),n_elements(d))
        if(arg_present(flags)) then flags=bytarr(n_elements(ipara),n_elements(d))
      endif
      rdata(f,*)=d
      if(arg_present(flags)) then flags(f,*)=fl
    endif
  endif
endfor
return
end

function faamfile::plot,indv,depv,iselect=iselect,selected=selected, $
          run=run,start=start,stop=stop,plottype=plottype,widget=widget, $
	  filt=filt,plotcolors=plotcolors,plotlines=plotlines,plotthick=plotthick, $
	  plotsyms=plotsyms,plotnames=plotnames,nodraw=nodraw,_extra=extra
      self->get,structure=struct
      vars=struct.variables      
      q=obj_new()
      if(n_elements(indv) GT 0) then begin
        iselect=self->get_indexes(indv)
        if(n_elements(depv) GT 0) then begin
          selected=self->get_indexes(depv)
        endif
      endif
      if((n_elements(iselect) eq 1) and (n_elements(selected) gt 1)) then begin
        isel=lonarr(n_elements(selected))
	isel(*)=iselect
      endif else begin
         isel=iselect
      endelse
      nsels=n_elements(selected)
      if(nsels GT 0)then begin
        if(n_elements(plotcolors) eq 0) then plotcolors=lindgen(nsels)+1
        if(n_elements(plottype) eq 0) then plottype='obrplot'
        plotted=0
        for f=0,n_elements(selected)-1 do begin
          if(isel[f] NE -1) and (selected[f] NE -1) then begin
            ind=vars.(isel[f])
            dep=vars.(selected(f))
	    if(n_elements(plotlines) eq nsels) then linestyle=plotlines(f)
	    if(n_elements(plotthick) eq nsels) then thick=plotthick(f)
	    if(n_elements(plotsyms) eq nsels) then psym=plotsyms(f)
	    if(n_elements(plotnames) eq nsels) then name=plotnames(f)
  	      if not(plotted) then begin
	      ind->get,name=nm
              timeplot=0
              if (strlowcase(nm) eq 'time') then timeplot=1
              q=obj_new(plottype,ind,dep,widget=widget, $
                    datatype='faamplotdata',timeplot=timeplot, $
	            filt=filt,start=start,stop=stop,runname=run,/nodraw, $
		    color=plotcolors(f),linestyle=linestyle,thick=thick, $
		    psym=psym,name=name,_extra=extra)
	      plotted=1
 	    endif else begin
              q->plot,ind,dep,color=plotcolors(f),/nodraw
	    endelse
	  endif
        endfor
        if(obj_valid(q) and not(keyword_set(nodraw))) then q->draw
      endif
return,q
end

function faamfile::get_indexes,ipara
ans=lonarr(n_elements(ipara))
for f=0,n_elements(ipara)-1 do begin
  ans[f]=self->getvar(ipara(f),/index)
endfor
return,ans
end

pro faamfile::extract_text,ipara,run=run,start=start,stop=stop,selected=selected, $
                          filename=filename,_extra=extra
		
      filt={maxflag:0   $
		      ,tstep:1          $
		      ,freq:1           $
		      ,avg:0            $
		      ,stretch:0        $
		      ,interpflag:3}
      if(n_elements(extra) GT 0) then begin
        tn=tag_names(extra)
	if(max(strmatch(tn,'MAXFLAG')))then filt.maxflag=extra.maxflag
	if(max(strmatch(tn,'TSTEP')))then filt.tstep=extra.tstep
	if(max(strmatch(tn,'FREQ')))then filt.freq=extra.freq
	if(max(strmatch(tn,'AVG')))then filt.avg=extra.avg
	if(max(strmatch(tn,'STRETCH')))then filt.stretch=extra.stretch
	if(max(strmatch(tn,'INTERPFLAG')))then filt.interpflag=extra.interpflag
      ENDIF
      self->get,structure=struct,filename=dataset,fltno=fltno,date=date
      vars=struct.variables      
      if(n_elements(ipara) GT 0) then begin
        selected=self->get_indexes(ipara)
      endif
      np=n_elements(selected)
      if(n_elements(run) eq 0) then run=''
      if(n_elements(filename) eq 0) then begin
        filename=fltno+run+".txt"
        filename=dialog_pickfile(file=filename)
      endif
      if(filename NE '') then begin
        openw,unit,filename,/get_lun
        printf,unit,'Flight Number: '+fltno
        printf,unit,date
        printf,unit,'Dataset:'+dataset
        printf,unit,strtrim(string(np),2)+' Parameters '
        time=(self->getpara('Time',start=start,stop=stop))->getdata(_extra=filt)
        for pn=0,np-1 do begin
          para=vars.(selected(pn))
	  para->get,fullname=fullname
          printf,unit,fullname
          d=(para->getpara(start=start,stop=stop))->getdata(_extra=filt) 
          if(pn eq 0) then data=fltarr(np,n_elements(d))
          data(pn,*)=d  
        endfor
        if(run NE '') then printf,unit,run
        printf,unit,'Start time ',gmts(start),' (',strtrim(string(start),2),' secs past midnight)'
        printf,unit,'End time ',gmts(stop),' (',strtrim(string(stop),2),' secs past midnight)'
          if filt.tstep NE 1 then s=strtrim(string(filt.tstep),2)+' secs' else $
                s=strtrim(string(filt.freq),2)+' Hz'
          if filt.avg eq 1 then begin
          if filt.tstep ne 1 then s='over '+s else s='at '+s
          printf,unit,'Averaged data '+s
        endif else begin
          printf,unit,'Spot values at '+s
        endelse
        if filt.interpflag LT 3 then printf,unit, $
                   'Interpolated for data with a flag GT ',filt.interpflag
        n=n_elements(data(0,*))
        printf,unit,'Number of datapoints = '+strtrim(string(n),2)
        printf,unit,' '
        s='Time        '
        for pn=0,np-1 do begin
	  (vars.(selected(pn)))->get,name=name
          s=s+string(name,format='(A14)')
        endfor
        printf,unit,s
        printf,unit,' '
        for i=0l,n-1l do begin
          s=gmts(time(i),sec_format='(F6.3)')
          for pn=0,np-1 do begin
            s=s+' '+string(data(pn,i),format='(G13.6E1)')
          endfor
          printf,unit,s
        endfor
        close,unit
        free_lun,unit
        print,'Data written'
      endif
return
end
  
function faamfile::getpara,name,ind=i,_ref_extra=extra
  ans=(self->getvar(name,fromindex=i))
  if(size(ans,/TNAME) eq 'OBJREF') then ans=ans->getpara(_extra=extra)
  return,ans
end  


function faamfile::getvar,name,fromindex=fromindex,index=index
  ans='Undefined'
  if(ptr_valid(self.thevariables)) then begin
    if((size(name,/type) eq 2) or (size(name,/type) eq 3)) then begin
      p='PARA'+string(name,format='(i4.4)')
      if(name eq 0) then p='Time'
      fromindex=self->ncfile::getvar(p,/index)
      if(fromindex eq -1) then begin
        v=self->frompointer(self.thevariables)
        for f=0,n_tags(v)-1 do begin
          n=v.(f)->getatt('number')
	  if(size(n,/type) eq 2) or (size(n,/type) eq 3) then begin
	    if(n eq name) then fromindex=f
	  endif
        endfor
      endif
      ans=self->ncfile::getvar(fromindex=fromindex,index=index)
    endif else begin
      ans=self->ncfile::getvar(name,fromindex=fromindex,index=index)
    endelse
  endif
return,ans
end      

function faamfile::wheretime,t1
  self->gettime,times=times
  return,where(times eq t1)
end

pro faamfile::calc_count_offset,start=start,stop=stop, $
          count=count,offset=offset,freq=freq
    st=-1 
    stp=-1 
    self->gettime,times=times,stop=stop1,start=start1,timelength=timelength 
    if(n_elements(start) GT 0) then $
         st=where(times eq start) else $
	 start=start1
    if(n_elements(stop) GT 0) then $
         stp=where(times eq stop) else $
	 stop=stop1
    if(st(0) eq -1) then st=0
    if(stp(0) eq -1) then stp=timelength-1
    if(n_elements(freq) gt 0) then begin
      offset=[0,st]
      count=[freq,stp-st+1]
    endif else begin
      offset=[st]
      count=[stp-st+1]
    endelse
    
return
end

pro faamfile::cleanup
  if((self.writable) and obj_valid(self.timeobj)) then self->settimes
  self->ncfile::cleanup
  heap_free,self
return
end

pro faamfile__define

struct={faamfile, INHERITS ncfile,fltno:'',date:'', $
   otimestart:0l,otimestop:0l,timeobj:OBJ_NEW()}

return 
end
