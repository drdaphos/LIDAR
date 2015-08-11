;SIMPLESTAT_PLOT
;plot a histogram computed with simplestat
;uses IDL (not TIDL)
;
;by Franco Marenco
;please report any bugs and/or your modifications to me :-)
;
;companion routine: simplestat
;also needs: simplefit
;
;input:   his_freq, his_x are the data frequencies and central values
;         computed with simplestat
;input:   avg, std are the mean and std dev used for overplotting a gaussian
;input:   xmin, xmax, med: are printed on the plot
;input:   n_gauss: number of points composing the gaussian (default 100)
;input:   gauss_color, gauss_style: color/linestyle for the gaussian
;input:   the other input parameters are for graphical style and
;         are straightforward (look at the routine definition below)
;
;keyword: nowritestat: if set, the avg, std, median, etc are not overwritten
;         on the plot


pro simplestat_plot, his_freq, his_x, $
	avg=avg, std=std, xmin=min, xmax=max, med=med, $
	n_gauss=n_gauss, gauss_color=gauss_color, gauss_style=gauss_style, $
	title=title, xtitle=xtitle, ytitle=ytitle, $
	thick=thick, charthick=charthick, charsize=charsize, $
	xcharsize=xcharsize, ycharsize=ycharsize, $
	xtickformat=xtickformat, ytickformat=ytickformat, $
	position=position, xmargin=xmargin, ymargin=ymargin, $
	nowritestat=nowritestat, histoplot=histoplot


compile_opt strictarr, strictarrsubs


n_bins = n_elements(his_freq)
if (n_elements(his_x) LE 0) then his_x = dindgen(n_bins)
if (n_elements(his_x) NE n_bins) then message, 'Array sizes inconsistent'

if (n_elements(ytitle) NE 1) then ytitle = 'Frequency'
if (n_elements(xtickformat) NE 1) then xtickformat = '(f0.2)'

if (n_elements(n_gauss) LE 0) then n_gauss = 100
if (n_elements(gauss_color) LE 0 && n_elements(gauss_style) LE 0) $
	then gauss_style = 5

plotgauss = 0

xran = n_bins / 2.0D + [-1D, 1D] * (n_bins + 3.0D) / 2.0D
ymax = max(his_freq)
nsamples = total(his_freq)
delta = mean(his_x[2:(n_bins-2)] - his_x[1:(n_bins-3)])
fit = simplefit(dindgen(n_bins-2)+1.0D, his_x[1:(n_bins-2)])
norm = nsamples * delta
t = xran[0] + (xran[1] - xran[0]) * dindgen(n_gauss) / (n_gauss - 1.0D)
x = fit[0] + fit[1] * t

if (n_elements(avg) EQ 1 && n_elements(std) EQ 1) then begin
	y = norm * exp(-(x - avg)^2.0D / (2.0D*std^2)) / (sqrt(2.0*!dpi)*std)
	ymax = max([y, ymax])
	plotgauss = 1
endif

plot, lindgen(n_bins+2)-1L, [0.0D, his_freq, 0.0D], psym=10, /nodata, $
	/xstyle, xrange=xran, yrange=[0,ymax+0.5], ytickformat=ytickformat, $
	xticks=n_bins-3, xtickv=dindgen(n_bins-2)+1.0D, $
	xtickname=strtrim(string(his_x[1:(n_bins-2)],format=xtickformat),2), $
	thick=thick, xthick=thick, ythick=thick, charthick=charthick, $
	charsize=charsize, xcharsize=xcharsize, ycharsize=ycharsize, $
	title=title, xtitle=xtitle, ytitle=ytitle, position=position, $
	xmargin=xmargin, ymargin=ymargin

if (keyword_set(histoplot)) then begin
	data = 0
	for i=0, n_bins-1 do if (his_freq[i] GT 0) then $
		data = [data, replicate(i-0.5, his_freq[i])]
	data = data[1:*]
	datacolor0 = (!p.color EQ 0 ? 'Black' : 'White')
	case histoplot of
		2: begin
			datacolor = datacolor0
			line_fill = 1
			orientation = [45,-45]
			spacing = 0.25
			polycolor = datacolor0
		end

		3: begin
			datacolor = 'Indian red'
			line_fill = 1
			orientation = [45, -45]
			spacing = 0.25
			polycolor = 'Indian red'
		end

		else: begin
			datacolor = datacolor0
			fillpolygon = 1
			polycolor = 'Grey'
		end
	endcase
	histoplot, data, /oplot, binsize=1, thick=thick, $
		datacolorname=datacolor, line_fill=line_fill, $
		fillpolygon=fillpolygon, orientation=orientation, $
		spacing=spacing, polycolor=polycolor
endif else begin
	oplot, lindgen(n_bins+2)-1L, [0.0D, his_freq, 0.0D], $
		psym=10, thick=thick
endelse

if (plotgauss) then begin
	oplot, t, y, color=gauss_color, linestyle=gauss_style, thick=thick
endif

if (~keyword_set(nowritestat)) then begin
	xyouts, !x.crange[0] + 0.75*(!x.crange[1]-!x.crange[0]), $
		!y.crange[0] + 0.85*(!y.crange[1]-!y.crange[0]), $
		/data, charsize=ycharsize, charthick=charthick, $
		strtrim(string(nsamples, format='(i0)'),2) + ' samples'

	if (n_elements(avg) EQ 1) then $
		xyouts, !x.crange[0] + 0.75*(!x.crange[1]-!x.crange[0]), $
			!y.crange[0] + 0.80*(!y.crange[1]-!y.crange[0]), $
			/data, charsize=ycharsize, charthick=charthick, $
			'Avg: ' + strtrim(string(avg, format=xtickformat),2)

	if (n_elements(std) EQ 1) then $
		xyouts, !x.crange[0] + 0.75*(!x.crange[1]-!x.crange[0]), $
			!y.crange[0] + 0.75*(!y.crange[1]-!y.crange[0]), $
			/data, charsize=ycharsize, charthick=charthick, $
			'Std: ' + strtrim(string(std, format=xtickformat),2)

	if (n_elements(min) EQ 1) then $
		xyouts, !x.crange[0] + 0.75*(!x.crange[1]-!x.crange[0]), $
			!y.crange[0] + 0.70*(!y.crange[1]-!y.crange[0]), $
			/data, charsize=ycharsize, charthick=charthick, $
			'Min: ' + strtrim(string(min, format=xtickformat),2)

	if (n_elements(max) EQ 1) then $
		xyouts, !x.crange[0] + 0.75*(!x.crange[1]-!x.crange[0]), $
			!y.crange[0] + 0.65*(!y.crange[1]-!y.crange[0]), $
			/data, charsize=ycharsize, charthick=charthick, $
			'Max: ' + strtrim(string(max, format=xtickformat),2)

	if (n_elements(med) EQ 1) then $
		xyouts, !x.crange[0] + 0.75*(!x.crange[1]-!x.crange[0]), $
			!y.crange[0] + 0.60*(!y.crange[1]-!y.crange[0]), $
			/data, charsize=ycharsize, charthick=charthick, $
			'Median: ' + strtrim(string(med, format=xtickformat),2)
endif


end


