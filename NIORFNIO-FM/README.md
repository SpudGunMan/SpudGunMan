# NIO-T15B

- [Manual](niodesktop_tb_series.pdf)
- Hardware [details](spec.txt)

The device will play MP3 Files in Alpha-order on a mmc/USB FAT32 as priority over all other methods. Followed by, BT followed by Analog.
The Mic will mix into the feed.


## Software
Dont get your hopes up..

- [NIO](NIO-PC-RADIO-CONTROL.zip) PC RADIO CONTROL
  - password 123, and 123456? from facebook it appears to be a virus
- Softwre reported to work with the hardware https://stationplaylist.com/download.html
- The USB seems to have nothing in linux so .. forget about it.


```
sudo apt-get install mplayer
sudo apt-get install espeak
```


# Google speak Code
```
#!/bin/bash
say() { local IFS=+;/usr/bin/mplayer -ao pulse -volume 70 -noconsolecontrols "http://translate.google.com/translate_tts?ie=UTF-8&client=tw-ob&q=$*&tl=en"; }
say $*
```
