#! /bin/bash 
# potactivate.sh
# POTA - Parks On The Air Activation Script
# Copyright 2026 Kelly Keeton K7MHI
# Licensed under the MIT License
# https://opensource.org/licenses/MIT
# Version 2.0.0

# This script is designed to help you activate a park for Parks On The Air
# It will create a log folder for the park and a lockfile to track progress
# It will also help you wrap up your activation by moving WSJT logs to the log folder
# Allowing for clean uploads to the POTA website

#user variables
LOTW_LOCATION="United States"
logFolder=~/Documents/log_archive/
WSJTLogFolder=~/.local/share/WSJT-X/
FLDIGLogFolder=~/.fldigi/logs/
VARACLog=~/Documents/log_archive/VarAC_qso_log.adi



#system variables
cd "$(dirname "$0")"
#date in UTC for POTA
date=$(date -u +%Y%m%d)
seperator=":"
LaunchGPSD2HAM="true"

# Lightweight menu picker: arrow keys in TTY, numeric fallback otherwise.
menu_pick() {
    local prompt="$1"
    shift
    local -a opts=("$@")
    local count=${#opts[@]}
    local key
    local selected=0
    local term_lines=24
    local max_visible=10
    local window_start=0
    local menu_drawn_lines=0

    if [ "$count" -eq 0 ]; then
        return 1
    fi

    # Non-interactive fallback (e.g. piped input/testing)
    if [[ ! -t 0 || ! -t 1 ]]; then
        echo "$prompt"
        for i in "${!opts[@]}"; do
            printf '%d) %s\n' "$((i + 1))" "${opts[i]}"
        done

        while true; do
            read -r -p "Enter selection number: " key
            if [[ "$key" =~ ^[0-9]+$ ]] && [ "$key" -ge 1 ] && [ "$key" -le "$count" ]; then
                MENU_INDEX=$((key - 1))
                MENU_VALUE="${opts[MENU_INDEX]}"
                return 0
            fi
            echo "Invalid selection. Try again."
        done
    fi

    echo "$prompt"
    echo "Use Up/Down arrows and Enter (or press number keys)."

    _draw_menu() {
        local j
        local end
        menu_drawn_lines=0
        end=$((window_start + max_visible - 1))
        if [ "$end" -ge "$count" ]; then
            end=$((count - 1))
        fi

        if [ "$window_start" -gt 0 ]; then
            printf '\r\033[K  ^ more\n'
            menu_drawn_lines=$((menu_drawn_lines + 1))
        fi

        for ((j=window_start; j<=end; j++)); do
            if [ "$j" -eq "$selected" ]; then
                printf '\r\033[K> %s\n' "${opts[j]}"
            else
                printf '\r\033[K  %s\n' "${opts[j]}"
            fi
            menu_drawn_lines=$((menu_drawn_lines + 1))
        done

        if [ "$end" -lt "$((count - 1))" ]; then
            printf '\r\033[K  v more\n'
            menu_drawn_lines=$((menu_drawn_lines + 1))
        fi
    }

    if command -v tput >/dev/null 2>&1; then
        term_lines=$(tput lines 2>/dev/null || echo 24)
    fi
    max_visible=$((term_lines - 8))
    if [ "$max_visible" -lt 5 ]; then
        max_visible=5
    fi

    _draw_menu
    while true; do
        IFS= read -rsn1 key
        if [[ "$key" == $'\x1b' ]]; then
            IFS= read -rsn2 key
            key=$'\x1b'"$key"
        fi

        case "$key" in
            $'\x1b[A')
                selected=$(((selected - 1 + count) % count))
                ;;
            $'\x1b[B')
                selected=$(((selected + 1) % count))
                ;;
            "")
                MENU_INDEX=$selected
                MENU_VALUE="${opts[MENU_INDEX]}"
                printf '\n'
                return 0
                ;;
            [1-9])
                if [ "$key" -le "$count" ]; then
                    MENU_INDEX=$((key - 1))
                    MENU_VALUE="${opts[MENU_INDEX]}"
                    printf '\n'
                    return 0
                fi
                ;;
            q|Q)
                return 1
                ;;
        esac

        if [ "$selected" -lt "$window_start" ]; then
            window_start=$selected
        elif [ "$selected" -ge "$((window_start + max_visible))" ]; then
            window_start=$((selected - max_visible + 1))
        fi

        printf '\033[%dA' "$menu_drawn_lines"
        _draw_menu
    done
}

