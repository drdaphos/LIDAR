; copied from /home/fp0100/tardis/tardis/mrf_idl/faampara__define.pro
function faampara::init,variable,start,stop,d,Flags=f, $
            runname=runname,frequency=frequency

self.frequency=1
nsec=0
self.variable=variable
self->setdata,D,flags=F,frequency=frequency
self.start=start
self.stop=stop
if(n_elements(runname) GT 0) then self.runname=runname
return,1

end 

pro faampara::avg,data,flags,n2,ratio

n=n_elements(data)
data2=fltarr(n2)
flags2=bytarr(n2)
for i=0l,n2-1l do begin
  ixn=((i+1)*ratio)-1
  if ixn GE n then ixn=n-1
  xd=data(i*ratio:ixn)
  xf=flags(i*ratio:ixn)
  minf=min(xf)
  ixf=where(xf eq minf)
  nixf=n_elements(ixf)
  data2(i)=mean(xd(ixf))
  flags2(i)=minf
endfor
data=data2
flags=flags2

return
end


pro faampara::stretch,data,flags,n2,ratio

n=n_elements(data)

data2=fltarr(n2)
flags2=bytarr(n2)
for i=0l,n-1l do begin
  ixn=((i+1)*ratio)-1
  if ixn GE n2 then ixn=n2-1
  data2(i*ratio:ixn)=data(i)
  flags2(i*ratio:ixn)=flags(i)
endfor
data=data2
flags=flags2

return
end

pro faampara::spot1,data,flags,n2,ratio

n=n_elements(data)

data2=fltarr(n2)
flags2=bytarr(n2)
data2(*)=-9999.0
flags2(*)=3

for i=0l,n-1 do begin
  data2(i*ratio)=data(i)
  flags2(i*ratio)=flags(i)
endfor
data=data2
flags=flags2

return
end

pro faampara::spot2,data,flags,n2,ratio

n=n_elements(data)

data2=fltarr(n2)
flags2=bytarr(n2)

for i=0l,n2-1 do begin
  data2(i)=data(i*ratio)
  flags2(i)=flags(i*ratio)
endfor
data=data2
flags=flags2

return
end

pro faampara::interp,data,flags,flag

if n_elements(flag) eq 0 then flag=0

i=where(flags le flag)

ni=long(n_elements(i))


if ni GT 1 then begin

  for i1=0l,ni-2l do begin

    idx1=i(i1)
    idx2=i(i1+1)

    if idx2 GT (idx1+1) then begin
     idiff=idx2-idx1
     diff=data(idx2)-data(idx1)
     missbit=(1.0+findgen(idiff-1))/float(idiff)
     missbit=missbit*diff+data(idx1)
     imissbit=lindgen(idiff-1)+idx1+1
     data(imissbit)=missbit
     flags(imissbit)=flag+1
    endif
   endfor
endif
return
end

function faampara::GetData,flags=flags,maxflag=maxflag, $
             tstep=tstep,freq=freq,avg=avg,stretch=stretch, $
	     interpflag=interpflag,raw=raw
  
  d=*self.data
  f=*self.flags
  if(not(keyword_set(raw))) then begin
  if n_elements(tstep) eq 0 then tstep=1l
  if n_elements(freq) eq 0 then freq=1l
  tstep=long(tstep)
  freq=long(freq)
  if tstep LT 1l then tstep=1l
  if freq GT 1 and tstep GT 1 then begin
    print,'Incompatible keywords FREQ and TSTEP setting FREQ=1'
    freq=1
  endif
  nsecs=(self.stop-self.start)+1l
  insize=nsecs/tstep
  insize2=insize
  if insize*tstep ne nsecs then insize=insize+1

  insize=insize*freq
  insize2=insize2*freq
  
  indx=n_elements(d)
  rat1=float(freq)/(self.frequency*tstep)
  rat2=(self.frequency*tstep)/float(freq)
  if indx LT insize then begin
      if keyword_set(stretch) then $
           self->stretch,d,f,insize,rat1 $
            else self->spot1,d,f,insize,rat1
  endif
  if indx GT insize then begin
    if keyword_set(avg) then self->avg,d,f,insize,rat2 $
                        else self->spot2,d,f,insize,rat2
  endif
  if n_elements(interpflag) GT 0 then begin
    if interpflag LT 3 then self->interp,d,f,interpflag
  endif
  if((n_elements(maxflag) eq 0) and not(arg_present(flags)))then maxflag=0
  if n_elements(maxflag) GT 0 then begin
      i=where(f GT maxflag(0))
      if(i(0) GT -1) then d(i)=!VALUES.F_Nan
  endif
  endif
  flags=f
  return,d
end

pro faampara::get,start=start,stop=stop,_ref_extra=extra
  start=self.start
  stop=self.stop
  variable=self.variable
  self.variable->get,_extra=extra
return
end

function faampara::getvar,_ref_extra=extra
  self.variable->get,_extra=extra
  return,self.variable
end

pro faampara::cleanup

  ptr_free,self.data
  ptr_free,self.flags
return
end

pro faampara::setdata,D,flags=F,frequency=frequency
if(n_elements(d) GT 0) then begin
  dx=float(reform(D,n_elements(D)))
  if(ptr_valid(self.data)) then begin
    *self.data=dx 
    frequency=self.frequency
  endif else begin
    self.data=ptr_new(dx)
    if(n_elements(frequency) eq 0) then begin
      if(size(D,/n_dimensions) eq 1) then begin
        frequency=1
      endif else begin
        frequency=(size(D,/dimensions))[0]
      endelse
    endif
    nsec=n_elements(D)/frequency
    self.nsecs=nsec
    self.frequency=frequency
  endelse
endif
  if(ptr_valid(self.flags)) then begin
    if(n_elements(f) GT 0) then *self.flags=byte(reform(F,n_elements(self.flags)))
  endif else begin
    if(n_elements(f) EQ 0) then f=bytarr(n_elements(D))
    self.flags=ptr_new(byte(reform(F,n_elements(F))))
  endelse
return
end  

pro faampara__define

struct={faampara              $
        ,variable:obj_new()   $
        ,Data:ptr_new()       $
	,flags:ptr_new()      $
	,start:0l             $
	,stop:0l              $
	,nsecs:0l             $
	,frequency:0l         $
	,runname:''           $
	}
	
return
end
