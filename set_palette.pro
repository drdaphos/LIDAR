;SET_PALETTE
;set a colour palette for contour plots + a discrete palette
;this procedure was originally written for allowing the Lidardisplay viewer
;to permit interactive changes of the colour palette at run-time
;uses IDL (not TIDL)
;
;by Franco Marenco
;please report any bugs and/or your modifications to me :-)
;
;this routine sets a colour palette with the following specifications:
;the new colour palette (suitable for contour plots) is set from colours
;bottom to top; bottom and top vary from palette to palette
;colours 0 to bottom-1 are set according to the col27.pro routine
;this enables to have some discrete colours handy in addition to the
;colour palette which is used for contours; colour 255 is set to white
;guaranteed discrete colours are: black (0), white (1,255), red (2),
;green (3), darkish blue (4), yellow (4), cyan (6), and magenta (7)
;
;this routine assumes a total of 256 colours (0-255)
;note: some of these palettes rely on IDL loadct colour tables;
;please note that in TIDL/WAVEON they are different from IDL and
;you would get wrong results or error messages.
;you must be in pure IDL for this routine to work properly
;
;sample contour plotting code:
;  set_palette, 3, bottom=bottom, top=top, maxlevs=maxlevs
;  variable = dist(200)
;  range = [0, 150]
;  nlevs = min([maxlevs, 32])
;  levs = range[0] + (range[1]-range[0]) * dindgen(nlevs)/(nlevs-1.0D)
;  cols = bottom + bytscl(indgen(nlevs), top=top-bottom)
;  contour, variable, levels=levs, c_colors=cols, /cell_fill, $
;      position=[0.1,0.1,0.8,0.9]
;  colorbar, range=range, bottom=bottom, ncolors = top-bottom+1, $
;      position=[0.9,0.2,0.95,0.8], /vertical
;
;input:   palette: the palette number; if negative then loadct, -palette-1 is
;         called, but with bottom=8 and top=254
;input:   filename: load WAVE colour table using restore_colours
;         you need a modified restore_colours able to work in pure IDL
;         palette is ignored when filename is specified, and bottom=8, top=254
;
;output:  bottom: returns bottom for the chosen palette (8 or larger)
;output:  top: returns top for the chosen palette (254 or smaller)
;output:  maxlevs: the maximum number of levels to use when calling 'contour'
;         this is important because some palettes only have a small discrete
;         number of different colours
;output:  get_names: if present in the procedure call, returns an array with
;         the names of the available palettes; the colour table is not changed
;
;keyword: show_sample: if set, plot the available palettes and exit;
;         if show_sample=2 use postscript (Unix only)
;keyword: time_save: exit if the same colour table had already been requested
;         in the previous call; you could end up with wrong results if the
;         colour table was modified by a different program than set_palette
;keyword: verbose: if set, print a message after changing the palette



pro set_palette, palette, filename=filename, bottom=bottom, top=top, $
	maxlevs=maxlevs, get_names=names, show_sample=show_sample, $
	time_save=time_save, verbose=verbose


compile_opt strictarr, strictarrsubs

common __set_palette, old_palette, old_filename, $
	old_bottom, old_top, old_maxlevs


names = ['Rainbow', 'Blue-Red', 'Kate''s original', 'Kate''s half', $
	'Kate''s continuous', 'Discrete-1', 'Discrete-2', $
	'Blue-Yellow', 'Purple-Yellow', 'Green-1', 'Green-2']
n_names = n_elements(names)
n_filename = n_elements(filename)

if (arg_present(names)) then return

if (n_elements(verbose) NE 1)  then verbose=0
if (n_elements(palette) NE 1)  then palette = 0

tvlct, old_ct, /get

if (keyword_set(show_sample)) then begin
	thick = 1
	if (show_sample GE 2) then begin
		psfln = '/tmp/set_palette.ps'
		set_plot, 'ps'
		device, /color, bits_per_pixel=8, filename=psfln, $
			xoffset=0.5, yoffset=1, xsize=20, ysize=27.5
		thick = 3
	endif
	erase
	for i=0, n_names + n_filename - 1 do begin
		if (i LT n_names) then begin
			set_palette, i, bottom=bottom, top=top, maxlevs=maxlevs
			info_str = string(i, names[i], maxlevs, $
				format='(%"%2d) %s (%d levels)")')
		endif else begin
			set_palette, filename=filename[i-n_names], $
				bottom=bottom, top=top, maxlevs=maxlevs
			info_str = string(filename[i-n_names], maxlevs, $
				format='(%"''%s'' (%d levels)")')
		endelse
		y = 0.94-i*0.05
		colorbar, bottom=bottom, ncolors = top-bottom+1, $
			range=[bottom, top], divisions=1, minor=0, $
			position=[0.05,y-0.01,0.55,y+0.01], $
			linethick=thick, charthick=thick, charsize=0.7
		xyouts, 0.6, y-0.003, /normal, charthick=thick, charsize=1, $
			info_str
	endfor
	if (show_sample GE 2) then begin
		device, /close_file
		set_plot, 'x'
		spawn, 'gv ' + psfln + ' &'
	endif
	tvlct, old_ct
	return
