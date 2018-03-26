#!/bin/bash

#######################################################################
#                                                                     #
# backup_swsshims.sh [first flt no inc path] [optional: last flt no]  #
#                                                                     #
#  Script to back up SWS/SHIMS data to MASS                           #
#                                                                     #
#  This script is intended to tar raw SWS/SHIMS data, a flight  at a  #
#  time, and archive them in MASS.  The tar files will be created in  #
#  a temporary directory in the SWS/SHIMS project space until trans-  #
#  fered to MASS.  The script should notify  the  operator  of  each  #
#  flight which is successfully archived and any  where  either  the  #
#  tarring or the archiving fail. In the event of a failure with one  #
#  flight, the script will skip onto the next flight.   Where  there  #
#  are gaps in the series of flight numbers between  the  first  and  #
#  last provided the script shall skip over these.                    #
#                                                                     #
#  WARNING:  SWS/SHIMS data  must  be  stored  in  directories  with  #
#            standard flight number format  names (i.e.  one  letter  #
#            followed by three digits) or the script shall fail. The  #
#            manner in which it might fail has not been  tested  and  #
#            such errors are not currently trapped in any way.        #
#                                                                     #
#  Input arguments (no key words):                                    #
#    [first flt no inc path]  =  the full, absolute  path  of  first  #
#            flight to be archived including the flight directory.    #
#    [optional: last flt no]  =  flight number (no  path  or  prefix  #
#            of the last flight.  Omit if only one flight.            #
#                                                                     #
#  Examples:                                                          #
#    backup_swsshims.sh /media/usbdisk/B400 421                       #
#        archive all flights from B400 to B421,  inclusive,  located  #
#        in /media/usbdisk/                                           #
#    backup_swsshims.sh /media/usbdisk/B413                           #
#        archive only flight B413 located in /media/usbdisk/          #
#                                                                     #
#                                                       AKV 10-12-14  #
#######################################################################

# Count the number of arguments supplied and act accordingly
  if [ "$#" = 0 ]
   then
#   If no arguments have been supplied then print the 'help file' and quit.
    awk 'FNR==2,FNR==40 {print}' ./backup_swsshims.sh
    exit 1
  else
    date +"======== STARTING SWS/SHIMS ARCHIVE RUN, %H%M %A %d/%m/%y ========"
#   Create a (hopefully) unique filename for this run using the time of day.
    log_name=`date +"/home/h03/swsshims/log_files/swsshims_archive_%H%M%S.log"`
    echo "       log file: "$log_name
#   Check if the error log file exists as a test to see if archiving is already under way.
    if [ -f "$log_name" ]
     then
#     Establish who left the log and assemble their address
      operator1username=`ls -l $log_name | awk '{print $3}'`
      operator1name=`finger $operator1username | head -1 | awk '{print $4}'`
      operator1address=$operator1name"@metoffice.gov.uk"
#     Establish who is running the script and assemble their address
      script_run_by=`whoami`
      operator2name=`finger $script_run_by | head -1 | awk '{print $4}'`
      operator2address=$operator2name"@metoffice.gov.uk"
#     Print a message to the screeen for the operator
      screen_text="\n#\n# ARCHIVE FAILURE\n#\n# Your archive attempt has been \
        prevented from running \n# an SWS/SHIMS duplicate log file already \
		exists.  The file was created\n# by "$operator2name".  He/she/it has \
		been notified of your attempt\n# and should contact you shortly.\n#\n"
      echo -e $screen_text
#     Email the previous operator to alert them to the second attempt to run an archival
      email_text=" An SWS/SHIMS archive log file exists in your name and has prevented \
        "$operator1name" from running an archive job.  If this file exists because \
		you are running an archive job, please email "$operator2address" to say so, \
		and again when your job is complete.\n\n If this file remains in place because \
		your job has failed, please establish the reason for the failure and either \
		complete the archival or seek assistance from Alan Vance.  In either case, \
		please contact "$operator2name" as he/she/it is waiting to run a job."
      echo -e $email_text | mailx $operator1username -s 'WARNING: SWS/SHIMS archive attempt'
      exit 1
    else
    touch $log_name
#   Run the script as a background job
      nohup ./swsshims_backup_script.sh $log_name $@ > $log_name 2>&1 &
    fi
  fi
# end
