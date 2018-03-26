#!/bin/bash

################################################################################
#
#  backup_sws-shims.sh [first flt no inc path] [optional: last flt no]
#
#   Script to back up SWS/SHIMS data to MASS
#
#   This script is intended to tar raw sws-shims data, a flight at a time, and
#   archive them in MASS.  The tar files will be created in a temporary
#   directory in the SWS/SHIMS project space until transfered to MASS.  The
#   script should notify the operator of each flight which is successfully
#   archived and any where either the tarring or the archiving fail.  In the
#   event of a failure with one flight, the script will skip onto the next
#   flight.  Where there are gaps in the series of flight numbers between the
#   first and last provided the script shall skip over these.
#
#   WARNING:  SWS/SHIMS data must be stored in directories with standard flight
#             number format names (i.e. one letter followed by three digits or
#             the script shall fail.  The manner in which it might fail has not
#             been tested and such errors are not currently trapped in any way.
#
#   Input arguments (no key words):
#     [first flt no inc path]  =  the full, absolute path of first
#         flight to be archived including the flight directory.
#     [optional: last flt no]  =  flight number (no path or prefix
#         of the last flight.  Omit if only one flight.
#
#   Examples:
#     backup_sws-shims.sh /media/usbdisk/B400 421
#         archive all flights from B400 to B421, inclusive, located
#         in /media/usbdisk/
#     backup_sws-shims.sh /media/usbdisk/B413
#         archive only flight B413 located in /media/usbdisk/
#
#                                                                   AKV 11-07-14
################################################################################


# Declare some variables as integers
  declare -i last_flight_number first_flight_number current_flight_number

  echo ""
  echo "======================== STARTING SWS/SHIMS ARCHIVE RUN ========================"
  date +"                            %H%M %A %d/%m/%y"
  echo ""

# Establish who is running the script and assemble their address
  script_run_by=`whoami`
  operator=`finger $script_run_by | head -1 | awk '{print $4}'`
  operator=$operator"@metoffice.gov.uk"
  owner="alan.vance@metoffice.gov.uk"

# Read log file name.
  log_name="$1"
# Read first argument and turn into useful variables.
  first_flight_dir="$2"
# split the relevant bits out of the absolute path

  last_field=`echo $first_flight_dir | awk -F/ '{print $NF}'`
  if [ "$last_field" != "" ]
   then
   first_flight_dir=$first_flight_dir"/"
  fi
  first_flight=`echo $first_flight_dir | awk -F/ '{print $(NF-1)}'`
  path_NF=`echo $first_flight_dir | awk -F/ '{print NF-2}'`
  flight_dir_path=`dirname $first_flight_dir`
  flight_dir_path=$flight_dir_path"/"
  prefix=${first_flight:0:1}
  first_flight_number=${first_flight:1}

#
#   BIG difference here is that there's essentially six instruments rather than 1
#
#
#
#
#

# Work out from these parameters what the directories are which are
# to be tarred and check that they exist.

# Create a list of numbers to of flights to be archived
  flight_list=""
  if [ "$3" = "" ]
   then
#   Define a flight name as a string because the number alone might lack leading zeros.
    current_flight_name=$prefix`printf %03i ${first_flight_number}` #previous version#-->    current_flight_name=$prefix`printf %03i ${current_flight_number}`
#   Construct the directory path
    current_flight_dir=$flight_dir_path$current_flight_name
#   Check to see if this directory exists
    [ -d $current_flight_dir ]
#   If it does, add its number to the list
    if [ $? -eq 0 ]
     then
      flight_list=$flight_list" "$current_flight_name
    fi
  else
    last_flight_number=10#$3
  #  first_flight_number=10#$first_flight_number
  #  current_flight_number=10#$current_flight_number

#   go from first flight number to last, checking for directories
    for ((current_flight_number=$first_flight_number; current_flight_number<=$last_flight_number; current_flight_number++))
     do
#     Define a flight name as a string because the number alone might lack leading zeros.
      current_flight_name=$prefix`printf %03i ${current_flight_number}`