endif


if (n_filename NE 1) then filename = ''

if (keyword_set(time_save) && n_elements(old_palette) EQ 1 $
   && filename EQ old_filename && (n_filename EQ 1 || palette EQ old_palette)) $
	then begin
		bottom  = old_bottom
		top     = old_top
		maxlevs = old_maxlevs
		return
endif

maxlevs = 0


if (n_filename EQ 1 && filename NE '') then begin
	restore_colours, filename, silent=~verbose
	bottom = 8
	top = 254
	goto, final_statements
endif




case palette of
	0:	begin			; rainbow
			loadct, 39, /silent
			bottom = 15
			top = 254
		end

	1:	begin			; blue-red
			loadct, 33, /silent
			bottom = 15
			top = 254
		end
	2:	begin			; Kate's discrete rainbow (28 colours)
			bottom=32
			top = 59
			red=[64,83,86,66,0,0,0,0,0,0,115,190, $
				0,0,0,0,120,185,210,230,255,$
				255,255,255,255,255,255,155,75,30]
			green=[0,0,0,0,0,89,131,150,174,190,200,230, $
				255,255,255,255,255,255,255,255,255,$
				220,190,165,135,80,0,0,0,0]
			blue=[68,120,145,209,255,255,255,255,255,255,255,255, $
				255,216,170,135,0,0,0,0,0,$
				0,0,0,0,0,0,0,0,0]
			tvlct, red, green, blue, bottom
		end

	3:	begin			; a variant on Kate's (14 colours)
			bottom=32
			top = 45
;			red=[94,66,0,0,0,190,47,0,161,250,217,252,254,155]
;			green=[10,0,89,150,190,230,207,255,255,255,175,121,0,0]
;			blue=[109,209,255,255,255,255,182,135,0,0,25,0,0,0]
			red=[170,66,0,0,0,190,47,0,161,250,217,252,254,155]
			green=[154,0,89,150,190,230,207,255,255,255,175,121,0,0]
			blue=[210,209,255,255,255,255,182,135,0,0,25,0,0,0]
			tvlct, red, green, blue, bottom
		end

	4:	begin			; a variant on Kate's (interpolated)
			bottom = 31
			top = 254
