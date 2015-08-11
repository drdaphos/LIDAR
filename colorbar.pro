; extracted from file /home/h04/hadjh/idl/htfrtc/idl_general.pro
; courtesy of Jean-Claude Thelen
; modified to accept the following keywords: charthick, linethick, min_value
; and to avoid modifying format
;
;+
; NAME:
;   COLORBAR
;
; PURPOSE:
;
;       The purpose of this routine is to add a color bar to the current
;       graphics window.
;
; CALLING SEQUENCE:
;
;       COLORBAR
;
; INPUTS:
;
;       None.
;
; KEYWORD PARAMETERS:
;
;       ANNOTATECOLOR: The name of the "annotation color" to use. The names are those for
;                     FSC_COLOR, and using the keyword implies that FSC_COLOR is also in
;                     your !PATH. If this keyword is used, the annotation color is loaded
;                     *after* the color bar is displayed. The color will be represented
;                     as theColor = FSC_COLOR(ANNOTATECOLOR, COLOR). This keyword is provide
;                     to maintain backward compatibility, but also to solve the problem of
;                     and extra line in the color bar when this kind of syntax is used in
;                     conjunction with the indexed (DEVICE, DECOMPOSED=0) model is used:
;
;                          LoadCT, 33
;                          TVImage, image
;                          Colorbar, Color=FSC_Color('firebrick')
;
;                     The proper syntax for device-independent color is like this:
;
;                          LoadCT, 33
;                          TVImage, image
;                          Colorbar, AnnotateColor='firebrick', Color=255
;
;       BOTTOM:       The lowest color index of the colors to be loaded in
;                     the bar.
;
;       CHARSIZE:     The character size of the color bar annotations. Default is !P.Charsize.
;
;       COLOR:        The color index of the bar outline and characters. Default
;                     is !P.Color..
;
;       DIVISIONS:    The number of divisions to divide the bar into. There will
;                     be (divisions + 1) annotations. The default is 6.
;
;       FONT:         Sets the font of the annotation. Hershey: -1, Hardware:0, True-Type: 1.
;
;       FORMAT:       The format of the bar annotations. Default is '(I0)'.
;
;       INVERTCOLORS: Setting this keyword inverts the colors in the color bar.
;
;       MAXRANGE:     The maximum data value for the bar annotation. Default is
;                     NCOLORS.
;
;       MINRANGE:     The minimum data value for the bar annotation. Default is 0.
;
;       MINOR:        The number of minor tick divisions. Default is 2.
;
;       NCOLORS:      This is the number of colors in the color bar.
;
;       NODISPLAY:    COLORBAR uses FSC_COLOR to specify some of it colors. Normally, 
;                     FSC_COLOR loads "system" colors as part of its palette of colors.
;                     In order to do so, it has to create an IDL widget, which in turn 
;                     has to make a connection to the windowing system. If your program 
;                     is being run without a window connection, then this program will 
;                     fail. If you can live without the system colors (and most people 
;                     don't even know they are there, to tell you the truth), then setting 
;                     this keyword will keep them from being loaded, and you can run
;                     COLORBAR without a display.
;
;       POSITION:     A four-element array of normalized coordinates in the same
;                     form as the POSITION keyword on a plot. Default is
;                     [0.88, 0.10, 0.95, 0.90] for a vertical bar and
;                     [0.10, 0.88, 0.90, 0.95] for a horizontal bar.
;
;       RANGE:        A two-element vector of the form [min, max]. Provides an
;                     alternative way of setting the MINRANGE and MAXRANGE keywords.
;
;       REVERSE:      Setting this keyword reverses the colors in the colorbar.
;
;       RIGHT:        This puts the labels on the right-hand side of a vertical
;                     color bar. It applies only to vertical color bars.
;
;       TICKNAMES:    A string array of names or values for the tick marks.
;
;       TITLE:        This is title for the color bar. The default is to have
;                     no title.
;
;       TOP:          This puts the labels on top of the bar rather than under it.
;                     The keyword only applies if a horizontal color bar is rendered.
;
;       VERTICAL:     Setting this keyword give a vertical color bar. The default
;                     is a horizontal color bar.
;
; EXAMPLE:
;
;       To display a horizontal color bar above a contour plot, type:
;
;       LOADCT, 5, NCOLORS=100
;       CONTOUR, DIST(31,41), POSITION=[0.15, 0.15, 0.95, 0.75], $
;          C_COLORS=INDGEN(25)*4, NLEVELS=25
;       COLORBAR, NCOLORS=100, POSITION=[0.15, 0.85, 0.95, 0.90]
;

PRO COLORBAR, BOTTOM=bottom, CHARSIZE=charsize, COLOR=color, DIVISIONS=divisions, $
   FORMAT=format0, POSITION=position, MAXRANGE=maxrange, MINRANGE=minrange, NCOLORS=ncolors, $
   TITLE=title, VERTICAL=vertical, TOP=top, RIGHT=right, MINOR=minor, $
   RANGE=range, FONT=font, TICKLEN=ticklen, _EXTRA=extra, INVERTCOLORS=invertcolors, $
   TICKNAMES=ticknames, REVERSE=reverse, ANNOTATECOLOR=annotatecolor, XLOG=xlog, YLOG=ylog, $
   NODISPLAY=nodisplay, CHARTHICK=charthick, LINETHICK=linethick, MIN_VALUE=min_value

    compile_opt idl2

    if (n_elements(format0) GE 1) then format = format0

    ; Return to caller on error.
    On_Error, 2

    ; Save the current plot state.
    bang_p = !P
    bang_x = !X
    bang_Y = !Y
    bang_Z = !Z
    bang_Map = !Map

    ; Are scalable pixels available on the device?
    IF (!D.Flags AND 1) NE 0 THEN scalablePixels = 1 ELSE scalablePixels = 0

    ; Which release of IDL is this?
    thisRelease = Float(!Version.Release)

    ; Check and define keywords.
    IF N_ELEMENTS(ncolors) EQ 0 THEN BEGIN

       ; Most display devices to not use the 256 colors available to
       ; the PostScript device. This presents a problem when writing
       ; general-purpose programs that can be output to the display or
       ; to the PostScript device. This problem is especially bothersome
       ; if you don't specify the number of colors you are using in the
       ; program. One way to work around this problem is to make the
       ; default number of colors the same for the display device and for
       ; the PostScript device. Then, the colors you see in PostScript are
       ; identical to the colors you see on your display. Here is one way to
       ; do it.

       IF scalablePixels THEN BEGIN
          oldDevice = !D.NAME

             ; What kind of computer are we using? SET_PLOT to appropriate
             ; display device.

          thisOS = !VERSION.OS_FAMILY
          thisOS = STRMID(thisOS, 0, 3)
          thisOS = STRUPCASE(thisOS)
          CASE thisOS of
             'MAC': SET_PLOT, thisOS
             'WIN': SET_PLOT, thisOS
             ELSE: SET_PLOT, 'X'
          ENDCASE

          ; Here is how many colors we should use.
          ncolors = !D.TABLE_SIZE
          SET_PLOT, oldDevice
        ENDIF ELSE ncolors = !D.TABLE_SIZE
    ENDIF
    IF N_ELEMENTS(bottom) EQ 0 THEN bottom = 0B
    IF N_ELEMENTS(charsize) EQ 0 THEN charsize = !P.Charsize
    IF N_ELEMENTS(format) EQ 0 THEN format = '(I0)'
    IF N_ELEMENTS(color) EQ 0 THEN color = !P.Color
    minrange = (N_ELEMENTS(minrange) EQ 0) ? 0. : Float(minrange)
    maxrange = (N_ELEMENTS(maxrange) EQ 0) ? Float(ncolors) : Float(maxrange)
    IF N_ELEMENTS(ticklen) EQ 0 THEN ticklen = 0.2
    IF N_ELEMENTS(minor) EQ 0 THEN minor = 2
    IF N_ELEMENTS(range) NE 0 THEN BEGIN
       minrange = Float(range[0])
       maxrange = Float(range[1])
    ENDIF
    IF N_ELEMENTS(divisions) EQ 0 THEN divisions = 6
    IF N_ELEMENTS(font) EQ 0 THEN font = !P.Font
    IF N_ELEMENTS(title) EQ 0 THEN title = ''
    xlog = Keyword_Set(xlog)
    ylog = Keyword_Set(ylog)

    ; You can't have a format set *and* use ticknames.
    IF N_ELEMENTS(ticknames) NE 0 THEN format = ""

    ; If the format is NOT null, then format the ticknames yourself.
    ; Can't assume minrange is less than maxrange.
    IF (xlog XOR ylog) EQ 0 THEN BEGIN
        IF format NE "" THEN BEGIN
           IF minrange LT maxrange THEN BEGIN
               step = (maxrange - minrange) / divisions
               levels = minrange > (Indgen(divisions+1) * step + minrange) < maxrange
               IF StrPos(StrLowCase(format), 'i') NE -1 THEN levels = Round(levels)
               ticknames = String(levels, Format=format)
               format = "" ; No formats allowed in PLOT call now that we have ticknames.
           ENDIF ELSE BEGIN
               step = (minrange - maxrange) / divisions
               levels = maxrange > (Indgen(divisions+1) * step + maxrange) < minrange
               levels = Reverse(levels)
               IF StrPos(StrLowCase(format), 'i') NE -1 THEN levels = Round(levels)
               ticknames = String(levels, Format=format)
               format = "" ; No formats allowed in PLOT call now that we have ticknames.
           ENDELSE
        ENDIF
    ENDIF

    IF KEYWORD_SET(vertical) THEN BEGIN
       bar = REPLICATE(1B,20) # BINDGEN(ncolors)
       IF Keyword_Set(invertcolors) THEN bar = Reverse(bar, 2)
       IF N_ELEMENTS(position) EQ 0 THEN BEGIN
          position = [0.88, 0.1, 0.95, 0.9]
       ENDIF ELSE BEGIN
          IF position[2]-position[0] GT position[3]-position[1] THEN BEGIN
             position = [position[1], position[0], position[3], position[2]]
          ENDIF
          IF position[0] GE position[2] THEN Message, "Position coordinates can't be reconciled."
          IF position[1] GE position[3] THEN Message, "Position coordinates can't be reconciled."
       ENDELSE
    ENDIF ELSE BEGIN
       bar = BINDGEN(ncolors) # REPLICATE(1B, 20)
       IF Keyword_Set(invertcolors) THEN bar = Reverse(bar, 1)
       IF N_ELEMENTS(position) EQ 0 THEN BEGIN
          position = [0.1, 0.88, 0.9, 0.95]
       ENDIF ELSE BEGIN
          IF position[3]-position[1] GT position[2]-position[0] THEN BEGIN
             position = [position[1], position[0], position[3], position[2]]
          ENDIF
          IF position[0] GE position[2] THEN Message, "Position coordinates can't be reconciled."
          IF position[1] GE position[3] THEN Message, "Position coordinates can't be reconciled."
       ENDELSE
    ENDELSE

    ; Scale the color bar.
     bar = BYTSCL(bar, TOP=(ncolors-1) < (255-bottom)) + bottom

    ; Apply the min_value
     if (n_elements(min_value) EQ 1) then begin
	top_idx = (ncolors-1) < (255-bottom)
	min_idx = bytscl(min_value, min=minrange, max=maxrange, $
		TOP=top_idx) + bottom
	if (min_idx GT top_idx) then min_idx = top_idx
	if (min_idx GT bottom) then begin
;		--min_idx
		if (keyword_set(vertical)) then begin
			bar[*,0:min_idx] = !p.background
		endif else begin
			bar[0:min_idx,*] = !p.background
		endelse
        endif
     endif

     IF Keyword_Set(reverse) THEN BEGIN
       IF Keyword_Set(vertical) THEN bar = Reverse(bar,2) ELSE bar = Reverse(bar,1)
     ENDIF

    ; Get starting locations in NORMAL coordinates.
    xstart = position[0]
    ystart = position[1]

    ; Get the size of the bar in NORMAL coordinates.
    xsize = (position[2] - position[0])
    ysize = (position[3] - position[1])

    ; Display the color bar in the window. Sizing is
    ; different for PostScript and regular display.
    IF scalablePixels THEN BEGIN

       TV, bar, xstart, ystart, XSIZE=xsize, YSIZE=ysize, /Normal

    ENDIF ELSE BEGIN

       bar = CONGRID(bar, CEIL(xsize*!D.X_VSize), CEIL(ysize*!D.Y_VSize))

       ; Decomposed color off if device supports it.
       CASE  StrUpCase(!D.NAME) OF
            'X': BEGIN
                IF thisRelease GE 5.2 THEN Device, Get_Decomposed=thisDecomposed
                Device, Decomposed=0
                ENDCASE
            'WIN': BEGIN
                IF thisRelease GE 5.2 THEN Device, Get_Decomposed=thisDecomposed
                Device, Decomposed=0
                ENDCASE
            'MAC': BEGIN
                IF thisRelease GE 5.2 THEN Device, Get_Decomposed=thisDecomposed
                Device, Decomposed=0
                ENDCASE
            ELSE:
       ENDCASE

       TV, bar, xstart, ystart, /Normal

       ; Restore Decomposed state if necessary.
       CASE StrUpCase(!D.NAME) OF
          'X': BEGIN
             IF thisRelease GE 5.2 THEN Device, Decomposed=thisDecomposed
             ENDCASE
          'WIN': BEGIN
             IF thisRelease GE 5.2 THEN Device, Decomposed=thisDecomposed
             ENDCASE
          'MAC': BEGIN
             IF thisRelease GE 5.2 THEN Device, Decomposed=thisDecomposed
             ENDCASE
          ELSE:
       ENDCASE

    ENDELSE

    ; Annotate the color bar.
    IF N_Elements(annotateColor) NE 0 THEN $
      color = FSC_Color(annotateColor, color, NODISPLAY=Keyword_Set(nodisplay))

    IF KEYWORD_SET(vertical) THEN BEGIN

       IF KEYWORD_SET(right) THEN BEGIN

          PLOT, [minrange,maxrange], [minrange,maxrange], /NODATA, XTICKS=1, $
             YTICKS=divisions, XSTYLE=1, YSTYLE=9, $
             POSITION=position, COLOR=color, CHARSIZE=charsize, /NOERASE, $
             XTICKFORMAT='(A1)', YTICKFORMAT='(A1)', YMINOR=minor, _EXTRA=extra, $
             YTICKNAME=ticknames, FONT=font, YLOG=ylog, $
             CHARTHICK=charthick, XTHICK=linethick, YTHICK=linethick

          AXIS, YAXIS=1, YRANGE=[minrange, maxrange], YTICKFORMAT=format, YTICKS=divisions, $
             YTICKLEN=ticklen, YSTYLE=1, COLOR=color, CHARSIZE=charsize, $
             FONT=font, YTITLE=title, _EXTRA=extra, YMINOR=minor, YTICKNAME=ticknames, YLOG=ylog, $
             CHARTHICK=charthick, XTHICK=linethick, YTHICK=linethick

       ENDIF ELSE BEGIN

          PLOT, [minrange,maxrange], [minrange,maxrange], /NODATA, XTICKS=1,  $
             YTICKS=divisions, YSTYLE=1, XSTYLE=1, TITLE=title, $
             POSITION=position, COLOR=color, CHARSIZE=charsize, /NOERASE, $
             XTICKFORMAT='(A1)', YTICKFORMAT=format, YMinor=minor, _EXTRA=extra, $
             YTICKNAME=ticknames, YLOG=ylog, YTICKLEN=ticklen, FONT=font, $
             CHARTHICK=charthick, XTHICK=linethick, YTHICK=linethick

       ENDELSE

    ENDIF ELSE BEGIN

       IF KEYWORD_SET(top) THEN BEGIN

          PLOT, [minrange,maxrange], [minrange,maxrange], /NODATA, XTICKS=divisions, $
             YTICKS=1, XSTYLE=9, YSTYLE=1, $
             POSITION=position, COLOR=color, CHARSIZE=charsize, /NOERASE, $
             YTICKFORMAT='(A1)', XTICKFORMAT='(A1)', XTICKLEN=ticklen, $
             XRANGE=[minrange, maxrange], FONT=font, XMINOR=minor,_EXTRA=extra, $
             XTICKNAME=ticknames, XLOG=xlog, $
             CHARTHICK=charthick, XTHICK=linethick, YTHICK=linethick

          AXIS, XTICKS=divisions, XSTYLE=1, COLOR=color, CHARSIZE=charsize, $
             XTICKFORMAT=format, XTICKLEN=ticklen, XRANGE=[minrange, maxrange], XAXIS=1, $
             FONT=font, XTITLE=title, _EXTRA=extra, XCHARSIZE=charsize, XMINOR=minor, $
             XTICKNAME=ticknames, XLOG=xlog, $
             CHARTHICK=charthick, XTHICK=linethick, YTHICK=linethick

       ENDIF ELSE BEGIN

          PLOT, [minrange,maxrange], [minrange,maxrange], /NODATA, XTICKS=divisions, $
             YTICKS=1, XSTYLE=1, YSTYLE=1, TITLE=title, $
             POSITION=position, COLOR=color, CHARSIZE=charsize, /NOERASE, $
             YTICKFORMAT='(A1)', XTICKFORMAT=format, XTICKLEN=ticklen, $
             XRANGE=[minrange, maxrange], FONT=font, XMinor=minor, _EXTRA=extra, $
             XTICKNAME=ticknames, XLOG=xlog, $
             CHARTHICK=charthick, XTHICK=linethick, YTHICK=linethick

        ENDELSE

    ENDELSE

    ; Restore the previous plot and map system variables.
    !P = bang_p
    !X = bang_x
    !Y = bang_y
    !Z = bang_z
    !Map = bang_map

END

