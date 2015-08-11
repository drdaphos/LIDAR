pro lid_interactive, profnum, windowkeep=windowkeep, br_ref=br_ref


@lid_settings.include


common __lid_interactive, xran, xran_p, xran_a, xran_b, yran, viewtype, $
	show, p, slope, usebr;, adiacent

br_ref = keyword_set(br_ref)

openw, lgf, logfln, /get_lun, /append
printf, lgf, 'lid_interactive: starting'


if (n_elements(nprofiles) NE 1 || nprofiles LE 0L) then $
	message, 'No data. lid_data_read must be called first.'

if (view EQ _nadir_) then begin
	yran0 = [ymin, ceil(max(profinfo.alt)/1000.0D)*1000.0D]
endif else begin
	yran0 = [floor(min(profinfo.alt)/1000.0D)*1000.0D, ymax]
endelse

xran0 = [0.0D, 3000.0D]
xran_p0 = [0.0D, 0.2D]
xran_a0 = [-50.0D, 500.0D]
xran_b0 = [0.9D, 2.0D]
show0 = [1, 1]
wnum = 0
wnump = 2

_mol_ = 0
_aer_ = 1
_cld_ = 2

_p_none_     = -1
_p_depol_    = 0
_p_fern_al_  = 1
_p_digi_al_  = 2
_p_fern_br_  = 3
_p_digi_br_  = 4

if (n_elements(yran) NE 2)     then yran = yran0
if (n_elements(xran) NE 2)     then xran = xran0
if (n_elements(xran_p) NE 2)   then xran_p = xran_p0
if (n_elements(xran_a) NE 2)   then xran_a = xran_a0
if (n_elements(xran_b) NE 2)   then xran_b = xran_b0
if (n_elements(viewtype) NE 1) then viewtype = _mol_
if (n_elements(slope) NE 1)    then slope = 0
if (n_elements(adiacent) NE 1) then adiacent = 0
if (n_elements(usebr) NE 1)    then usebr = 0
if (n_elements(show) NE 2)     then show = show0
if (n_elements(profnum) EQ 1)  then p = profnum $
	else if (n_elements(p) NE 1) then p = 0
if (p LT 0 || p GE nprofiles)  then p = 0

zoomfact = 2.0D
normidx0 = [2*ovl, 1500]
charsize  = 1.5
;xsiz = 1024
;ysiz = 768
xsiz = 1200
ysiz = 900


; colors

c_pr2 = [5, 8]
c_pa  = [2, 1]
c_mol = [6, 16]
c_ok  = [2, 6]
c_ovl = 13
c_lsf = 9
c_osf = 15
c_std = 1
c_err = 2
c_active = [3, 23, 7, 22]
c_guess = 2
c_slope = [8, 5]


; plot axes geometry

xax  = [0.07, 0.70]
yax  = [0.07, 0.93]
marg = [0.05, 0.05]
xoffs = xax[1] + 0.02


; horizontal button alignment

xtit = xoffs + [0.00, 0.05]
xidx = xoffs + [0.06, 0.16]
xcal = xoffs + [0.17, 0.22]
xzer = xoffs + [0.23, 0.26]
xmid = [0.5*(xtit[0]+xzer[1]-0.01), 0.5*(xtit[0]+xzer[1]+0.01)]

xb1  = xoffs + [0.00, 0.10]
xb2  = xoffs + [0.11, 0.18]
xb3  = xoffs + [0.19, 0.26]

xlay = xoffs + [0.00, 0.13]
xlz  = xoffs + [0.135, 0.155]
xct  = xoffs + [0.17, 0.24]
xcz  = xoffs + [0.245, 0.265]

xguess = [0.45, 0.52, 0.53, 0.60]

; vertical button alignment

y_depth  = 0.04
y_sep    = 0.012	; 0.02
y_height = y_depth + y_sep
y_start1 = yax[1] + 0.06
y_start2 = 0.27

yok  = y_start1 - [y_depth, 0.0]
ydep = yok  - y_height
yfer = yok  - y_height*2.0
ydig = yok  - y_height*3.0
ylra = yok  - y_height*4.0
ysur = yok  - y_height*5.0
ybr  = yok  - y_height*6.0
ychn = y_start2 - [y_depth, 0.0]
yzoo = ychn - y_height
ypik = ychn - y_height*2.0
yqui = ychn - y_height*3.0
yusv = ychn - y_height*4.0

