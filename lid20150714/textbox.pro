pro textbox, box, text, color=color, charsize=charsize, nobox=nobox, left=left


compile_opt strictarr, strictarrsubs


if (n_elements(charsize) NE 1) then charsize = 1.5

halfchar = charsize * 0.25 * float(!d.y_ch_size) / !d.y_size
xbox  = [box[0], box[2], box[2], box[0], box[0]]
ybox  = [box[1], box[1], box[3], box[3], box[1]]
xtext = (box[0] + box[2]) / 2.0
ytext = (box[1] + box[3]) / 2.0 - halfchar
align = 0.5

if (~keyword_set(nobox)) then begin
	plots, xbox, ybox, color=color, /normal
endif else if (n_elements(left) NE 1) then begin
	left = 1
endif

if (keyword_set(left)) then begin
	xtext = box[0]
	align = 0.0
endif

if (n_elements(text) EQ 1) then begin
	xyouts, xtext, ytext, text, alignment=align, /normal, $
		color=color, charsize=charsize
endif

end
