/**
 *
 * This is an auxiliary program for MNP. The purpose is to send "start" signal to the "base station" mote.
 * 
 * Authors: Limin Wang, Sandeep Kulkarni
 * 
 **/

#define AM_MnpMsg_ID  47

configuration BSStart {
}
implementation {
  components Main, BSStartM, TimerC, GenericComm, LedsC;
  Main.StdControl -> BSStartM.StdControl;
  BSStartM.SendMsg    -> GenericComm.SendMsg[AM_MnpMsg_ID];  
  BSStartM.GenericCommCtl -> GenericComm;
  BSStartM.Timer -> TimerC.Timer[unique("Timer")];
  BSStartM.Leds -> LedsC;
}

