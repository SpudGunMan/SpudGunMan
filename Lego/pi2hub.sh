#!/bin/bash
# Pi2Hub is for conecting via Bluetooth to Lego Hub, tested with BlackberryDebian
# this will redirect /bind a port using CLI commands for automation or projects
#
# pi2hub.sh
# use 'bluetoothctl scan on' to hunt for your device MAC
HUB0="2C:AB:33:5D:00:00"
# tested on bullseye and rpi3
# requirements: sudo apt-get install bluetooth libbluetooth-dev screen
# optional: sudo python3 -m pip install pybluez
# optional: python3 -m pip install rshell
#
echo "pi2LegoHub BT/TTY connector for linux shell on raspberry pi"
echo "Starting BT handler, connect hub now by pressing BT button."
echo
bluetoothctl -- pair $HUB0
#bluetoothctl pair $HUB0
sleep 3
bluetoothctl -- trust $HUB0
#bluetoothctl trust $HUB0
#
#bluetoothctl -- connect $HUB0
sleep 2
bluetoothctl -- paired-devices
echo
rfcomm bind rfcomm0 $HUB0
ls -l /dev/rfcomm0
echo
echo "/dev/rfcomm0 is ready for use by system if no errors. leave this window open."
#launch scripts or other things here if you want part of this one script
#python3 my_script.py
echo
echo -ne '\x03' > /dev/rfcomm0
echo "lego connected run your scripts now, in a new window"
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