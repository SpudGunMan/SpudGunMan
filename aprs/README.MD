# Micro­Trak RTG FA

The [Manual](MicroTrak_RTG_FA_Manual_v1.8-2.pdf) describes the hardware and firmware functions

The [Config Manual](TinyTrak3_Config_Manual_v1.4.pdf) is also mandatory to review as it has lots of nerdy bits.

The TLDR version of it all...

Following is for temp return in F
```
PARM.Battery,Temp
UNIT.Volts,Deg.F
EQNS.0,0.0293,0,0,0.879,-­459.67
```
Following for temp return in C
```
PARM.Battery,Temp
UNIT.Volts,Deg.C
EQNS.0,0.0293,0,0,0.489,-­273.15
```

enter the data into [findu send tool](http://www.findu.com/cgi­bin/entermsg.cgi)
I have found issues with the EQNS, I cant send it to myself (If using a SSID it works FROM TO cant be the same call possibly)

More on EQNS on page 70 of the [APRS whitepapers](http://www.aprs.org/doc/APRS101.PDF)

# Hardware modifications
![mtrak.jpeg](microtrak)
the “SW” and “T” markings are reversed. “T” is the secondary configuration switch input, and “SW” is the analog telemetry input photo here shows functioning connections to the hardware. jumpers used to extend the telemetry port externally when used.

 - Switch for profiles
 - 3rd Telemetry input


 