#     Construct the directory path
      current_flight_dir=$flight_dir_path$current_flight_name
#     Check to see if this directory exists
      [ -d $current_flight_dir ]
#     If it does, add its number to the list
      if [ $? -eq 0 ]
       then
        flight_list=$flight_list" "$current_flight_name
      fi
    done
  fi

# Tell the operator what's been found.

  echo "--- Attempting to tar the following flights"
  echo -e "   \c"
  echo -e " "$flight_list
  echo ""

# We have now got a list of the available flights within the range requested.
# Tar up flights in the list and extract from the list any flights which fail
# to tar properly.

  did_not_tar=""
  not_archived=""
  for current_flight_name in $flight_list
   do
    echo -e "--- Tarring flight "$current_flight_name" ---"
#   Construct the directory path
    current_flight_dir=$flight_dir_path$current_flight_name
#   Assemble a name and path for the tar file to be created.
    tar_name="/project/sws-shims/tar/"$current_flight_name".tar.bz"
#   Tar up the current flight
    tar -cjf $tar_name $current_flight_dir > /dev/null
    if [ $? -eq 0 ]
     then
#     Set permissions and give ownership to sws-shims
      chmod 664 $tar_name > /dev/null
      chown sws-shims $tar_name > /dev/null
#     Pass to MASS
      echo -e "--- Moosing flight "$current_flight_name" ---"
#     Put the file into MASS - MOOSE will reject if file already exists in MASS
      moo put -v $tar_name moose:/adhoc/projects/sws-shims/rawdata
#     Check the return code and if non-zero...
      moose_droppings=$?
      if [ $moose_droppings -eq 0 ]
       then
        echo -e "   *** flight "$current_flight_name" successfully archived ***"
        rm -f $tar_name
      elif [ $moose_droppings -eq 2 ]
       then
#       Notify the operator
        echo -e "Error: "$current_flight_name".tar.bz already exists in MASS - please rename and insert manually"
#       Add to bad list and notify operator of tar failure
        not_archived=$not_archived" "$current_flight_name
      else
#       Add to bad list and notify operator of tar failure
        not_archived=$not_archived" "$current_flight_name
        echo -e "Error: something odd happened with flight "$current_flight_name", MOOSE return code = "$moose_droppings".  NOT ARCHIVED."
      fi
    else
#     Add to bad list and notify operator of tar failure
      did_not_tar=$did_not_tar" "$current_flight_name
      echo -e "Error: failed to tar flight "$current_flight_name
    fi
    date +"---------- Finished with flight "$current_flight_name" at %H%M %A %d/%m/%y -----------"
  done
# List any flights which failed to tar.
  if [ "$did_not_tar" != "" ]
   then
    echo -e "\n--------------------------------------------------------------------------\n"
    did_not_tar="The following flights did not tar properly and have not been \
      archived:\n"$did_not_tar"\n"
    wait $!
    echo -e $did_not_tar
  fi
# Confess any flights which did not go to MASS.
  if [ "$not_archived" != "" ]
   then
    not_archived="The following flights probably tarred ok but did not go to \
      MASS:\n"$not_archived"\n"
    wait $!
    echo -e $not_archived
  fi
  wait
  echo ""
  date +"                            %H%M %A %d/%m/%y"
  echo "======================== FINISHED SWS/SHIMS ARCHIVE RUN ========================"
  echo ""
# Email the archive log
  mailx -s 'SWS/SHIMS archive log' -b $script_run_by, $owner < $log_name
  rm -f $log_name
  mass_list_name=`date +"/home/h06/sws-shims/mass_listing_%y%m%d_%H%M.txt"`
  moo ls -l moose:/adhoc/projects/sws-shims/rawdata >$mass_list_name
  sed 's/:/\ /g' $mass_list_name > /tmp/sws-shims_mass_list.tmp
  awk 'BEGIN{ OFS="\t"};{print $5,$6,$7$8,$11":"$12}' /tmp/sws-shims_mass_list.tmp >  $mass_list_name
  mv mass_listing_*.txt log_files/

# end
