function lid_layers_equal, x, y

compile_opt strictarr, strictarrsubs

ok   = (x.aerok EQ y.aerok)
pidx = array_equal(x.p_idx, y.p_idx)
pcal = (x.p_cal EQ y.p_cal)
fidx = array_equal(x.f_idx, y.f_idx)
fbr  = (x.f_br EQ y.f_br)
flr  = (x.f_lidratio EQ y.f_lidratio)
didx = array_equal(x.d_idx, y.d_idx)
dbr  = (x.d_br EQ y.d_br)
lsf  = (x.lsf EQ y.lsf)
lay  = array_equal(x.layer_idx, y.layer_idx)
ct   = array_equal(x.ct_idx, y.ct_idx)


return, (ok && pidx && pcal && fidx && fbr $
	&& flr && didx && dbr && lsf && lay && ct)

end
