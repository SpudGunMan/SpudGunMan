tool to gather and compile lego micropython tools and library back to a OEM hub after LEGO firmware update.
I commonly have accidental format to factory OEM flash and I have all my files lost and its a pain to gather them back up,
so a compiler and installer forked from the mpy-tools project's installer to more modular installer for any project

```
#!python3

# Run this on a Mac or Linux machine to create/update 'install_legolibs.py'
# Copy the contents of install_legolibs.py into an empty SPIKE/51515 project
# on the offical lego app And run to install. The transfer and program run 
# will take extra time. 
# 
# To restore to OEM, allow LEGO app to update your hub, library's will be removed.
#
# 
# installer idea from antonsmindstorms.com
#
# The following librarys will be checked and used if they are
# git cloned into the same folder as this project.
# by default if they exist they will be loaded
# to add your own just create a new item ih the compile_list
#
# https://github.com/antonvh/mpy-robot-tools 
# https://github.com/antonvh/UartRemote
# https://github.com/ceeoinnovations/SPIKEPrimeBackpacks
#
#
# Open the console/Debug and watch for notice to unplug USB BEFORE you upload/run
```
