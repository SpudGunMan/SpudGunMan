/lego/SmartCityTrain.py 

  The purpose of this was to replace the Lego Firmware on the [City Train](https://www.lego.com/en-us/product/passenger-train-60197) kits using the City Hub with more features and hack around in Pybricks. Specifically needed to add smarts to keep each remote working correctly with each train on the track. Also to have full use of the buttons on the remote. Including a ATO (Automatic Train Operation) function. Finally there is watchdog timeout and power off for being unused.

   Support for Lego Lights, turning them on and off with the remote (see code for more)

  Another feature is the use of an optional light/distance sensor. This has a primary purpose of detecting an engine tilt or tip over to halt the motor functions, as they commonly crash due to shenanigans, and battery life is precious. it should be disabled if you run above ground track (or alter your track). It also has the pybricks example code embedded to enable speed control under various conditions, also allows ATO with color indicators added to the track, for further automation. 

  Automation with Pybricks messaging for hub to hub automation and multi hub features coming soon

  found [here](https://github.com/SpudGunMan/SpudGunMan/blob/main/Lego/Smart-CityTrain.py) 
