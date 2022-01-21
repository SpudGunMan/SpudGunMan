/lego/[legolibs](https://github.com/SpudGunMan/SpudGunMan/tree/main/Lego/legolibs)

  tool to gather and compile lego micropython tools and library back to a OEM hub after LEGO firmware update. I commonly have accidental format to factory OEM flash and I have all my files lost and its a pain to gather them back up, so a compiler and installer forked from the mpy-tools project's installer to more modular installer for any project

 - Lego Mindstorms 51515 and Lego Spike Hub

/lego/[SmartCityTrain.py](https://github.com/SpudGunMan/SpudGunMan/blob/main/Lego/Smart-CityTrain.py) 

  The purpose of this was to replace the Lego Firmware on the [City Train](https://www.lego.com/en-us/product/passenger-train-60197) kits using the City Hub with more features and hack around in Pybricks. Specifically needed to add smarts to keep each remote working correctly with each train on the track. Also to have full use of the buttons on the remote. Including a ATO (Automatic Train Operation) function. Finally there is watchdog timeout and power off for being unused.

   Support for Lego Lights, turning them on and off with the remote (see code for more)

  Another feature is the use of an optional light/distance sensor. This has a primary purpose of detecting an engine tilt or tip over to halt the motor functions, as they commonly crash due to shenanigans, and battery life is precious. it should be disabled if you run above ground track (or alter your track). It also has the pybricks example code embedded to enable speed control under various conditions, also allows ATO with color indicators added to the track, for further automation. 

  Automation with Pybricks messaging for hub to hub automation and multi hub features