;			red = [106,104,102,101,99,97,95,94, $
;				92,90,88,87,85,83,81,80, $
;				78,76,74,73,71,69,67,66, $
			red = [215,209,202,196,189,183,176,170, $
				163,157,150,144,137,131,124,118, $
				111,105,98,92,85,79,72,66, $
				61,57,53,49,45,41,37,33, $
				28,24,20,16,12,8,4,0, $
				0,0,0,0,0,0,0,0, $
				0,0,0,0,0,0,0,0, $
				0,0,0,0,0,0,0,0, $
				0,0,0,0,0,0,0,0, $
				11,23,35,47,59,71,83,95, $
				106,118,130,142,154,166,178,190, $
				181,172,163,154,145,136,127,118, $
				109,100,91,82,73,64,55,47, $
				44,41,38,35,32,29,26,23, $
				20,17,14,11,8,5,2,0, $
				10,20,30,40,50,60,70,80, $
				90,100,110,120,130,140,150,161, $
				166,172,177,183,188,194,199,205, $
				211,216,222,227,233,238,244,250, $
				247,245,243,241,239,237,235,233, $
				231,229,227,225,223,221,219,217, $
				219,221,223,225,227,230,232,234, $
				236,238,241,243,245,247,249,252, $
				252,252,252,252,252,252,252,253, $
				253,253,253,253,253,253,253,254, $
				247,241,235,229,223,216,210,204, $
				198,192,185,179,173,167,161,155, $
				148,142,136,130,124,118,111,105]
;			green = [14,13,13,12,11,11,10,10, $
;				9,8,8,7,6,6,5,5, $
;				4,3,3,2,1,1,0,0, $
			green = [221,211,202,192,183,173,163,154, $
				144,134,125,115,105,96,86,77, $
				67,57,48,38,28,19,9,0, $
				5,11,16,22,27,33,38,44, $
				50,55,61,66,72,77,83,89, $
				92,96,100,104,108,111,115,119, $
				123,127,130,134,138,142,146,150, $
				152,155,157,160,162,165,167,170, $
				172,175,177,180,182,185,187,190, $
				192,195,197,200,202,205,207,210, $
				212,215,217,220,222,225,227,230, $
				228,227,225,224,222,221,219,218, $
				217,215,214,212,211,209,208,207, $
				210,213,216,219,222,225,228,231, $
				234,237,240,243,246,249,252,255, $
				255,255,255,255,255,255,255,255, $
				255,255,255,255,255,255,255,255, $
				255,255,255,255,255,255,255,255, $
				255,255,255,255,255,255,255,255, $
				250,245,240,235,230,225,220,215, $
				210,205,200,195,190,185,180,175, $
				171,168,164,161,158,154,151,148, $
				144,141,137,134,131,127,124,121, $
				113,105,98,90,83,75,68,60, $
				52,45,37,30,22,15,7,0, $
				0,0,0,0,0,0,0,0, $
				0,0,0,0,0,0,0,0, $
				0,0,0,0,0,0,0,0]
;			blue = [65,71,77,84,90,96,102,109, $
;				115,121,127,134,140,146,152,159, $
;				165,171,177,184,190,196,202,209, $
			blue = [209,209,209,209,209,209,209,210, $
				209,209,209,209,209,209,209,209, $
				209,209,209,209,209,209,209,209, $
				211,214,217,220,223,226,229,232, $
				234,237,240,243,246,249,252,255, $
				255,255,255,255,255,255,255,255, $
				255,255,255,255,255,255,255,255, $
				255,255,255,255,255,255,255,255, $
				255,255,255,255,255,255,255,255, $
				255,255,255,255,255,255,255,255, $
				255,255,255,255,255,255,255,255, $
				250,245,241,236,232,227,223,218, $
				213,209,204,200,195,191,186,182, $
				179,176,173,170,167,164,161,158, $
				155,152,149,146,143,140,137,135, $
				126,118,109,101,92,84,75,67, $
				59,50,42,33,25,16,8,0, $
				0,0,0,0,0,0,0,0, $
				0,0,0,0,0,0,0,0, $
				1,3,4,6,7,9,10,12, $
				14,15,17,18,20,21,23,25, $
				23,21,20,18,17,15,14,12, $
				10,9,7,6,4,3,1,0, $
				0,0,0,0,0,0,0,0, $
				0,0,0,0,0,0,0,0, $
				0,0,0,0,0,0,0,0, $
				0,0,0,0,0,0,0,0, $
				0,0,0,0,0,0,0,0]
			tvlct, red, green, blue, bottom
		end

	5:	begin			; discrete (14 colours)
			loadct, 38, /silent
			bottom = 32
			top = 254
			maxlevs = 14
			for i=32,47 do tvlct, 150, 0, 150, i
			for i=48,63 do tvlct, 100, 100, 150, i
			for i=240,254 do tvlct, 125, 50, 50, i
		end

	6:	begin			; discrete (8 colours)
			bottom = 32
			top = 39
			red   = [ 35, 95,140, 65, 90,220,220,215]
			green = [ 35,110,215,126,175,220,130, 40]
			blue  = [170,190,215, 85, 45, 30, 30, 40]
			tvlct, red, green, blue, bottom
		end

	7:	begin			; blue-yellow, self-made
			bottom = 15
			top = 254
			nlevs = top - bottom + 1
			x1 = findgen(nlevs) / nlevs
			x2 = findgen(nlevs/2) * 2 / nlevs
			x3 = findgen(nlevs/4) * 4 / nlevs
			h = [240. - 70. * x2, 170. - 65. * x3, 105. - 45 * x3]
			l = 0.05 + 0.60 * x1
			s = [0.65 - 0.50 * x2, 0.15 + 0.50 * x2]
			tvlct, h, l, s, bottom, /hls
			tvlct, 255, 255, 0, top
		end

	8:	begin			; purple-yellow, or "haze"
			loadct, 16, /silent
			bottom = 16
			top = 239
			tvlct, 255, 255, 0, top
		end

	9:	begin			; green, linear
			loadct, 8, /silent
			bottom = 16
			top = 239
			tvlct, 255, 255, 255, top
		end

	10:	begin			; green, exponential
			loadct, 9, /silent
			bottom = 16
			top = 239
			tvlct, 255, 255, 255, top
		end

	else:	begin
			if (palette LT 0 && palette GE -41) then begin
		       		loadct, -palette-1, silent=~verbose
				bottom = 8
				top = 254
			endif else begin
				message2, 'Unknown palette: ' $
					+ string(palette), /continue
				set_palette, bottom=bottom, top=top, $
					maxlevs=maxlevs, /verbose
				return
			endelse
		end
endcase


final_statements:


if (maxlevs LE 0) then maxlevs = top - bottom + 1

; set the discrete part of the palette (based on col27.pro)

red_col27=[0,255,255,0,0,255,0,255,255,255,255,127,0,127,127,0,127,127, $
	0,127,0,0,127,127,127,255,255]
green_col27=[0,255,0,255,0,255,255,0,127,0,127,255,255,255,0,127,127,0, $
	0,127,127,127,127,0,255,127,255]
blue_col27=[0,255,0,0,255,0,255,255,0,127,127,0,127,127,255,255,255,127, $
	127,127,0,127,0,0,255,255,127]
max27 = min([bottom-1, 26])
tvlct, red_col27[0:max27], green_col27[0:max27], blue_col27[0:max27]
tvlct, 255, 255, 255, 255


old_palette  = palette
old_filename = filename
old_bottom   = bottom
old_top      = top
old_maxlevs  = maxlevs


if (verbose && palette GE 0 && n_filename NE 1) then begin
	info_str = string(palette, names[palette], bottom, top, maxlevs, $
		format='(%"Palette %d (%s) bottom=%d top=%d maxlevs=%d")')
	message2, info_str, /informational
endif


end
