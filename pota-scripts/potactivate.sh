#! /bin/bash potactivate.sh
# POTA - Parks On The Air Activation Script
# Copyright 2023 Kelly Keeton K7MHI
# Licensed under the MIT License
# https://opensource.org/licenses/MIT
# Version 1.2.1

# This script is designed to help you activate a park for Parks On The Air
# It will create a log folder for the park and a lockfile to track progress
# It will also help you wrap up your activation by moving WSJT logs to the log folder
# Allowing for clean uploads to the POTA website


# Initialize variables
cd "$(dirname "$0")"
logFolder=~/Documents/log_archive/
WSJTLogFolder=~/.local/share/WSJT-X/
date=$(date +%Y%m%d)
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

    #Guess Activation count for WSJT
    if [ -d $WSJTLogFolder ]; then
        #count line numbers of log
        count=$(wc -l "$WSJTLogFolder"wsjt.log | cut -d' ' -f1)
        if [ -z count ]; then
            count=0
        fi

        if [[ $count -gt 10 ]]; then
            echo "CONGRATS WSJT has $count QSOs"
        else
            echo "You didnt activate yet, WSJT has $count QSOs"
        fi
    fi

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
                else
                    echo "error moving $WSJTLogFolder logs $ParkLogFolder"
                fi

                rm ~/.pota-lock
                echo "Lockfile removed"
                echo "73.."
                exit 0
                ;;
            No*)
                echo "Happy Activating 73.."
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

    read -p "Enter the park designator(ie. K-3180): " parkDesignator
    # Convert to uppercase
    parkDesignator=$(echo $parkDesignator | tr '[:lower:]' '[:upper:]')
    echo "$parkDesignator$seperator$parkID" >> ~/.pota-park
    echo "Collected park: $parkDesignator, $parkID"
    park=$parkDesignator
    #end function
else
    echo "Select a park by entering the number or create a new park by selecting # NEW*PARK"
    select opt in $(cat ~/.pota-park) NEW*PARK QUIT; do
        case $opt in
            NEW*PARK)
                #create park file (duplicate from above)
                echo "Please enter the park details.."
                read -p "Enter the park details(UsefullName): " parkID
                #remove spaces
                parkID=$(echo $parkID | tr -d '[:space:]')


                read -p "Enter the park designator(ie. K-3180): " parkDesignator
                # Convert to uppercase
                parkDesignator=$(echo $parkDesignator | tr '[:lower:]' '[:upper:]')
                echo "$parkDesignator$seperator$parkID" >> ~/.pota-park
                echo "Collected park: $parkDesignator, $parkID"
                park=$parkDesignator
                #end function
                break
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
