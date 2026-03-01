#! /bin/bash 
# potactivate.sh
# POTA - Parks On The Air Activation Script
# Copyright 2026 Kelly Keeton K7MHI
# Licensed under the MIT License
# https://opensource.org/licenses/MIT
# Version 1.5

# This script is designed to help you activate a park for Parks On The Air
# It will create a log folder for the park and a lockfile to track progress
# It will also help you wrap up your activation by moving WSJT logs to the log folder
# Allowing for clean uploads to the POTA website

#user variables
LOTW_LOCATION="United States"
logFolder=~/Documents/log_archive/
WSJTLogFolder=~/.local/share/WSJT-X/
FLDIGLog=~/.fldigi/logs/logbook.adif
VARACLog=~/Documents/log_archive/Varac_qso_log.adi



#system variables
cd "$(dirname "$0")"
#date in UTC for POTA
date=$(date -u +%Y%m%d)
seperator=":"
LaunchGPSD2HAM="true"

echo
echo "*****************************************"
echo "POTA - Parks On The Air Activation Script"
echo "*****************************************"
echo

#check for lockfile
if [ -f ~/.pota-lock ]; then
    #read lockfile
    ParkLogFolder=$(cat ~/.pota-lock | cut -d$seperator -f1)
    MyPark=$(cat ~/.pota-lock | cut -d$seperator -f2)
    MyParkID=$(cat ~/.pota-lock | cut -d$seperator -f3)


    echo
    echo "POTA - Parks On The Air welcome back $(cat ~/.pota-call)"
    echo "You have an active activation in progress $MyPark, $MyParkID"
    echo "Would you like to wrap up your activation?"
    echo "Select 1 Yes or 2 No"
    echo

    select yn in "Yes-WrapUp" "No-Nevermind"; do
        case $yn in
            Yes*)
                if [ -d "$WSJTLogFolder" ]; then
                    mv "$WSJTLogFolder"wsjtx_log.adi "$ParkLogFolder"
                    mv "$WSJTLogFolder"wsjtx.log "$ParkLogFolder"
                    #replace file to keep conky from complaining
                    touch "$WSJTLogFolder"wsjtx.log
                    echo "Moved WSJT logs to $ParkLogFolder"

                    # if operated FT8 expected to find wsjtx_log.adi
                    if [ -f "$ParkLogFolder"wsjtx_log.adi ]; then
                        #process MY_SIG info on the logs
                        sed "s|<eor>|<MY_SIG:4>POTA <MY_SIG_INFO:6>$MyPark <eor>|g" "$ParkLogFolder"wsjtx_log.adi > "$ParkLogFolder"wsjtx_log_$MyPark.adi
                        echo "Processed WSJTX logs to $ParkLogFolder for Park $MyPark"
                    fi 
                    
                    #if operated SSB expected to find ssb.adi or SSB.adi
                    if [ -f "$ParkLogFolder"ssb.adi ]; then
                        #process MY_SIG info on the logs for ssb
                        sed "s|<eor>|<MY_SIG:4>POTA <MY_SIG_INFO:6>$MyPark <eor>|gI" "$ParkLogFolder"ssb.adi > "$ParkLogFolder"ssb_$MyPark.adi
                        echo "Processed ssb logs to $ParkLogFolder for Park $MyPark"
                    fi

                    #move fldigi logs if exist and touch new log to keep conky happy rename to fldigi_log_$MyPark.adi
                    if [ -d "$FLDIGLogFolder" ]; then
                        mv "$FLDIGLogFolder"logbook.adif "$ParkLogFolder"fldigi_log_$MyPark.adi
                        #process MY_SIG info on the logs for fldigi
                        sed "s|<eor>|<MY_SIG:4>POTA <MY_SIG_INFO:6>$MyPark <eor>|gI" "$ParkLogFolder"fldigi_log_$MyPark.adi > "$ParkLogFolder"fldigi_log_$MyPark.adi
                        echo "Processed fldigi logs to $ParkLogFolder for Park $MyPark"
                        echo "Moved fldigi logs to $ParkLogFolder"
                        touch "$FLDIGLogFolder"logbook.adif
                    fi

                    #move varac logs if exist and touch new log to keep conky happy rename to varac_log_$MyPark.adi
                    if [ -f "$VARACLog" ]; then
                        mv "$VARACLog" "$ParkLogFolder"varac_log_$MyPark.adi
                        #process MY_SIG info on the logs for varac
                        sed "s|<eor>|<MY_SIG:4>POTA <MY_SIG_INFO:6>$MyPark <eor>|gI" "$ParkLogFolder"varac_log_$MyPark.adi > "$ParkLogFolder"varac_log_$MyPark.adi
                        echo "Processed varac logs to $ParkLogFolder for Park $MyPark"
                        echo "Moved varac logs to $ParkLogFolder"
                        touch "$VARACLog"
                    fi   

                    echo 
                    read -p "Enter any activation notes: " notes
                    if [ -z "$notes" ]; then
                        notes="No notes provided"
                    else
                        echo "$notes" > "$ParkLogFolder"notes.txt
                        echo "Added notes to $ParkLogFolder"
                    fi
                    #get system uptime use for park work time estimate
                    uptime=$(uptime -p)
                    echo "$MyPark Working Time: $uptime" >> "$ParkLogFolder"notes.txt

                    #count contacts from all logs for reference
                    contactCount=$(grep -c "<call:" "$ParkLogFolder"wsjtx_log_$MyPark.adi)
                    contactCount=$((contactCount + $(grep -c "<call:" "$ParkLogFolder"ssb_$MyPark.adi)))
                    
                    echo "Total Contacts: $contactCount" >> "$ParkLogFolder"notes.txt
                    echo "Added contact count to notes.txt"


                else
                    echo "error moving $WSJTLogFolder dose not exist"
                    exit 1
                fi

                rm ~/.pota-lock
                echo "Lockfile removed"
                echo "73.."
                exit 0
                ;;
            No*)
                echo "Happy Activating 73.."
                #force time sync here
                # check for ntpd otherwise suggest to install
                if [[ $(whereis ntpd | grep bin) ]]; then
                    sudo ntpd -gq
                    echo "Time sync initiated"
                    exit 0
                else
                    echo "ntpd not found, please install ntpd with, sudo apt-get install ntp"
                    exit 1
                fi
                exit 0
                ;;
        esac
    done
