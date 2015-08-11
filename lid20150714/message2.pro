pro message2, text, level=level, ioerror=ioerror, continue=continue, $
	informational=informational, noname=noname, noprefix=noprefix, $
	noprint=noprint, file_name=file_name, reset=reset


compile_opt strictarr, strictarrsubs

common __message2, fln, counter


if (n_elements(fln) NE 1) then fln = ''
if (n_elements(counter) NE 1) then counter = 0

something_done = 0

if (n_elements(file_name) EQ 1) then begin
	fln = file_name
	something_done = 1
endif

if (keyword_set(reset)) then begin
	if (fln NE '') then begin
		file_delete, fln, /quiet
		openw, fl, fln, /get_lun
		free_lun, fl
	endif
	counter = 0
	something_done = 1
endif


if (n_elements(text) NE 1 && something_done) then return


if (n_elements(level) NE 1) then level = 0
if (level LE 0) then --level

halting = ((~keyword_set(continue)) && (~keyword_set(informational)))

++counter

caldat, systime(/julian), mth, dd, yy, hh, mm, ss
date = string(dd, mth, yy MOD 100, hh, mm, ss, $
	format='(%"%2d/%02d/%02d %2d:%02d:%02d")')

scope = scope_traceback(/structure)
nscope = n_elements(scope)
if (nscope GE 2) then caller_scope = nscope-2 else caller_scope = nscope-1
caller_name = scope[caller_scope].routine

options = ''
if (halting) then options += 'H'
if (keyword_set(ioerror)) then options += 'O'
if (keyword_set(continue)) then options += 'C'
if (keyword_set(informational)) then options += 'I'
if (options NE '') then options = ',' + options

if (fln NE '') then begin
	openw, fl, fln, /append, /get_lun
	printf, fl, date, caller_name, text, counter, options, $
		format='(%"%-18s %s: %s (%d%s)")'
	if (halting) then for i=nscope-1, 0, -1 do $
		printf, fl, scope[i].routine,scope[i].line,scope[i].filename, $
			format='(%"   %-15s %6d %s")'
	free_lun, fl
endif

message, text, continue=continue, level=level, $
	informational=informational, ioerror=ioerror, noname=noname, $
	noprefix=noprefix, noprint=noprint


end