# Force time sync using whichever service is available.
force_time_sync() {
    local synced="false"
    local sudo_ready="false"

    echo "Attempting hard time sync..."

    # Try to obtain sudo credentials once if needed (interactive when possible).
    if command -v sudo >/dev/null 2>&1; then
        if sudo -n true >/dev/null 2>&1; then
            sudo_ready="true"
        elif [[ -t 0 && -t 1 ]]; then
            echo "Admin privileges may be required for time sync."
            if sudo -v; then
                sudo_ready="true"
            else
                echo "Sudo authentication failed; continuing with non-privileged methods."
            fi
        fi
    fi

    if command -v chronyc >/dev/null 2>&1; then
        # Chrony path: prefer direct control, then sudo if authenticated.
        if chronyc -a makestep >/dev/null 2>&1; then
            chronyc sources -v || true
            synced="true"
        elif [ "$sudo_ready" = "true" ] && sudo chronyc -a makestep >/dev/null 2>&1; then
            sudo chronyc sources -v || true
            synced="true"
        fi
    fi

    if [ "$synced" != "true" ] && command -v ntpd >/dev/null 2>&1; then
        # NTP one-shot sync against configured sources.
        if ntpd -gq >/dev/null 2>&1; then
            synced="true"
        elif [ "$sudo_ready" = "true" ] && sudo ntpd -gq >/dev/null 2>&1; then
            synced="true"
        fi
    fi

    if [ "$synced" != "true" ] && command -v sntp >/dev/null 2>&1; then
        # Fallback if only sntp exists.
        if sntp -sS pool.ntp.org >/dev/null 2>&1; then
            synced="true"
        elif [ "$sudo_ready" = "true" ] && sudo sntp -sS pool.ntp.org >/dev/null 2>&1; then
            synced="true"
        fi
    fi

    if [ "$synced" = "true" ]; then
        echo "Time sync complete."
    else
        echo "Unable to sync time automatically (chrony/ntp unavailable or permission denied)."
    fi
}

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
    echo

    while true; do
        if ! menu_pick "Wrap up activation?" "Sync-Time-Now" "Yes-WrapUp" "No-Nevermind"; then
            echo "73.."
            exit 0
        fi

        case "$MENU_VALUE" in
            Yes*)
                if [ -d "$WSJTLogFolder" ]; then
                    # Move all wsjtx_log*.adi files
                    find "$WSJTLogFolder" -maxdepth 1 -name 'wsjtx_log*.adi' -type f -exec mv {} "$ParkLogFolder" \;
                    mv "$WSJTLogFolder"wsjtx.log "$ParkLogFolder"
                    #replace file to keep conky from complaining
                    touch "$WSJTLogFolder"wsjtx.log
                    printf '%s\n' "<ADIF_VER:5>3.1.1" "<EOH>" > "$WSJTLogFolder"wsjtx_log.adi
                    echo "Moved WSJT logs to $ParkLogFolder"

                    # Process all wsjtx_log*.adi files found
                    for wsjtx_file in "$ParkLogFolder"wsjtx_log*.adi; do
                        if [ -f "$wsjtx_file" ]; then
                            #process MY_SIG info on the logs
                            sed "s|<eor>|<MY_SIG:4>POTA <MY_SIG_INFO:6>$MyPark <eor>|g" "$wsjtx_file" > "$wsjtx_file".tmp && mv "$wsjtx_file".tmp "$wsjtx_file"
                            echo "Processed WSJTX logs $(basename "$wsjtx_file") to $ParkLogFolder for Park $MyPark"
                        fi
                    done

                    echo "Moved WSJT logs to $ParkLogFolder"
                fi

                #move fldigi logs if exist and touch new log to keep conky happy rename to fldigi_log_$MyPark.adi
                if [ -d "$FLDIGLogFolder" ] && [ -f "$FLDIGLogFolder"logbook.adif ]; then
                    mv "$FLDIGLogFolder"logbook.adif "$ParkLogFolder"fldigi_log_$MyPark.adi
                    #process MY_SIG info on the logs for fldigi
                    tmp_fldigi_file=$(mktemp)
                    sed "s|<eor>|<MY_SIG:4>POTA <MY_SIG_INFO:6>$MyPark <eor>|gI" "$ParkLogFolder"fldigi_log_$MyPark.adi > "$tmp_fldigi_file" && mv "$tmp_fldigi_file" "$ParkLogFolder"fldigi_log_$MyPark.adi
                    echo "Processed fldigi logs to $ParkLogFolder for Park $MyPark"
                    echo "Moved fldigi logs to $ParkLogFolder"
                    printf '%s\n' "<ADIF_VER:5>3.1.1" "<EOH>" > "$FLDIGLogFolder"logbook.adif
                fi

                #move varac logs if exist and touch new log to keep conky happy rename to varac_log_$MyPark.adi
                if [ -f "$VARACLog" ]; then
                    mv "$VARACLog" "$ParkLogFolder"varac_log_$MyPark.adi
                    #process MY_SIG info on the logs for varac
                    tmp_varac_file=$(mktemp)
                    sed "s|<eor>|<MY_SIG:4>POTA <MY_SIG_INFO:6>$MyPark <eor>|gI" "$ParkLogFolder"varac_log_$MyPark.adi > "$tmp_varac_file" && mv "$tmp_varac_file" "$ParkLogFolder"varac_log_$MyPark.adi
                    echo "Processed varac logs to $ParkLogFolder for Park $MyPark"
                    echo "Moved varac logs to $ParkLogFolder"
                    printf '%s\n' "<ADIF_VER:5>3.1.1" "<EOH>" > "$VARACLog"
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

                rm ~/.pota-lock
                echo "Lockfile removed"
                echo "73.."
                exit 0
                ;;
            No*)
                echo "Happy Activating 73.."
                exit 0
                ;;
            Sync*)
                force_time_sync
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
    echo
    echo "=============================="
    echo "   Select Park for Activation"
    echo "=============================="

    park_entries=()
    while IFS= read -r line; do
        [ -n "$line" ] && park_entries+=("$line")
    done < ~/.pota-park

    # Build display options
    options=()
    for entry in "${park_entries[@]}"; do
        p_designator=$(echo "$entry" | cut -d"$seperator" -f1)
        p_name=$(echo "$entry" | cut -d"$seperator" -f2)
        options+=("$p_designator - $p_name")
    done

    options+=("SEARCH (find nearby parks)")
    options+=("NEW PARK")
    options+=("QUIT")

    while true; do
        if ! menu_pick "Select Park for Activation" "${options[@]}"; then
            echo "73.."
            exit 0
        fi

        search_idx=$((${#park_entries[@]}))
        new_idx=$((${#park_entries[@]} + 1))
        quit_idx=$((${#park_entries[@]} + 2))

        if [[ "$MENU_INDEX" -ge 0 && "$MENU_INDEX" -lt "${#park_entries[@]}" ]]; then
            selected="${park_entries[$MENU_INDEX]}"
            park=$(echo "$selected" | cut -d"$seperator" -f1)
            parkID=$(echo "$selected" | cut -d"$seperator" -f2)
            echo "Activating: $park, $parkID"
            break

        elif [[ "$MENU_INDEX" -eq "$search_idx" ]]; then
            if [ -f grid2pota.sh ]; then
                bash grid2pota.sh
            else
                echo "grid2pota.sh not found"
            fi

        elif [[ "$MENU_INDEX" -eq "$new_idx" ]]; then
            echo "Please enter the park details.."
            read -r -p "Enter the park details (UsefulName): " parkID
            parkID=$(echo "$parkID" | tr -d '[:space:]')

            read -r -p "Enter the park designator (ie. US-3180): " parkDesignator
            parkDesignator=$(echo "$parkDesignator" | tr '[:lower:]' '[:upper:]')

            echo "$parkDesignator$seperator$parkID" >> ~/.pota-park
            echo "Collected park: $parkDesignator, $parkID"
            park="$parkDesignator"
            break

        elif [[ "$MENU_INDEX" -eq "$quit_idx" ]]; then
            echo "73.."
            exit 0

        else
            echo "Invalid selection. Try again."
        fi
    done
fi

# Build a unique log folder for archive and never overwrite prior activations.
baseLogFolder="$logFolder$parkID-$park-$date"
ParkLogFolder="$baseLogFolder"
suffix=2

while [ -e "$ParkLogFolder" ]; do
    ParkLogFolder="$baseLogFolder-$suffix"
    suffix=$((suffix + 1))
done

if [ -d "$logFolder" ]; then
    mkdir -p "$ParkLogFolder"
    echo "Created log folder: $(basename "$ParkLogFolder") in $logFolder"
else
    echo "cant make log folder: $(basename "$ParkLogFolder") in $logFolder"
fi

#write a lockfile with current progress
echo "$ParkLogFolder/$seperator$park$seperator$parkID" > ~/.pota-lock
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