ylay0 = [ybr[0] - y_sep*1.5, y_start2+y_sep*1.5]
maxlay = min([fix((ylay0[0]-ylay0[1]) / y_height) - 1, max([nlayers,nclouds])])
y_start3 = mean(ylay0) + ((maxlay+1) * y_height - y_sep) / 2.0
ylaytit = y_start3 - [y_depth, 0.00]
ylay = fltarr(2,maxlay)
ylay[1,*] = ylaytit[0] - findgen(maxlay) * y_height
ylay[0,*] = ylay[1,*] - y_depth

yguess1 = 0.70 - [y_depth, 0.0]
yguess2 = yguess1 - y_height
yguess3 = yguess1 - y_height*2.0
yguess4 = yguess1 - y_height*3.0


; plot, text, and button boxes

plot_box = [xax[0], yax[0], xax[1], yax[1]]
tit_box  = [xax[0], yax[1], xax[1], yax[1]+marg[0]]
err_box  = [0.40, 0.62, 0.65, 0.70]

xmin_box = [xax[0], yax[0]-marg[0], xax[0]+marg[1], yax[0]]
xmax_box = [xax[1]-marg[1], yax[0]-marg[0], xax[1], yax[0]]
xran_box = [xmin_box[2], xmin_box[1], xmax_box[0], xmax_box[3]]
ymin_box = [xax[0]-marg[0], yax[0], xax[0], yax[0]+marg[1]]
ymax_box = [xax[0]-marg[0], yax[1]-marg[1], xax[0], yax[1]]
yran_box = [ymin_box[0], ymin_box[3], ymax_box[2], ymax_box[1]]

ok_box   = [xmid[1], yok[0], xzer[1], yok[1]]
ptit_box = [xtit[0], ydep[0], xtit[1], ydep[1]]
pidx_box = [xidx[0], ydep[0], xidx[1], ydep[1]]
pcal_box = [xcal[0], ydep[0], xcal[1], ydep[1]]
pzer_box = [xzer[0], ydep[0], xzer[1], ydep[1]]
ftit_box = [xtit[0], yfer[0], xtit[1], yfer[1]]
fidx_box = [xidx[0], yfer[0], xidx[1], yfer[1]]
fcal_box = [xcal[0], yfer[0], xcal[1], yfer[1]]
fzer_box = [xzer[0], yfer[0], xzer[1], yfer[1]]
dtit_box = [xtit[0], ydig[0], xtit[1], ydig[1]]
didx_box = [xidx[0], ydig[0], xidx[1], ydig[1]]
dcal_box = [xcal[0], ydig[0], xcal[1], ydig[1]]
dzer_box = [xzer[0], ydig[0], xzer[1], ydig[1]]
mol_box  = [xtit[0], ydig[0], xzer[1], ydep[1]]

lidr_box = [xtit[0], ylra[0], xmid[0], ylra[1]]
surf_box = [xtit[0], ysur[0], xmid[0], ysur[1]]
slopeset_box = [xmid[1], ylra[0], xzer[1], ylra[1]]
slop_box = [xmid[1], ysur[0], xzer[1], ysur[1]]
adia_box = [xtit[0], ybr[0],  xmid[0], ybr[1]]
br_box   = [xmid[1], ybr[0],  xzer[1], ybr[1]]

both_box = [xb1[0], ychn[0], xb1[1], ychn[1]]
chn0_box = [xb2[0], ychn[0], xb2[1], ychn[1]]
chn1_box = [xb3[0], ychn[0], xb3[1], ychn[1]]
def_box  = [xb1[0], yzoo[0], xb1[1], yzoo[1]]
zoomout_box = [xb2[0], yzoo[0], xb2[1], yzoo[1]]
zoomin_box  = [xb3[0], yzoo[0], xb3[1], yzoo[1]]
pick_box = [xb1[0], ypik[0], xb1[1], ypik[1]]
prev_box = [xb2[0], ypik[0], xb2[1], ypik[1]]
next_box = [xb3[0], ypik[0], xb3[1], ypik[1]]
gues_box = [xb1[0], yqui[0], xb1[1], yqui[1]]
save_box = [xb2[0], yqui[0], xb2[1], yqui[1]]
quit_box = [xb3[0], yqui[0], xb3[1], yqui[1]]
vran_box = [xb1[0]+0.01, yusv[0], xb2[1]-0.01, yusv[1]]
usav_box = [xb3[0], yusv[0], xb3[1], yusv[1]]
;usav_box = [xax[1]-marg[1],yax[0]-1.3*marg[0],xax[1],yax[0]-0.7*marg[0]]
;usav_box = [xb3[0], ychn[0]+1.5*y_depth, xb3[1], ychn[1]+1.5*y_depth]
;slop_box = [xb3[0]-0.01, yusv[0], xb3[1], yusv[1]]

