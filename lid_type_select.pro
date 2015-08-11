function lid_type_select, type, accept


@lid_settings.include


n_acc = n_elements(accept)
if (n_acc EQ 0) then begin
	accept = replicate(1, ntypes)
endif else if (n_acc LT ntypes) then begin
	accept = [accept, intarr(ntypes-n_acc)]
endif else begin
	accept = accept[0:(ntypes-1)]
endelse


wrongtype = 0
if (n_elements(type) NE 1)  then type = _default_type_
if (size(type, /type) EQ 7) then begin
	i = 0
	while (i LT ntypes && ~strcmp(type, typename[i], /fold_case)) do ++i
endif else begin
	i = 0
	while (i LT ntypes && type NE i) do ++i
endelse

if (i LT ntypes && accept[i]) then type0 = i else wrongtype = 1


if (wrongtype) then begin
	type0 = _undef_
	msg = 'Unknown plot type. Use one of the following:'
	for i=0, ntypes-1 do if (accept[i]) then msg += ' ' + typename[i]
	message, msg
endif


return, type0


end

