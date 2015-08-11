function normalize, signal, mol, index, br

compile_opt strictarr, strictarrsubs

cnt  = n_elements(signal)
nidx = n_elements(index)

if (nidx NE 2) then begin
	if (nidx EQ 1) then index = [index[0], index[0]] $
	else if (nidx EQ 0) then index = [0, cnt-1] $
	else message2, '*** Index must have two elements ?!?'
endif

if n_elements(br) NE 1 then br = 0.0D

if (index[1] GT cnt-1 || index[0] GT index[1] || index[0] LT 0) then $
	message2, '*** Index inconsistency ?!?'

sign_mol_ratio = signal / mol
k_lidar = mean(sign_mol_ratio[index[0]:index[1]]) / (1.0D + br)

return, k_lidar

end