ltit_box = [xlay[0], ylaytit[0], xlay[1], ylaytit[1]]
ctit_box = [xct[0],  ylaytit[0], xct[1],  ylaytit[1]]
lay_box = fltarr(4, 2, maxlay)
zer_box = fltarr(4, 2, maxlay)
for i=0, maxlay-1 do begin
	lay_box[*,0,i] = [xlay[0], ylay[0,i], xlay[1], ylay[1,i]]
	lay_box[*,1,i] = [xct[0],  ylay[0,i], xct[1],  ylay[1,i]]
	zer_box[*,0,i] = [xlz[0],  ylay[0,i], xlz[1],  ylay[1,i]]
	zer_box[*,1,i] = [xcz[0],  ylay[0,i], xcz[1],  ylay[1,i]]
endfor
--i
aer_box  = [xlay[0], ylay[0,i], xlz[1], ylaytit[1]]
cld_box  = [xct[0],  ylay[0,i], xcz[1],  ylaytit[1]]

gtit_box = [xguess[0], yguess1[0], xguess[3], yguess1[1]]
gdep_box = [xguess[0], yguess2[0], xguess[1], yguess2[1]]
gfer_box = [xguess[0], yguess3[0], xguess[1], yguess3[1]]
gdig_box = [xguess[0], yguess4[0], xguess[1], yguess4[1]]
gcld_box = [xguess[2], yguess2[0], xguess[3], yguess2[1]] 
gok_box  = [xguess[2], yguess3[0], xguess[3], yguess3[1]]
gall_box = [xguess[2], yguess4[0], xguess[3], yguess4[1]]

; display settings

if (!version.os_family EQ 'unix') then begin
	set_plot, 'x'
	arrow = 2
endif else begin
	set_plot, 'win'
	arrow = 32512
endelse
device, get_screen_size=screen
xsiz0 = min([0.85*screen[0], xsiz])
ysiz0 = min([0.85*screen[1], ysiz])
xpos0 = (screen[0] - xsiz0) / 2
ypos0 = (screen[1] - ysiz0) * 3 / 4

if (~keyword_set(windowkeep)) then $
	window, wnum, xsize=xsiz0, ysize=ysiz0, xpos=xpos0, ypos=ypos0, $
		title='Lidar Interactive'


; main loop

saved = 1
newfile = 0
oldxran = xran
oldyran = yran
repeat begin
    device, window_state=window_open
    if (window_open[wnump]) then wdelete, wnump
    pstate = _p_none_
    p0 = p
    normidx = normidx0
    newmol  = 0
    prof    = profile[p]
    pinfo   = profinfo[p]
    hgt     = prof.height
    mol     = [[prof.mol_pr2], [prof.mol_pr2]]
    lidpr2  = prof.pr2
    knorm   = mean(lidpr2[normidx[0]:normidx[1],0] $
              / lidpr2[normidx[0]:normidx[1],1], /nan)
    if (finite(knorm)) then lidpr2[*,1] *= knorm
    tit     = string(format='(%"%s (%d)")', pinfo.title, p)
