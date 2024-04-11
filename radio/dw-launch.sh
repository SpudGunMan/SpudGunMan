#! /bin/bash
# This script is a simple launcher for Direwolf to set the modem parameters
# DE K7MHI version 0.4.11

# yad question dialog
SETTINGS=$(yad --form --width=600 --text-align=center --center --title="Direwolf Modem Selector" --text-align=center \
--image $LOGO --window-icon=$LOGO --image-on-top --separator="|" --item-separator="|" \
--text="<b>Direwolf Launcher</b>" \
--text="<b>Set the modem parameters for Direwolf</b>" \
--field="Mode":CB "1200|300|2400|4800|9600|AIS|EAS" \
--field="Sample Rate":CB "48000|44000" \
--field="Enable IL2P transmit":CB "no|yes" \
--field="IL2P inversion":CB "no|yes" \
--field="debug options -d " "" \
--button="Go For Launch":2 \
--button="Cancel":1)
CHOICE=$?

if [ $CHOICE = 1 ]; then
     exit 0
elif [ $CHOICE = 252 ]; then
     exit
elif [ $CHOICE = 2 ]; then
     MODE=$(echo $SETTINGS | awk -F "|" '{print $1}')
     BR=$(echo $SETTINGS | awk -F "|" '{print $2}')
     IL2P=$(echo $SETTINGS | awk -F "|" '{print $3}')
     IL2PR=$(echo $SETTINGS | awk -F "|" '{print $4}')
     DEBUG=$(echo $SETTINGS | awk -F "|" '{print $5}')
fi

# if IL2P set I for normal i for inverted, assuming the user knows what they are doing with this
if [ $IL2P = "yes" ]; then
     if IL2PR = "yes"; then
          IL2P="-i 1"
     else
          IL2P="-I 1"
     fi
else
     IL2P=""
fi

# if debug not empty pass string adding -d to start of string
if [ -n "$DEBUG" ]; then
     DEBUG="-d $DEBUG"
else
     DEBUG=""
fi

# launch direwolf with the modem settings desired and any other options
WOLF="direwolf -B $MODE -r $BR $IL2P $DEBUG"

echo "launching $WOLF"
# linux mint terminal launch with fancy title
if [[ $(whereis mate-terminal | grep bin) ]];then
     mate-terminal -t "direwolf TNC $MODE" -e "$WOLF"
else
     $WOLF
fi

exit 0
