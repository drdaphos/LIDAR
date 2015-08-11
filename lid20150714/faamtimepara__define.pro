; copied from /home/fp0100/tardis/tardis/mrf_idl/faamtimepara__define.pro
function faamtimepara::init,variable, $
			start,stop

self.variable=variable
self.start=start
self.stop=stop
return,1

end 


function faamtimepara::GetData,flags=flags,maxflag=maxflag, $
             tstep=tstep,freq=freq,avg=avg,stretch=stretch, $
	     interpflag=interpflag
     
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
  d=(((findgen(insize))/float(freq))*tstep)+self.start
  if keyword_set(avg) then d=d+float(tstep-1)/2.0
  x=(1+self.stop-self.start) mod tstep
  if x ne 0 then d(insize-1)=float(self.stop)-(float(x-1))/2.0
  f=bytarr(n_elements(d))
  flags=f
  return,d
end

pro faamtimepara::get,start=start,stop=stop,_ref_extra=extra
  start=self.start
  stop=self.stop
  self.variable->get,_extra=extra
return
end

function faamtimepara::getvar
  return,self.variable
end

pro faamtimepara__define

struct={faamtimepara   $
        ,variable:obj_new()   $
	,start:0l             $
	,stop:0l              $
	}
	
return
end
