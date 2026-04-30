#! /bin/bash 
# potadify.sh
# make 'em POTA friendly
# MIT License Kelly Keeton K7MHI 2026
# Version 1.5.0
# requires YAD if not presented wth a file  - sudo apt-get install yad
# script to clean up adi files for POTA processing, mostly focused on simple WSJT-X logs and ADIF files missing the MY_SIG_INFO field

# set variables
logFolder=~/Documents/log_archive/

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

# if file specified on command line use it otherwise prompt for file
if [ -z "$1" ]; then
    # check for YAD
    if ! [ -x "$(command -v yad)" ]; then
        echo 'ERROR: try: sudo apt-get install yad' >&2
        exit 1
    fi

    #set yad start directory 
    if ! [ -d $logFolder ]; then
        echo "Missing $logFolder"
    else 
        cd $logFolder
    fi

    # prompt for file
    adifile=$(yad --file --title="POTAdi-FY by K7MHI Select ADIF file to process" --fixed --width=800 --height=400)
    if [ -z "$adifile" ]; then
        echo "No file selected exiting"
        exit 1
    else 
        echo "Examining $adifile for POTA compliance"
    fi
else
    # use file from command line
    adifile=$1
    echo "Examining $adifile for POTA compliance"
fi


#get directory of the adi file
adir=$(dirname "$adifile")

# check for presence of SIG_INFO
if grep -q "MY_SIG:4>POTA" "$adifile"; then
    #get record from <MY_SIG_INFO:6> to <
    siginfo=$(grep -o '<MY_SIG_INFO:6>.*<' "$adifile" | cut -d'>' -f2 | sed 's/ <//g')
    
    #might shut this off once you trust the script
    echo "SIG_INFO found, if any of the following dont match halt and find out what went wrong"
    echo $siginfo
    echo "SIG_INFO found, if any of the preceeding didnt match halt and find out what went wrong"

    #get first entery in $siginfo for Park number
    MyPark=$(echo $siginfo | cut -d' ' -f1)

    #get new park number the .pota-park file if it exists is from potactivate.sh by yours truly K7MHI its a list of parks you have activated
    # US-####:ParkName is the formatting FYI
    # so if your ~/.pota-park file has a lot or only the ones you need .. if it looks like this.. (no #s single park per line)
    #
    #US-1234:TwoFerPark
    #US-5678:TrailHead
    #
    #you will only see a menu with those two "enhancer" parks while will by written to new adi file

    if [ -f ~/.pota-park ]; then
        park_entries=()
        while IFS= read -r line; do
            [ -n "$line" ] && park_entries+=("$line")
        done < ~/.pota-park

        park_options=()
        for entry in "${park_entries[@]}"; do
            p_designator=$(echo "$entry" | cut -d":" -f1)
            p_name=$(echo "$entry" | cut -d":" -f2)
            park_options+=("$p_designator - $p_name")
        done
        park_options+=("QUIT")

        if ! menu_pick "Select a NEW park to replace $MyPark" "${park_options[@]}"; then
            echo "exiting"
            exit 0
        fi

        quit_idx=${#park_entries[@]}
        if [ "$MENU_INDEX" -eq "$quit_idx" ]; then
            echo "exiting"
            exit 0
        fi

        NewPark=$(echo "${park_entries[$MENU_INDEX]}" | cut -d":" -f1)
        echo "Selected park: $NewPark"
    else
        read -p "No park file found, Enter the park designator(ie. US-4563): " NewPark
        # Convert to uppercase
        NewPark=$(echo $NewPark | tr '[:lower:]' '[:upper:]')
        #confirm matches US-####
        if [[ ! $NewPark =~ ^US-[0-9]{4}$ ]]; then
            echo "Invalid park designator format"
            exit 1
        fi
    fi

    # replace park number in $aidfile with $NewPark and copy to new filename_$NewPark.adi
    echo "Replacing $MyPark with $NewPark"
    sed "s/$MyPark/$NewPark/g" "$adifile" > "$adir"/$(basename "$adifile" .adi)_$NewPark.adi
    echo "New file created: $adir/$(basename "$adifile" .adi)_$NewPark.adi"
    exit 0
else
    if menu_pick "SIG_INFO not found. Add the SIG_INFO field?" "Yes-Add-SIG_INFO" "No-Exit"; then
        case "$MENU_VALUE" in
        Yes*) 
            echo "adding SIG_INFO field"

            #get park number
            if [ -f ~/.pota-park ]; then
                park_entries=()
                while IFS= read -r line; do
                    [ -n "$line" ] && park_entries+=("$line")
                done < ~/.pota-park

                park_options=()
                for entry in "${park_entries[@]}"; do
                    p_designator=$(echo "$entry" | cut -d":" -f1)
                    p_name=$(echo "$entry" | cut -d":" -f2)
                    park_options+=("$p_designator - $p_name")
                done
                park_options+=("QUIT")

                if ! menu_pick "Select a park for SIG_INFO" "${park_options[@]}"; then
                    echo "exiting"
                    exit 0
                fi

                quit_idx=${#park_entries[@]}
                if [ "$MENU_INDEX" -eq "$quit_idx" ]; then
                    echo "exiting"
                    exit 0
                fi

                MyPark=$(echo "${park_entries[$MENU_INDEX]}" | cut -d":" -f1)
                echo "Selected park: $MyPark"
            else
                read -p "No park file found, Enter the park designator(ie. US-4563): " MyPark
                # Convert to uppercase
                MyPark=$(echo $MyPark | tr '[:lower:]' '[:upper:]')
                #confirm matches US-####
                if [[ ! $MyPark =~ ^US-[0-9]{4}$ ]]; then
                    echo "Invalid park designator format"
                    exit 1
                fi
            fi

            #if file contains <eor> then add MY_SIG_INFO
            if grep -q "<eor>" "$adifile"; then
                echo "eor found adding MY_SIG_INFO"
                sed "s|<eor>|<MY_SIG:4>POTA <MY_SIG_INFO:6>$MyPark <eor>|g" "$adifile" > "$adir"/$(basename "$adifile" .adi)_$MyPark.adi
            else
                echo "EOR found adding MY_SIG_INFO"
                sed "s|<EOR>|<MY_SIG:4>POTA <MY_SIG_INFO:6>$MyPark <EOR>|g" "$adifile" > "$adir"/$(basename "$adifile" .adi)_$MyPark.adi
            fi

            echo "come back again to process these further if needed! 73.."
            exit 0
        ;;
        No*)
            echo "exiting"
            exit 0
            ;;
        esac
    else
        echo "exiting"
        exit 0
    fi

fi

echo "73.."
exit 0
