; copied from /home/fp0100/tardis/tardis/mrf_idl/mrfread.pro
;FUNCTION MRFREAD ,DSN,IPARA, $
;                 RDATA,IFLAGS, $
;                 time=time, $
;                 start=start,stop=stop, $
;                 tstep=tstep,freq=freq, $
;                 fltno=fltno,date=date, $
;                 avg=avg,stretch=stretch, $
;                 interpflag=interpflag, $
;                 maxflag=maxflag, $
;                 pnames=pnames,vms=vms
;
;
;
;  IDL procedure to read in data for an NC, M2,M3,M4 or M5, file.
;
;  Inputs:
;           DSN            Dataset name and location (STRING)
;           IPARA          Parameter numbers to be checked (LONARR(*))
;
;  Outputs:
;           RDATA          Data output (FLTARR(Nº paras,Nº data points))
;           IFLAGS         Flags output (BYTARR(Nº paras,Nº data points))
;
;  Keyword inputs:
;
;           START          Start time of data in seconds past midnight (LONG)
;                          default start of data
;           STOP           End time of data in seconds past midnight (LONG)
;                          default end of data
;           TSTEP          Time to average data over or interval time
;                          between samples - in whole seconds 
;                          Maximum 1 hour or 3600s - default 1 (LONG)
;
;           FREQ           Frequency to output data at (1,2,4,8,16,32 or 64 Hz)
;                          Can't have both TSTEP and FREQ > 1 - default 1 (LONG)
;
;           AVG            If set averages data rather than taking spot values.
;           STRETCH        If set 'stretches' lower frequency. eg. data
;                          measured at 1Hz, with FREQ set to 32Hz will repeat
;                          each value 32 times.
;
;                          Default takes spot values
;
;           INTERPFLAG     Interpolates between data with flag LE INTERPFLAG
;
;
;
;
;  Keyword outputs:
;
;           FLTNO          Flight number (STRING)
;           DATE           Flight date (STRING)
;           TIME           Data times (FLTARR(Nº data points))
;           PNAMES         Parameter names (STRARR(3,Nº parameters))
;
;  Called routines:
;
;           FAAMFILE
;           MRFFILE
;
;    V2.00  D.Tiddeman  22-Aug-2008
;                       Functional calling of object routines to
;                       be compatible with old MRFREAD function.
;
;  CHANGES
;
;**************************************************************************

function mrfread ,DSN,IPARA, $
                 RDATA,IFLAGS, $
                 time=time, $
                 start=start,stop=stop, $
		 dataobject=dataobject, $
		 fltno=fltno,date=date, $
                 pnames=pnames,faamparas=faamparas,_extra=extra
  status=0
  e=strpos(strlowcase(dsn),'_data.dat')
  if e ne -1 then begin
    core=obj_new('mrffile',strmid(dsn,0,e))
  endif else begin
    f=file_search(dsn+'_data.dat')
    if(f[0] eq '') then f=file_search(dsn+'_DATA.DAT')
    if(f[0] NE '') then core=obj_new('mrffile',dsn) else $
      core=obj_new('faamfile',dsn)
  endelse
  if(obj_valid(core)) then begin
    core->mrfread,ipara,rdata,flags=iflags,start=start,stop=stop, $
                  pnames=pnames,faamparas=faamparas, $
		  fltno=fltno,date=date,_extra=extra
    if(arg_present(time)) then begin
      time=(core->getpara('time',start=start,stop=stop))->getdata(_extra=extra)
    endif
    if(arg_present(dataobject)) then $
      dataobject=core else $
      obj_destroy,core
    status=1
  endif
return,status

end
