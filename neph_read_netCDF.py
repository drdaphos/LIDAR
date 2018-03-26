# -*- coding: iso-8859-1 -*-
'''
Created on November 6th for reading in and plotting nephelometer data
Debbie O'Sullivan
'''
import matplotlib.pyplot as plt
import numpy as np
from netCDF4 import Dataset
import time

###############################################################################################
" flight details and filenames all go here "
###############################################################################################

fltdata='/data/local/fros/Faam_data/core/core_faam_20120610_v004_r1_b702_1hz.nc'
flt_num='B702'

fltsumm='/data/local/fros/Faam_data/core/flight-sum_faam_20120610_r0_b702.txt'
run_times='/data/local/fros/Faam_data/fltsum/' + flt_num + '_run_times.txt'

savedir='/data/local/fros/Faam_data/plots/neph/'
###############################################################################################

def get_gmt(secs):
    time_gmt=time.strftime('%H:%M:%S',time.gmtime(secs)) 
    return time_gmt

def get_sec(s):
    '''
    Converts the time in HH:MM:SS to seconds
    '''
    l = s.split(':')
    return int(l[0]) * 3600 + int(l[1]) * 60 + int(l[2])

def read(neph_file):
    ''' 
    function to read in processed SWS/SHIMS netCDF data 
    file = name and path of ncfile
    '''
    nc=Dataset(neph_file,'r')
    f_time=nc.variables['Time'][:]
    alt=nc.variables['ALT_GIN'][:]
    lat=nc.variables['LAT_GIN'][:]
    lon=nc.variables['LON_GIN'][:]
    tsc_bluu=nc.variables['TSC_BLUU'][:]
    tsc_grnu=nc.variables['TSC_GRNU'][:]
    tsc_redu=nc.variables['TSC_REDU'][:]
    bsc_bluu=nc.variables['BSC_BLUU'][:]
    bsc_grnu=nc.variables['BSC_GRNU'][:]
    bsc_redu=nc.variables['BSC_REDU'][:]
    return f_time, alt, lat, lon, tsc_bluu, tsc_grnu, tsc_redu, bsc_bluu, bsc_grnu, bsc_redu

def find_starts():
    START_TIME=[]
    STOP_TIME=[]
    PROF=[]
    ALT=[]
    search = 'kft'
    for i in range (0,L):
        newdata = ' '.join(data[i].split())
        if search in newdata:
            starttime,stoptime,prof,alt=newdata.split()[0],newdata.split()[1],newdata.split()[3],newdata.split()[-2]
            start_list = list(starttime)
            start_list.insert(2, ':')
            start_list.insert(5,':') 
            start_time = "".join(start_list)
            stop_list = list(stoptime)
            stop_list.insert(2, ':')
            stop_list.insert(5,':') 
            stop_time = "".join(stop_list)
            print>>k, start_time,stop_time,prof,alt
            START_TIME.append(start_time)
            STOP_TIME.append(stop_time)
            PROF.append(prof)
            ALT.append(alt)
    return START_TIME,STOP_TIME,PROF,ALT
   
#def plot(alt,tsc_bluu,tsc_grnu,tsc_redu,i, flt_num):
    ''' plot spectra against wavelength
    '''
#    plt.title('Nephelometer data '+flt_num+' profile number= '+PROF[i]+' ')
#    ax = fig.add_subplot(111)
#    x=str(t)
#    p1, = ax.plot(nirwv,nir, label='NIR '+x)
#    p2, = ax.plot(viswv,vis, label='VIS '+x)
#    handles, labels = ax.get_legend_handles_labels()
#    ax.set_position([0.1,0.1,0.65,0.8])
#    ax.set_xlabel('wavelength (nm)')
#    ax.set_ylabel('irradiance Wm2 nm')
    
#    ax.legend(handles[::-1], labels[::-1],bbox_to_anchor=(1.37, 1.05))


################################################################################################
" calls to methods "
################################################################################################


# extracts data from the processed netCDF file
f_time, alt, lat, lon, tsc_bluu, tsc_grnu, tsc_redu, bsc_bluu, bsc_grnu, bsc_redu = read(fltdata)

# extracts run times from the flight managers log #
f = open(fltsumm, 'Ur')
data = f.readlines()
L=find_lines()
f.close()
k=open(run_times, 'w')

START_TIME,STOP_TIME,PROF,ALT =find_starts()
k.close()
print START_TIME,STOP_TIME,PROF,ALT

#for i in range (0,size):
#    runstart=I_START_TIME[i]
#    runstop=I_STOP_TIME[i]
#    fig = plt.figure(figsize=(15,13))
#    plot(alt,tsc_bluu,tsc_grnu,tsc_redu,i,flt_num)            
#    fig.savefig(savedir + '_' + flt_num+'_prof_'+PROF[i]+'_' + ALT[i] + '.jpg', format='jpg')
#print 'done'


plot(alt,tsc_bluu,tsc_grnu,tsc_redu,i,flt_num)            
fig.savefig(savedir + '_' + flt_num+'_prof number_'+prof+'_' + '.jpg', format='jpg')
print 'done'


