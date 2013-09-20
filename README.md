Stand-Sensor
============

Design files for accelerometer-based sitting/standing sensor and electrolaminate driver.  Built on Leaflabs' Maple.

Make sure that you have my hacked up version of the Wire library installed, as we need repeated start I2C. To install
it, make  backup of the old files and copy my Wire.cpp and Wire.h over them in the 

MapleIDE.app/Contents/Resources/Java/libraries/Wire/

directory (If you're on Mac).  This is a gross hack, sorry.
  
When uploading firmware, remember to build/install the Maple Mini target.

BOM is here:
https://docs.google.com/spreadsheet/ccc?key=0AkMyKIrUOd24dHlMcE16TWFrMjVCWlNEYzV1VXQ2dXc&usp=sharing

David Cranor
September 2013
cranor at media .mit dot edu



v1 notes/errata:
================

-DO NOT connect VCC-GND side of the switch when populating.
-USB port not close enough to edge on PCB
-Fix R12 to not trigger under-voltage protection when running off of battery power.  See datasheet for TPS61200.
-Fix mounting hole pattern to actually be symmetrical
-The leakage current in the currently specced D1 is too high, which caused some problems with the NFET power
 source switch.  Get one with a reasonable leakage current on next order.
-The PCB is slightly larger than the slot on the enclosure will allow.

