Crossbow projects:
Xnp : remote programming download app
  Date           Status
  Aug  13,2003   Xnp moved to main tinyos/apps directory. DO NOT USE THE /contrib/xbow/apps/xnp version  
  June  4,2003   Changed makefile so that app can be built from contrib/xbow/apps/.. directory
                 Change include xnp.h to Xnp.
  May   22,2003  Updated to work with promisicuous generic base. Successfully tested with GSK download.    
  April 10,2003  Alpha check-in, not a functional release.
  April 17,2003  Beta check-in for single  mote programming
  April 18,2003  Beta check-in for multi-mote programming
  May 14,2003    Working, checked with multiple mote download
                 Added fixes for larger TOS msgs, bad radio pkts that pass the crc test 

XSensorMica2: Measure mica2 voltage ref, compute battery voltage, ascii output to serial port
  June  4,2003   Changed makefile so that app can be built from contrib/xbow/apps/.. directory
  May   22,2003  Initial chk in

xsensordot2: Measures battery ref and thermistor voltage on mica2dot, ascii output to serial port
  July  7,2003   Initial chk in
 
XSensorMTS400: Measure mts400 sensor board (gps, barometric pressure, humidity, light, accel).
               Outputs ascii data thru serial port.
  Aug   19,2003  Initial chk in

XSensorMTS500: Measure mts500 sensor board (mica2dot wb). Computes engineering values, outputs
               ascii data thru serial port.
  Aug   13,2003  Initial chk in

XTestSnooze: Sets mica2 to 10uA sleep mode
  June  4,2003   Changed makefile so that app can be built from contrib/xbow/apps/.. directory
  June   2,2003  Check-in
