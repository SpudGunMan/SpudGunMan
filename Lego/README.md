SpudGunMan Lego Hacking Spike and 51515 Mindstorms Lego Hubs

/[pi2hub](pi2hub.sh)
  - inital work to allow debian raspberry pi to connect to lego hub factory firmware this is just an automation script.

/lego/UART/[OpenMV](https://github.com/SpudGunMan/SpudGunMan/tree/main/Lego/UART/OpenMV)
  - script of lego spike/51515 and OpenMV using UART shell for data, uses [uartremote](https://github.com/antonvh/UartRemote) library

/lego/[legolibs](https://github.com/SpudGunMan/SpudGunMan/tree/main/Lego/legolibs)

  - tool to gather and compile lego micropython tools and libaries back to a OEM hub after LEGO firmware update. Compiler and installer forked from the mpy
  - more modular installer for any project, 
  
    items in your project directory are safe unless content refereshed this allows builk depoyment of bricks for class etc. For quicker development edit the legoHub_install_path variable in base_script.py

/lego/CityHub/Train/[SmartCityTrain.py](https://github.com/SpudGunMan/SpudGunMan/blob/main/Lego/CityHub/Train/Smart-CityTrain.py) 

  - The purpose of this was to replace the Lego Firmware on the [City Train](https://www.lego.com/en-us/product/passenger-train-60197) kits using the City Hub with more features and hack around in Pybricks. 
  - Remote naing, to keep each remote working correctly with each train on the track. 
  - full use of the buttons on the remote. 
    -Including a ATO (Automatic Train Operation) function. 
  - watchdog timeout and power off function with RC button
  - Support for Lego Lights, turning them on and off with the remote
  - optional light/distance sensor. This has a primary purpose of detecting an engine tilt or tip over to halt the motor functions, as they commonly crash due to shenanigans, and battery life is precious. it should be disabled if you run above ground track (or alter your track). It also has the pybricks example code embedded to enable speed control under various conditions, allows ATO with color indicators added to the track, for further automation. 
  - Automation with Pybricks messaging for hub to hub automation and multi hub features