fi

# Initialize callsign
if [ ! -f ~/.pota-call ]; then
    read -p "Enter your callsign: " callsignRAW
    # Convert to uppercase
    callsign=$(echo $callsignRAW | tr '[:lower:]' '[:upper:]')
    echo $callsign > ~/.pota-call
else
    callsign=$(cat ~/.pota-call)
    echo -e "Welcome Back: $callsign"
fi

# Initialize park
if [ ! -f ~/.pota-park ]; then
    #create park file (functionize this)
    echo "Please enter the park details.."
    read -p "Enter the park details(UsefullName): " parkID
    #remove spaces
    parkID=$(echo $parkID | tr -d '[:space:]')

    read -p "Enter the park designator(ie. US-3180): " parkDesignator
    # Convert to uppercase
    parkDesignator=$(echo $parkDesignator | tr '[:lower:]' '[:upper:]')
    echo "$parkDesignator$seperator$parkID" >> ~/.pota-park
    echo "Collected park: $parkDesignator, $parkID"
    park=$parkDesignator
    #end function
else
    echo "Select a park by entering the number or create a new park by selecting # NEW*PARK"
    select opt in $(cat ~/.pota-park) SEARCH NEW*PARK QUIT; do
        case $opt in
            NEW*PARK)
                #create park file (duplicate from above)
                echo "Please enter the park details.."
                read -p "Enter the park details(UsefullName): " parkID
                #remove spaces
                parkID=$(echo $parkID | tr -d '[:space:]')
                
                read -p "Enter the park designator(ie. US-3180): " parkDesignator
                # Convert to uppercase
                parkDesignator=$(echo $parkDesignator | tr '[:lower:]' '[:upper:]')
                echo "$parkDesignator$seperator$parkID" >> ~/.pota-park
                echo "Collected park: $parkDesignator, $parkID"
                park=$parkDesignator
                #end function
                break
                ;;
            SEARCH)
                #if found grid2pota.sh display parks
                if [ -f grid2pota.sh ]; then
                    bash grid2pota.sh
                else
                    echo "grid2pota.sh not found"
                fi
                ;;
            QUIT)
                echo "73.."
                exit 0
                ;;
            *)
                park=$(echo $opt | cut -d$seperator -f1)
                parkID=$(echo $opt | cut -d$seperator -f2)
                if [ -z "$park" ]; then
                    echo "Invalid selection"
                else
                    echo "Activating: $park, $parkID"
                    break
                fi
                ;;
        esac
    done
fi

# Build log folders for archive
if [ -d $logFolder ]; then
    mkdir -p "$logFolder$parkID"-"$park"-"$date"
    echo "Created log folder: $parkID-$park-$date in $logFolder"
else
    echo "cant make log folder: $parkID-$park-$date in $logFolder"
fi

#write a lockfile with current progress
echo "$logFolder$parkID-$park-$date/$seperator$park$seperator$parkID" > ~/.pota-lock
echo "Lockfile created with current progress in ~/.pota-lock"

#optionally launch grid2ham.sh
if [ $LaunchGPSD2HAM == "true" ]; then
    if [ -f grid2app.sh ]; then
        echo "Attempting gpsd2grid acuire, will auto-exit in 10 seconds if not found or no gpsd data"
        gps=$(timeout 10s bash grid2app.sh)
    fi
fi

#touch conky file to keep fresh
touch ~/.conkyrc

echo "Happy Activating, re-run potActivate script to wrap up your activation."
echo "73.."

exit 0