#!/bin/bash
HUB0="2C:AB:33:5D:00:00"
echo "Check for SUDO"
echo "lego 2 PC BT connector"
#bluetoothctl pair $HUB0
#bluetoothctl trust $HUB0
echo "Starting BT..."
echo
bluetoothctl -- pair $HUB0
sleep 3
bluetoothctl -- trust $HUB0
#bluetoothctl -- connect $HUB0
sleep 2
bluetoothctl -- paired-devices
echo
rfcomm bind rfcomm0 $HUB0
ls -l /dev/rfcomm0
echo "/dev/rfcomm0 is ready for use by system if no errors. leave this window open."
#launch scripts or other things here
echo
echo -ne '\x03' > /dev/rfcomm0
echo "lego connected run your scripts now..."
echo "or REPL vis: screen /dev/rfcomm0"
echo "or      via: rshell -p /dev/rfcomm0"
echo
read -p "ready to release rfcomm? " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
    echo "*** early exit ***"
    echo
    echo "rfcomm release 0"
    echo "bluetoothctl disconnect " +  $HUB0
    echo
    echo "remember to ports manually!"
    exit 1
fi
echo "closing ports"
rfcomm release 0
bluetoothctl disconnect $HUB0


#EOF