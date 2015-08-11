;SIMPLESTAT
;makes a histogram of data and overplots a gaussian curve
;is a front end to the IDL histogram routine
;uses IDL (not TIDL)
;a simple example to try it: simplestat, (10-indgen(20))^2, /plot
;
;by Franco Marenco
;please report any bugs and/or your modifications to me :-)
;
;companion routine: simplestat_plot
;
;input:   x is the data
;input:   min_value, max_value: ignore smaller/larger data
;input:   n_bins: number of data bins (default 11)
;input:   n_std: width of binned interval in number of std dev (default 3)
;
;output:  his_freq, his_x are the data frequencies and central values
;output:  avg, std, xmin, xmax, med are average, std dev, min, max and median
;output:  nsamples is the number of valid data points
;
;keyword: plot: if set a plot is automatically made to the graphics device
;note:    more control on the plotting can ve done by calling simplestat
;         without /plot, and then calling simplestat_plot separately


pro simplestat, x, his_freq, his_x, min_value=min_value, max_value=max_value, $
	avg=avg, std=std, xmin=min, xmax=max, med=med, nsamples=nsamples, $
	n_bins=n_bins, n_std=n_std, plot=plot

compile_opt strictarr, strictarrsubs


if (n_elements(min_value) NE 1) then min_value = min(x,/nan) - 100.0D
if (n_elements(max_value) NE 1) then max_value = max(x,/nan) + 100.0D
if (n_elements(n_bins) NE 1)    then n_bins = 11
if (n_elements(n_std) NE 1)     then n_std = 3.0D

idx = where(finite(x) AND x GE min_value AND x LE max_value, nsamples)

if (nsamples LE 1) then message, 'Insufficient data.'

xx = x[idx]

avg = mean(xx)
std = stddev(xx)
min = min(xx, max=max)
med = median(xx)

his_freq = lonarr(n_bins)
min_his = avg - n_std * std
max_his = avg + n_std * std
his_freq[1:(n_bins-2)] = histogram(xx, nbins=n_bins-2, $
	binsize=(max_his-min_his)/(n_bins-2), min = min_his)
idx = where(xx LT min_his, cnt)
his_freq[0] = cnt
idx = where(xx GT max_his, cnt)
his_freq[n_bins-1] = cnt

delta = 2.0D * n_std * std / (n_bins - 2.0D)
t = dindgen(n_bins) - 0.5D - (n_bins - 2.0D) / 2.0D
his_x = avg + t * delta

if (keyword_set(plot)) then begin
	simplestat_plot, his_freq, his_x, $
		avg=avg, std=std, xmin=min, xmax=max, med=med
endif

end