;    print, tit
    replotviewwin = 1

    quit = 0
    repeat begin
        profinfo[p] = pinfo
        device, window_state=window_open
        if (replotviewwin) then $
            lid_preview_contour, pinfo.time, knorm=knorm, xran=xran, yran=yran
        replotviewwin = 0
        wset, wnum
        wshow, wnum
        !p.multi = 0
        col27
        if (newmol) then begin
            for ch=0, 1 do begin
                mnorm = mean(lidpr2[normidx[0]:normidx[1],ch] $
                    / mol[normidx[0]:normidx[1], ch], /nan)
                mol[*,ch] *= mnorm
            endfor
            newmol = 0
        endif
        c_dep = c_std
        c_fer = c_std
        c_dig = c_std
        c_aer = [c_std, c_std, c_std, c_std]
        c_ct  = [c_std, c_std, c_std, c_std]
        case viewtype of
            _mol_ : begin
                c_dep = c_active[0]
                c_fer = c_active[1]
                c_dig = c_active[2]
              end
            _aer_ : c_aer = c_active
            _cld_ : c_ct  = c_active
        endcase
        c_vran = [c_dep, c_fer, c_dig, c_fer, c_dig]
        plot, lidpr2[*,0], hgt, min_value=ymin, /xstyle, /ystyle, $
            xrange=xran, yrange=yran, charsize=charsize, $
            ytickformat='(i)', position=plot_box, /nodata
        oplot, xran, [pinfo.alt, pinfo.alt], color=c_ovl
        oplot, xran, [prof.height[ovl], prof.height[ovl]], color=c_ovl
        oplot, xran, [pinfo.lsf, pinfo.lsf], color=c_lsf, thick=2
        oplot, xran, [pinfo.osf, pinfo.osf], color=c_osf, thick=2
        for ch=1, 0, -1 do if (show[ch]) then $
            oplot, mol[*,ch], hgt, min_value=ymin, color=c_mol[ch]
        for ch=1, 0, -1 do if (show[ch]) then $
            oplot, lidpr2[*,ch], hgt, min_value=ymin, color=c_pr2[ch], $
                thick=2-ch
        p_def = (pinfo.p_idx[1] NE 0L AND pinfo.p_idx[1] GE pinfo.p_idx[0])
        f_def = (pinfo.f_idx[1] NE 0L AND pinfo.f_idx[1] GE pinfo.f_idx[0])
        d_def = (pinfo.d_idx[1] NE 0L AND pinfo.d_idx[1] GE pinfo.d_idx[0])
        l_def = (pinfo.layer_idx[1,*] NE 0L $
            AND pinfo.layer_idx[1,*] GE pinfo.layer_idx[0,*])
        c_def = (pinfo.ct_idx NE 0)
        ch_r = (show[0] ? 0 : 1)

        use_alph = (~br_ref)
        f_mol = 0.0D
        d_mol = 0.0D
        f_alph = -1.0D
        d_alph = -1.0D
        if (f_def) then f_mol = prof.mol_beta[mean([pinfo.f_idx])]
        if (d_def) then d_mol = prof.mol_beta[mean([pinfo.d_idx])]
        if (pinfo.f_br GT 0.0D) then $
            f_alph = 1D6 * (pinfo.f_br-1.0D) * pinfo.f_lidratio * f_mol
        if (pinfo.d_br GT 0.0D) then $
            d_alph = 1D6 * (pinfo.d_br-1.0D) * pinfo.f_lidratio * d_mol

        if (viewtype EQ _mol_ && p_def) then begin
            d1 = pinfo.p_idx[0]
            d2 = pinfo.p_idx[1]
            oplot, lidpr2[d1:d2,ch_r], hgt[d1:d2], color=c_dep, thick=2
        endif
        if (viewtype EQ _mol_ && f_def) then begin
            d1 = pinfo.f_idx[0]
            d2 = pinfo.f_idx[1]
            oplot, lidpr2[d1:d2,ch_r], hgt[d1:d2], color=c_fer, thick=2
        endif
        if (viewtype EQ _mol_ && d_def) then begin
            d1 = pinfo.d_idx[0]
            d2 = pinfo.d_idx[1]
            oplot, lidpr2[d1:d2,ch_r], hgt[d1:d2], color=c_dig, thick=2
        endif
        if (viewtype EQ _aer_) then begin
            for i=0, nlayers-1 do if (l_def[i]) then begin
               lhgt = prof.height[pinfo.layer_idx[*,i]]
               oplot, xran, [lhgt[0], lhgt[0]], color=c_aer[i]
               oplot, xran, [lhgt[1], lhgt[1]], color=c_aer[i]
              endif
        endif else if (viewtype EQ _cld_) then begin
            for i=0, nclouds-1 do if (c_def[i]) then begin
               chgt = prof.height[pinfo.ct_idx[i]]
               oplot, xran, [chgt, chgt], color=c_ct[i]
              endif
        endif
        idx_h = pinfo.pa_idx
        for ch=1, 0, -1 do if (show[ch] && idx_h[ch] GT 0) then $
            oplot, [lidpr2[idx_h[ch], ch]], [prof.height[idx_h[ch]]], $
                psym=1, symsize=2.5, color=c_pa[ch], thick=3

        xran_a_s = string(xran_a, format='(%"%0.1f-%0.1f")')
        xran_b_s = string(xran_b, format='(%"%0.2f-%0.2f")')
        xran_p_s = string(xran_p, format='(%"%0.2f-%0.2f")')
            

        textbox, tit_box, tit, /nobox
        textbox, ok_box, (pinfo.aerok ? 'ACCEPTED' : 'REJECTED'), $
            color=c_ok[pinfo.aerok], charsize=2

        textbox, ptit_box, 'Depol', color=c_dep
        textbox, pidx_box, string(format='(%"%d-%d")', $
            (p_def ? round(ascending(prof.height[pinfo.p_idx])) : [0,0])), $
            color=c_dep
        textbox, pcal_box, string(format='(%"%7.5f")', pinfo.p_cal), $
            color=c_dep, charsize=1.2
        textbox, pzer_box, 'X', color=c_dep

        textbox, ftit_box, 'Fern', color=c_fer
        textbox, fidx_box, string(format='(%"%d-%d")', $
            (f_def ? round(ascending(prof.height[pinfo.f_idx])) : [0,0])), $
            color=c_fer
        br_txt = (br_ref ? string(format='(%"%5.3f")', pinfo.f_br) $
            : string(format='(%"%d")', round(f_alph)))
        textbox, fcal_box, br_txt, color=c_fer
        textbox, fzer_box, 'X', color=c_fer

        textbox, dtit_box, 'Digi', color=c_dig
        textbox, didx_box, string(format='(%"%d-%d")', $
            (d_def ? round(ascending(prof.height[pinfo.d_idx])) : [0,0])), $
            color=c_dig
        br_txt = (br_ref ? string(format='(%"%5.3f")', pinfo.d_br) $
            : string(format='(%"%d")', round(d_alph)))
        textbox, dcal_box, br_txt, color=c_dig
        textbox, dzer_box, 'X', color=c_dig

        textbox, lidr_box, string(format='(%"LidRatio: %5.1f")', $
            pinfo.f_lidratio)
        textbox, surf_box, string(format='(%"Surface: %d")', $
            pinfo.lsf GE ymin ? round(pinfo.lsf) : -999), color=c_lsf
        textbox, slopeset_box, 'Slope-set'

        textbox, ltit_box, 'AEROSOL LAYERS', /nobox
        textbox, ctit_box, 'CLOUD ' + (view EQ _nadir_ ? 'TOPS' : 'BASES'), $
            /nobox
        for i=0, maxlay-1 do begin
            if (i LT nlayers) then begin
                textbox, lay_box[*,0,i], color=c_aer[i], /left, $
                    string(format='(%"%2d)%5d-%d")', i, (l_def[i] ? $
                    round(ascending(prof.height[pinfo.layer_idx[*,i]])):[0,0]))
                textbox, zer_box[*,0,i], 'X', color=c_aer[i]
            endif
            if (i LT nclouds) then begin
                textbox, lay_box[*,1,i], color=c_ct[i], /left, $
                    string(format='(%"%2d)%5d")', i, $
                    (c_def[i] ? round(prof.height[pinfo.ct_idx[i]]) : 0))
                textbox, zer_box[*,1,i], 'X', color=c_ct[i]
            endif
        endfor

        textbox, both_box, 'Both Ch'
        textbox, chn0_box, 'Ch0', color=c_pr2[0]
        textbox, chn1_box, 'Ch1', color=c_pr2[1]
        textbox, def_box,  'Deft View'
        textbox, zoomout_box, '-'
        textbox, zoomin_box,  '+'
        textbox, pick_box, 'Pick Prof'
        textbox, prev_box, 'Prev'
        textbox, next_box, 'Next'
        textbox, gues_box, 'Guess'
        textbox, save_box, 'Save'
        textbox, quit_box, 'Quit'
        if (~saved) then textbox, usav_box, 'UNSAVED', color=c_err, /nobox
        if (pstate NE _p_none_ && window_open[wnump]) then begin
            if (pstate EQ _p_depol_) then begin
                xranstr = xran_p_s
            endif else if (pstate EQ _p_fern_al_ $
              || pstate EQ _p_digi_al_) then begin
                xranstr = xran_a_s
            endif else begin
                xranstr = xran_b_s
            endelse
            textbox, vran_box, color=c_vran[pstate], xranstr
            if (pstate EQ _p_fern_al_ || pstate EQ _p_fern_br_) then $
                textbox, adia_box, color=c_slope[adiacent], $
                    (adiacent ? 'Hide' : 'Show') + ' Adiacent'
            if (pstate NE _p_depol_) then begin
                textbox, slop_box, color=c_slope[slope], $
                    'Slope ' + (slope ? 'hide' : 'show')
                textbox, br_box, color=c_slope[usebr], $
                    'Plot ' + (usebr ? 'Ext' : 'BR')
            endif
        endif

        repeat begin
            wset, wnum
            graphcenter = [mean(xran), mean(yran)]
            device, cursor_standard=arrow
            repeat begin
                cursor, xcur, ycur, /normal, wait=3, /change
                datacoord = convert_coord(xcur, ycur, /normal, /to_data)
                xdata = datacoord[0]
                ydata = datacoord[1]
                changecenter = in_box(xcur, ycur, plot_box)
                if (changecenter) then graphcenter = datacoord
            endrep until (~changecenter)
            pressed = 1
            xhalfsize = 0.5 * (xran[1] - xran[0]) * [-1.0, 1.0]
            yhalfsize = 0.5 * (yran[1] - yran[0]) * [-1.0, 1.0]
            oldinfo = pinfo
            altbox=[[pidx_box], [fidx_box], [didx_box]]
            altran=[[pinfo.p_idx], [pinfo.f_idx], [pinfo.d_idx]]


            case 1 of
                in_box(xcur, ycur, xmin_box): $
                    xran[0] = get_input('X-min', xran[0], box=err_box)
                in_box(xcur, ycur, xmax_box): $
                    xran[1] = get_input('X-max', xran[1], box=err_box)
                in_box(xcur, ycur, ymin_box): $
                    yran[0] = get_input('Y-min', yran[0], box=err_box)
                in_box(xcur, ycur, ymax_box): $
                    yran[1] = get_input('Y-max', yran[1], box=err_box)
                in_box(xcur, ycur, xran_box): $
                    if (abs(xdata-xran[0]) LE abs(xdata-xran[1])) $
                        then xran[0] = xdata else xran[1] = xdata
                in_box(xcur, ycur, yran_box): $
                    if (abs(ydata-yran[0]) LE abs(ydata-yran[1])) $
                        then yran[0] = ydata else yran[1] = ydata

                in_box(xcur, ycur, ok_box): $
                    pinfo.aerok = ~ pinfo.aerok
                in_box(xcur, ycur, lidr_box) : $
                    pinfo.f_lidratio = get_input('Lidar Ratio', $
                        pinfo.f_lidratio, box=err_box)
                in_box(xcur, ycur, slopeset_box): begin
                        lid_layers_slopeset, p, lgf, verbose=0
                        pinfo = profinfo[p]
                        use_alph = 0
                end
                
                in_box(xcur, ycur, surf_box) : $
                    pinfo.lsf = prof.height[get_range(hgt, lidpr2[*,ch_r], $
                        'Surface Altitude', chan=ch_r, box=err_box, /one)]

                in_box(xcur, ycur, mol_box) : begin
                    viewtype = _mol_
                    case 1 of
                        in_box(xcur, ycur, ptit_box): if (p_def) then begin
                            normidx = pinfo.p_idx
                            newmol = 1
                            lid_preview_processed, p, _totdep_, $
                                xran=xran_p, yran=yran
                            pstate = _p_depol_
                          endif
                        in_box(xcur, ycur, pidx_box): begin
                            pinfo.p_idx = get_range(hgt,lidpr2[*,ch_r], $
                                'Depol', chan=ch_r, box=err_box, $
                                altbox=altbox, altran=altran)
                            if (~array_equal(pinfo.p_idx, oldinfo.p_idx) $
                                && pinfo.p_cal EQ 0.0D) then $
                                    pinfo.p_cal = default_caldr
                          end
                        in_box(xcur, ycur, pcal_box): $
                            pinfo.p_cal = get_input('Depol ref', $
                                pinfo.p_cal, box=err_box, format='%8.5f')
                        in_box(xcur, ycur, pzer_box): begin
                            pinfo.p_idx = [0L, 0L]
                            pinfo.p_cal = 0.0D
                          end
                        in_box(xcur, ycur, ftit_box): if (f_def) then begin
                            normidx = pinfo.f_idx
                            newmol = 1
                            lid_preview_processed, p, $
                                (usebr ? _bratio_ : _extinc_), _fern_, $
                                xran = (usebr ? xran_b : xran_a), $
                                yran=yran, slope_method=slope, $
                                show_adiacent=adiacent
                            pstate = (usebr ? _p_fern_br_ : _p_fern_al_)
                          endif
                        in_box(xcur, ycur, fidx_box): begin
                            pinfo.f_idx=get_range(hgt,lidpr2[*,ch_r], $
                                'Fernald', chan=ch_r, box=err_box, $
                                altbox=altbox, altran=altran)
                            if (~array_equal(pinfo.f_idx, oldinfo.f_idx) $
                                 && pinfo.f_br EQ 0.0D) then begin
                                    pinfo.f_br = default_f_ref
                                    f_alph = default_f_alph
                            endif
                          end
                        in_box(xcur, ycur, fcal_box): $
                            if (br_ref) then begin
                                pinfo.f_br = get_input('Fernald BR ref', $
                                    pinfo.f_br, box=err_box)
                            endif else begin
                               f_alph = get_input('Fernald Extinction ' $
                                    + 'ref (Mm-1)', f_alph, box=err_box)
                            endelse
                        in_box(xcur, ycur, fzer_box): begin
                            pinfo.f_idx = [0L, 0L]
                            pinfo.f_br = 0.0D
                            f_alph = -1.0D
                          end
                        in_box(xcur, ycur, dtit_box): if (d_def) then begin
                            normidx = pinfo.d_idx
                            newmol = 1
                            lid_preview_processed, p, $
                                (usebr ? _bratio_ : _extinc_), _digi_, $
                                xran = (usebr ? xran_b : xran_a), $
                                yran=yran, slope_method=slope
                            pstate = (usebr ? _p_digi_br_ : _p_digi_al_)
                          endif
                        in_box(xcur, ycur, didx_box): begin
                            pinfo.d_idx = get_range(hgt, lidpr2[*,ch_r], $
                                'Digi', chan=ch_r, box=err_box, $
                                altbox=altbox, altran=altran)
                            if (~array_equal(pinfo.d_idx, oldinfo.d_idx) $
                                && pinfo.d_br EQ 0.0D) then begin
                                    pinfo.d_br = default_d_ref
                                    d_alph = default_d_alph
                            endif
                          end
                        in_box(xcur, ycur, dcal_box): $
                            if (br_ref) then begin
                                pinfo.d_br = get_input('Digi BR ref', $
                                    pinfo.d_br, box=err_box)
                            endif else begin
                                d_alph = get_input('Digi Extinction ' $
                                    + 'ref (Mm-1)', d_alph, box=err_box)
                            endelse
                        in_box(xcur, ycur, dzer_box): begin
                            pinfo.d_idx = [0L, 0L]
                            pinfo.d_br = 0.0D
                            d_alph = -1.0D
                          end
                        else:
                    endcase
                end

                in_box(xcur, ycur, aer_box) : begin
                    viewtype = _aer_
                    for i=0, min([nlayers,maxlay])-1 do $
                        if in_box(xcur, ycur, lay_box[*,0,i]) then begin
                            pinfo.layer_idx[*,i] = get_range(hgt, $
                                lidpr2[*,ch_r], string(format='(%"Layer %d")', $
                                i), chan=ch_r, box=err_box)
                            break
                        endif else if in_box(xcur, ycur, zer_box[*,0,i]) $
                          then begin
                            pinfo.layer_idx[*,i] = 0L
                            break
                        endif
                end

                in_box(xcur, ycur, cld_box) : begin
                    viewtype = _cld_
                    for i=0, min([nclouds,maxlay])-1 do $
                        if in_box(xcur, ycur, lay_box[*,1,i]) then begin
                            pinfo.ct_idx[i] = get_range(hgt, lidpr2[*,ch_r],$
                                string(format='(%"Cloud %d level")', i), $
                                chan=ch_r, box=err_box, /one)
                            break
                        endif else if in_box(xcur, ycur, zer_box[*,1,i]) $
                          then begin
                            pinfo.ct_idx[i] = 0L
                            break
                        endif
                end

                in_box(xcur, ycur, both_box) : show = [1, 1]
                in_box(xcur, ycur, chn0_box) : show = [1, 0]
                in_box(xcur, ycur, chn1_box) : show = [0, 1]
                in_box(xcur, ycur, def_box)  : begin
                    xran = xran0
                    yran = yran0
                    show = show0
                  end
                in_box(xcur, ycur, zoomout_box) : begin
                    xran = graphcenter[0] + xhalfsize * zoomfact
                    yran = graphcenter[1] + yhalfsize * zoomfact
