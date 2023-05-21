#! /bin/bash potadify.sh
# make 'em POTA friendly
# MIT License Kelly Keeton K7MHI 2023
# Version 1.0.0
# requires YAD if not presented wth a file  - sudo apt-get install yad
# script to clean up adi files for POTA processing, mostly focused on simple WSJT-X logs and ADIF files missing the MY_SIG_INFO field


# if file on the command line use that
if [ -n "$1" ]; then
    adifile=$1
    echo "Using $adifile"
else
    # get the adi file with YAD GUI
    adifile=$(yad --title "POTAdi-fy select adi file for processing" --file)
    if [ -z "$adifile" ]; then
        echo "No file selected exiting"
        exit 1
    else 
        echo "Examining $adifile for POTA compliance"
    fi
fi

#get directory of the adi file
adir=$(dirname "$adifile")

# check for presence of SIG_INFO
if grep -q "MY_SIG:4>POTA" "$adifile"; then
    #get record from <MY_SIG_INFO:6> to <
    siginfo=$(grep -o '<MY_SIG_INFO:6>.*<' "$adifile" | cut -d'>' -f2 | sed 's/ <//g')
    echo "SIG_INFO found, if any of the following dont match halt and find out what went wrong"
    echo $siginfo

    #get first entery in $siginfo for Park number
    MyPark=$(echo $siginfo | cut -d' ' -f1)

    #get new park number
    if [ -f ~/.pota-park ]; then
        echo "Select a park by entering the number"
        select opt in $(cat ~/.pota-park) QUIT; do
            case $opt in
                QUIT)
                    echo "exiting"
                    exit 0
                    ;;
                *)
                    NewPark=$(echo $opt | cut -d: -f1)
                    echo "Selected park: $NewPark"
                    break
                    ;;
            esac
        done
    else
        read -p "No park file found, Enter the park designator(ie. K-4563): " NewPark
        # Convert to uppercase
        NewPark=$(echo $NewPark | tr '[:lower:]' '[:upper:]')
        #confirm matches K-####
        if [[ ! $NewPark =~ ^K-[0-9]{4}$ ]]; then
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
    read -p "SIG_INFO not found correct and add the SIG_INFO field? " yn
    case $yn in
        [Yy]* ) 
            echo "adding SIG_INFO field"

            #get park number
            if [ -f ~/.pota-park ]; then
                echo "Select a park by entering the number or create a new park by selecting # NEW*PARK"
                select opt in $(cat ~/.pota-park) QUIT; do
                    case $opt in
                        QUIT)
                            echo "exiting"
                            exit 0
                            ;;
                        *)
                            MyPark=$(echo $opt | cut -d: -f1)
                            echo "Selected park: $MyPark"
                            break
                            ;;
                    esac
                done
            else
                read -p "No park file found, Enter the park designator(ie. K-4563): " MyPark
                # Convert to uppercase
                MyPark=$(echo $MyPark | tr '[:lower:]' '[:upper:]')
                #confirm matches K-####
                if [[ ! $MyPark =~ ^K-[0-9]{4}$ ]]; then
                    echo "Invalid park designator format"
                    exit 1
                fi
            fi

            #if file contains <eor> then add MY_SIG_INFO
            if grep -q "<eor>" "$adifile"; then
                echo "eor found adding MY_SIG_INFO"
                sed 's/<eor>/<MY_SIG:4>POTA <MY_SIG_INFO:6>$MyPark <eor>/g' "$adifile" > "$adir"/$(basename "$adifile" .adi)_$MyPark.adi
            else
                echo "EOR found adding MY_SIG_INFO"
                sed 's/<EOR>/<MY_SIG:4>POTA <MY_SIG_INFO:6>$MyPark <EOR>/g' "$adifile" > "$adir"/$(basename "$adifile" .adi)_$MyPark.adi
            fi

            echo "come back again to process these further if needed! 73.."
            exit 0
        ;;
        [Nn]* ) echo "exiting"; exit;;
        * ) echo "Please answer yes or no.";;
    esac

fi

echo "73.."
exit 0
