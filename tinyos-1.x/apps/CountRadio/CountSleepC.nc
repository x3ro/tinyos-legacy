// $Id: CountSleepC.nc,v 1.1 2004/05/29 21:07:17 jpolastre Exp $
// @author Cory Sharp <cssharp@eecs.berkeley.edu>

// CountDual:
//   If the mote id is 1, count to the leds and send it over the radio.
//   Otherwise, receive the count from the radio and display it on the leds.

includes CountMsg;

configuration CountSleepC
{
}
implementation
{
  components Main
           , CountSleepM
	   , TimerC
	   , LedsC
           , HPLPowerManagementM
	   ;
  
  Main.StdControl -> TimerC;
  Main.StdControl -> CountSleepM;

  CountSleepM.Timer -> TimerC.Timer[unique("Timer")];
  CountSleepM.Leds -> LedsC.Leds;
  CountSleepM.PowerManagement -> HPLPowerManagementM;
  CountSleepM.Enable -> HPLPowerManagementM.Enable;
}