;                    xran = 1.5 * xran - 0.5 * reverse(xran)
;                    yran = 1.5 * yran - 0.5 * reverse(yran)
                  end
                in_box(xcur, ycur, zoomin_box) : begin
                    xran = graphcenter[0] + xhalfsize / zoomfact
                    yran = graphcenter[1] + yhalfsize / zoomfact
;                    xran = 0.75 * xran + 0.25 * reverse(xran)
;                    yran = 0.75 * yran + 0.25 * reverse(yran)
                  end
                in_box(xcur, ycur, pick_box): $
                    p = get_input('Profile number', p, box=err_box, $
                        time=profinfo.start)
                in_box(xcur, ycur, prev_box): --p
                in_box(xcur, ycur, next_box): ++p
                in_box(xcur, ycur, gues_box): begin
                    textbox, gtit_box, 'Guess what?', $
                       /nobox, left=0, color=c_guess
                    textbox, gdep_box, 'Depol', color=c_guess
                    textbox, gfer_box, 'Fern', color=c_guess
                    textbox, gdig_box, 'Digi', color=c_guess
                    textbox, gcld_box, 'Clouds', color=c_guess
                    textbox, gok_box, 'Acc/Rej', color=c_guess
                    textbox, gall_box, 'ALL', color=c_guess
                    repeat begin
                       cursor, xcur, ycur, /normal, wait=3, /change
                       guess_specified = 1
                       guessdep = 0
                       guessfer = 0
                       guessdig = 0
                       guesscld = 0
                       guessok  = 0
                       case 1 of
                          in_box(xcur, ycur, gdep_box): guessdep = 1
                          in_box(xcur, ycur, gfer_box): guessfer = 1
                          in_box(xcur, ycur, gdig_box): guessdig = 1
                          in_box(xcur, ycur, gcld_box): guesscld = 1
                          in_box(xcur, ycur, gok_box):  guessok  = 1
                          in_box(xcur, ycur, gall_box): 
                          else: guess_specified = 0
                       endcase
                    endrep until guess_specified
                    lid_layers_guess, p, lgf, depol=guessdep, fernald=guessfer,$
                       digi=guessdig, clouds=guesscld, aerok=guessok
                    pinfo  = profinfo[p]
                    use_alph = 0
                  end
                in_box(xcur, ycur, vran_box): $
                    if (pstate NE _p_none_ && window_open[wnump]) then begin
                        if (pstate EQ _p_depol_) then begin
                            xran_p = get_input('Depol axis', xran_p, /range)
                        endif else if (pstate EQ _p_fern_al_ $
                          || pstate EQ _p_digi_al_) then begin
                            xran_a = get_input('Ext axis', xran_a, /range)
                        endif else begin
                            xran_b = get_input('BR axis', xran_b, /range)
                        endelse
                    endif
                in_box(xcur, ycur, adia_box): $
                    if ((pstate EQ _p_fern_al_ || pstate EQ _p_fern_br_) $
                    && window_open[wnump]) then adiacent = ~adiacent
                in_box(xcur, ycur, slop_box): $
                    if (pstate NE _p_none_ && pstate NE _p_depol_ $
                      && window_open[wnump]) then slope = ~slope
                in_box(xcur, ycur, br_box): $
                    if (pstate NE _p_none_ && pstate NE _p_depol_ $
                      && window_open[wnump]) then usebr = ~usebr
                in_box(xcur, ycur, save_box): begin
                    lid_layers_save, lgf, verbose=0
                    if (~saved) then newfile = 1
                    saved = 1
                  end
                in_box(xcur, ycur, quit_box): if (saved) then begin
                    quit = 1
                  endif else begin
                    textbox, err_box, 'Save first!', charsize=2, color=c_err
                    wait, 0.7
                  endelse
                else: pressed = 0
            endcase
            saved AND= lid_layers_equal(pinfo, oldinfo)
        endrep until (pressed)
        if (use_alph) then begin
            if (pinfo.f_lidratio EQ 0.0D) then pinfo.f_lidratio = default_lr
            f_def = (pinfo.f_idx[1] NE 0L AND pinfo.f_idx[1] GE pinfo.f_idx[0])
            d_def = (pinfo.d_idx[1] NE 0L AND pinfo.d_idx[1] GE pinfo.d_idx[0])
            if (f_def) then f_mol = prof.mol_beta[mean([pinfo.f_idx])]
            if (d_def) then d_mol = prof.mol_beta[mean([pinfo.d_idx])]
            pinfo.f_br = (f_alph GE 0.0D $
                ? 1.0D + 1D-6 * f_alph / (pinfo.f_lidratio * f_mol) : 0.0D)
            pinfo.d_br = (d_alph GE 0.0D $
                ? 1.0D + 1D-6 * d_alph / (pinfo.f_lidratio * d_mol) : 0.0D)
        endif
        saved AND= lid_layers_equal(pinfo, oldinfo)
        p = max([p, 0])
        p = min([p, nprofiles-1])
        replotviewwin = ~(array_equal(xran, oldxran) $
            && array_equal(yran, oldyran))
        oldxran = xran
        oldyran = yran
        flush, lgf
    endrep until (quit || p NE p0)
endrep until (quit)

if (newfile) then begin
	print, 'REMEMBER TO COPY THE LAYERS FILE TO ' + info_path
	textbox, err_box, 'You must copy the file!', charsize=2, color=c_err
endif else begin
	textbox, err_box, 'Quit', charsize=2, color=c_err
endelse


printf, lgf, 'lid_interactive: quitting'
free_lun, lgf


end
